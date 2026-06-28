# Disconnected OCP + Quay — Working Guide

**Audience:** Platform engineer implementing mirror-registry, `oc-mirror`, and first disconnected cluster  
**Status:** Reproducible runbook — substitute version and host values per environment  
**Scope anchor:** [BRIEF.md](BRIEF.md) · **Index:** [README.md](README.md)  
**ImageSet examples:** [imageset-examples.md](imageset-examples.md)

---

## Why this document exists

Disconnected work fails when steps are reordered — Quay without storage on the right disk, mirror without pull-secret merge, install without `ImageDigestMirrorSet`, OperatorHub before catalog mirror.

This guide is the **execution path**: stand up mirror-registry correctly, mirror content with oc-mirror v2, install, then operate.

**Non-goals:** RHACM/ArgoCD fleet onboarding · mirroring the full operator catalog · production Quay HA/DR.

---

## How to use this guide

| Principle | What it means |
|-----------|---------------|
| **Vertical slices** | Each phase ends with a check someone else can re-run. |
| **Pin versions** | Mirror exact z-streams under change control — not channel head. |
| **Platform before operators** | Prove release images on Quay before operator catalogs. |
| **Storage first** | Image data must not land on `/`. |

Substitute throughout: `${OCP_MINOR}` (e.g. `4.18`), `${OCP_ZSTREAM}` (e.g. `4.18.14`), `${CHANNEL}` (e.g. `stable-4.18`).

---

## Environment worksheet

| Variable | Your value | Notes |
|----------|------------|-------|
| `MIRROR_HOST` | | FQDN — must match cert SAN and `--quayHostname` |
| `MIRROR_REPO_PREFIX` | | Quay org/repo path (e.g. `ocp4`) |
| `MIRROR_CA_FILE` | | PEM for `additionalTrustBundle` |
| `PULL_SECRET` | | From cloud.redhat.com |
| `MIRROR_PULL_SECRET` | | Merged: Red Hat registries + mirror robot |
| `QUAY_DATA_MOUNT` | | Dedicated LV mount (e.g. `/data/quay`) — **must be in fstab** |
| `OCP_ZSTREAM` | | e.g. `4.18.14` |
| `OCP_MINOR` | | e.g. `4.18` |
| `CHANNEL` | | e.g. `stable-4.18` |
| `INSTALL_METHOD` | | `ipi` / `upi` / `assisted` |

---

## Storage planning (mirror-registry)

Red Hat sizing for OCP 4.18-class releases ([source](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/disconnected_environments/installing-mirroring-creating-registry)):

| Content | Approx. size |
|---------|----------------|
| Platform / release only (one z-stream) | ~12 GB |
| Platform + full Red Hat operator catalog | ~358 GB |
| Platform + Virt + Portworx + headroom | **plan 400–500 GB** |
| Growth (z-streams, more operators) | up to **1 TB+** suggested |

### mirror-registry: two paths people confuse

| Flag | Holds | Size |
|------|-------|------|
| `--quayRoot` | Config, nginx, certs, install metadata | Few GB |
| `--quayStorage` | **Image blobs** | Hundreds of GB |
| `--sqliteStorage` | DB metadata | Small |

**Default trap:** without `--quayStorage`, blobs go to Podman volumes under `/var/lib/containers/storage/volumes/` on **`/`**. A dedicated mount at `/quay` that is empty while `/` fills is a misconfiguration — not a sizing problem on the right disk.

### nginx

mirror-registry **includes** nginx (`quayRoot/conf/nginx`).
Do not add a separate system nginx on `:443` unless there is a deliberate VIP/TLS requirement — misconfigured reverse proxies cause **502 on blob write**.

### Disk topology checklist

- [ ] Dedicated LV/filesystem for `--quayStorage` (not `/`)
- [ ] Root `/` kept lean — **20 GB+ free** after mirror
- [ ] `df -h` on `${QUAY_DATA_MOUNT}` grows during `oc-mirror`; `/` stays flat
- [ ] No competing registry (Nexus, etc.) on the same role unless intentional

---

## Phase 0 — Discover

- [ ] OCP z-stream and channel pinned
- [ ] Day-1 operator list with **correct catalog** per package ([imageset-examples.md](imageset-examples.md))
- [ ] Pull secret + `registry.redhat.io` access verified
- [ ] Storage sized and mount planned
- [ ] Install method chosen

---

## Phase 1 — mirror-registry

### Install (greenfield)

```bash
sudo mkdir -p /data/quay/storage /data/quay/sqlite /data/quay/install

./mirror-registry install -v \
  --quayHostname "${MIRROR_HOST}" \
  --quayRoot /data/quay/install \
  --quayStorage /data/quay/storage \
  --sqliteStorage /data/quay/sqlite
```

Save install output: `init` password, hostname, root CA path.

### Verify

```bash
df -h / /data/quay
curl -k "https://${MIRROR_HOST}/v2/"
podman login "${MIRROR_HOST}" -u init -p '<password>'

# Data must NOT accumulate here after pushes:
podman volume inspect quay-storage 2>/dev/null || true
```

Create org + robot account for `${MIRROR_REPO_PREFIX}`; merge robot into `${MIRROR_PULL_SECRET}`.

### mirror-registry versions and systemd units

**mirror-registry 2.x** (current) uses **SQLite** (`--sqliteStorage`) — not PostgreSQL/Redis.
Do not assume `quay-postgres` or `quay-redis` units exist; older 1.x installs may still have them.

Discover what this host actually installed:

```bash
systemctl list-units --all '*quay*'
systemctl --user list-units --all '*quay*'   # if install ran without root
podman ps -a | grep -i quay
```

Typical **2.x** units: `quay-pod.service`, `quay-app.service` (root install) — names vary by version.

### Day-2 start/stop (after reboot)

Bring the registry back **without** running `./mirror-registry` CLI (install/upgrade/uninstall).
That CLI may require `/mnt/dvd/BaseOS` only when using offline RHEL repos — not for normal operation.

```bash
# 1. Data mount must be up first (see fstab below)
mount "${QUAY_DATA_MOUNT}"
df -h "${QUAY_DATA_MOUNT}"

# 2. Start installed units — use names from list-units above
sudo systemctl start quay-pod quay-app
# user install: systemctl --user start quay-pod quay-app

# 3. Verify
curl -k "https://${MIRROR_HOST}/v2/"
```

**fstab** (required — reboot breaks registry if data LV is not mounted):

```bash
UUID=$(blkid -s UUID -o value /dev/<vg>/<lv>)
echo "UUID=${UUID}  ${QUAY_DATA_MOUNT}  xfs  defaults  0  2" | sudo tee -a /etc/fstab
sudo mount -a
```

After `--quayStorage` is wired correctly, image data lives under that mount — not under `/var/lib/containers/.../quay-storage`.

### Reinstall after storage misconfiguration

If blobs landed on `/`:

1. Stop stack · free space on `/` (prune old podman volumes after stop)
2. Extend data LV if needed
3. `mirror-registry uninstall` (same `--quayRoot` as before)
4. Reinstall with `--quayStorage` and `--sqliteStorage` on the data mount
5. Re-mirror from scratch

### LV extend (when reclaiming unused LVs)

```bash
sudo umount /unused-mount
sudo lvchange -an /dev/vg0/unused-lv
sudo lvremove /dev/vg0/unused-lv
sudo lvextend -l +100%FREE /dev/vg0/registry-lv   # or -L 500G
sudo xfs_growfs /data/quay                          # ext4: resize2fs
```

`lvremove` needs free space on `/` for LVM metadata archives — prune `/` first if you see *can't create temporary archive name*.

---

## Phase 2 — oc-mirror v2

### Workstation

Use **`oc` and `oc-mirror` matching the target OCP z-stream**.

```bash
oc version
oc mirror --v2 --help
podman login registry.redhat.io
podman login "${MIRROR_HOST}"
```

### Run strategy: split platform and operators

| Run | Config | When |
|-----|--------|------|
| 1 — platform | [platform-only](imageset-examples.md#platform-only-first-mirror-run) | First — proves storage and release payload |
| 2 — operators | [operators-only](imageset-examples.md#operators-only-incremental) | After platform succeeds |
| Combined | [full example](imageset-examples.md#combined-full-re-mirror) | Full re-mirror only |

```bash
oc mirror -c imageset-platform.yaml \
  --workspace file://$(pwd)/mirror-workspace-platform \
  docker://${MIRROR_HOST}/${MIRROR_REPO_PREFIX} \
  --dest-skip-tls=false \
  --image-timeout=2h \
  --retry-times=5 \
  --v2
```

**During mirror:**

```bash
watch -n10 'df -h / /data/quay'
```

### Capture outputs

From `working-dir/cluster-resources/`:

- `idms-oc-mirror.yaml` — `ImageDigestMirrorSet`
- `itms-oc-mirror.yaml` — tag mirrors if generated
- `CatalogSource` / cluster catalog YAML
- `updateService.yaml` — only if `graph: true`
- `signature-configmap.yaml`

Commit to `mirror-manifests/${OCP_ZSTREAM}/`.

### Done when

- [ ] Release images mirrored (oc-mirror reports all release images success)
- [ ] Required operator catalogs present in Quay
- [ ] `oc adm release info` works against mirrored release digest
- [ ] Error log clean or failures understood and retried

---

## Phase 2b — Validate mirror (before install)

**Goal:** Confirm Quay holds the expected content and artifacts are archived for cluster install.

### Mirror inventory

```bash
df -h / "${QUAY_DATA_MOUNT}"

curl -ks "https://${MIRROR_HOST}/v2/${MIRROR_REPO_PREFIX}/redhat-operator-index/tags/list"
curl -ks "https://${MIRROR_HOST}/v2/${MIRROR_REPO_PREFIX}/certified-operator-index/tags/list"
```

Adjust catalog paths to match what you mirrored — not every environment needs `certified-operator-index`.

### Release payload

Use the release image digest or tag from oc-mirror output (`working-dir` logs or cluster-resources):

```bash
oc adm release info \
  "docker://${MIRROR_HOST}/${MIRROR_REPO_PREFIX}/<release-path>@sha256:<digest>" \
  --pullspecs
```

Add `--insecure` only in lab until CA trust is wired on the workstation.

### Archive install artifacts

Copy `working-dir/cluster-resources/` to version-controlled storage:

| Artifact | Purpose |
|----------|---------|
| `idms-oc-mirror.yaml` | Node pull redirects (`ImageDigestMirrorSet`) |
| `itms-oc-mirror.yaml` | Tag-based redirects (if generated) |
| `CatalogSource` / cluster catalog YAML | Disconnected OperatorHub |
| `signature-configmap.yaml` | Signature policy (if generated) |
| `updateService.yaml` | OSUS (only if `graph: true` in ImageSetConfiguration) |

```bash
mkdir -p mirror-manifests/${OCP_ZSTREAM}
cp -a working-dir/cluster-resources/* mirror-manifests/${OCP_ZSTREAM}/
```

Retain separately (secrets management — not in Git):

- `${MIRROR_PULL_SECRET}` — merged pull secret
- `${MIRROR_CA_FILE}` — from `quayRoot/quay-rootCA/` or install output
- Mirrored **release image** reference (install command input)

### Install-path branch

| Situation | Start at |
|-----------|----------|
| **New cluster** (IPI / UPI / agent) | Phase 3 |
| **Cluster already running** | Phase 4 — apply IDMS + catalogs; skip Phase 3 install |
| **ACM / CIM provisions cluster** | [cim-hub-setup.md](../../rhacm/notes/cim-hub-setup.md) + Phase 3 manifests on hub/spoke as applicable |

**Exit:** Release info succeeds · catalogs tagged in Quay · manifests archived · install method chosen.

---

## Phase 3 — Disconnected install (greenfield)

**Goal:** Cluster installs from the mirror only — no public release or payload pulls.

### Install host prep

```bash
podman login registry.redhat.io
podman login "${MIRROR_HOST}"

# oc + openshift-install must match ${OCP_ZSTREAM}
oc version
openshift-install version
```

### install-config.yaml

Minimum disconnected fields (plus platform-specific compute, networking, etc.):

```yaml
apiVersion: v1
baseDomain: example.com
# compute, networking, platform: ...

additionalTrustBundle: |
  -----BEGIN CERTIFICATE-----
  # contents of ${MIRROR_CA_FILE}
  -----END CERTIFICATE-----

pullSecret: '<contents of ${MIRROR_PULL_SECRET}>'
```

```bash
mkdir -p install && cd install
openshift-install create install-config   # or copy a reviewed template
```

### manifests/ from oc-mirror

Copy **before** `create cluster`:

```bash
mkdir -p manifests
cp ../mirror-manifests/${OCP_ZSTREAM}/idms-oc-mirror.yaml manifests/
# Copy other cluster-resources as required by your install method
```

`ImageDigestMirrorSet` in `manifests/` is applied at install time on supported paths.
If your method applies IDMS post-bootstrap instead, note that in the decision log and apply in Phase 4.

### Run install with mirrored release image

Use the release image from oc-mirror output — **not** `quay.io/openshift-release-dev/...`.

```bash
# IPI / UPI — release image from mirror results
openshift-install create cluster --dir=.

# Assisted / agent-based
openshift-install agent create cluster --dir=.

# Explicit image when required by your procedure
openshift-install create cluster --dir=. \
  --image=docker://${MIRROR_HOST}/${MIRROR_REPO_PREFIX}/<release-image-path>
```

Exact `--image` value comes from oc-mirror working-dir output for `${OCP_ZSTREAM}`.

### Assisted / ACM hub provisioning

When a hub provisions clusters (Assisted Installer / CIM), configure hub-side mirror and RHCOS hosting per [cim-hub-setup.md](../../rhacm/notes/cim-hub-setup.md):

- `assisted-installer-mirror-config` (`registries.conf` + CA)
- `AgentServiceConfig.spec.mirrorRegistryRef`
- `osImages` when the hub cannot reach `mirror.openshift.com`

### Done when

- [ ] Install completes; `oc get clusterversion` shows `${OCP_ZSTREAM}`
- [ ] `oc get co` — no persistent `ImagePullBackOff` on core operators
- [ ] `oc get imagedigestmirrorset` — IDMS present
- [ ] Node pulls resolve to `${MIRROR_HOST}` (registry logs or node debug)

---

## Phase 4 — OperatorHub (disconnected)

**Goal:** Operator installs use mirrored catalogs only.

Skip IDMS apply if already included at install via `manifests/`.

### Apply mirror policy (if not done at install)

```bash
oc apply -f mirror-manifests/${OCP_ZSTREAM}/idms-oc-mirror.yaml
oc get mcp   # wait for MCO to finish if nodes were already running
```

### Disable default catalog sources

```bash
oc patch operatorhub cluster --type merge \
  -p '{"spec":{"disableAllDefaultSources":true}}'
```

### Apply mirrored catalogs

Apply all `CatalogSource` (or cluster catalog) YAML from oc-mirror output:

```bash
oc apply -f mirror-manifests/${OCP_ZSTREAM}/
oc get catalogsource -n openshift-marketplace
oc get packagemanifests | head
```

Only mirrored operators should appear.

### Install operators

Create `Subscription` resources per operator.
Use `source` and `sourceNamespace` from the generated `CatalogSource` names.

```bash
# Example — substitute operator name, channel, catalog source
oc create -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: example-operator
  namespace: openshift-operators
spec:
  channel: <channel-from-oc-mirror-list>
  name: <package-name>
  source: <catalog-source-name>
  sourceNamespace: openshift-marketplace
EOF

oc get csv -n openshift-operators
```

Channel and package names: `oc mirror list operators --catalog=... --package=...`

### Verify disconnected pulls

```bash
oc get imagedigestmirrorset -o yaml
oc debug node/<node> -- chroot /host cat /etc/containers/registries.conf
```

Confirm with egress blocked or mirror access logs that operand images pull from `${MIRROR_HOST}`.

### Done when

- [ ] `disableAllDefaultSources=true`
- [ ] Required operators `Succeeded`
- [ ] No pulls to public registries for installed operators

---

## Phase 5 — Operate

- Add operators: extend `packages:` in ImageSetConfiguration → re-run oc-mirror (incremental)
- Z-stream bump: widen `maxVersion` → re-mirror → cluster upgrade per Red Hat docs
- Quay garbage collection when removing mirrored content ([Red Hat Quay GC docs](https://docs.redhat.com/en/documentation/red_hat_quay/latest/html/manage_red_hat_quay/oci-artifact-garbage-collection))

---

## Suggested directory layout

```
disconnected-ocp-mirror/
├── imageset-platform.yaml
├── imageset-operators.yaml
├── pull-secrets/                 # gitignored
├── mirror-workspace-platform/
├── mirror-workspace-operators/
├── mirror-manifests/
│   └── 4.18.14/
│       ├── idms-oc-mirror.yaml
│       └── catalogsource-*.yaml
└── install/
    ├── install-config.yaml
    └── manifests/
```

---

## Troubleshooting

| Symptom | Likely cause | Action |
|---------|--------------|--------|
| `502` on blob write | `/` full; Quay DB can't write; or extra nginx proxy | `df -h`; verify `--quayStorage`; check mirror-registry nginx only |
| Registry down after reboot | Data LV not in `fstab` | `mount` `${QUAY_DATA_MOUNT}`; add `fstab`; `systemctl start quay-*` (discover units) |
| `/mnt/dvd/BaseOS` missing | Only when running `mirror-registry` CLI with DVD repos | Not needed for `systemctl start quay-*`; fix repos or remount ISO if reinstalling |
| `/quay` empty, `/` full | Missing `--quayStorage` | Reinstall mirror-registry on data mount |
| `lvremove`: temporary archive name | `/` full | Prune podman volumes, journal; free `/` |
| `certified-operator-index`: `manifest unknown` | Stale workspace; bad `targetCatalog`/`targetTag`; pull auth | Fresh workspace; simplify YAML ([imageset-examples.md](imageset-examples.md)); `skopeo inspect` catalog |
| Platform OK, operators partial | Wrong catalog for package | `oc mirror list operators`; certified vs redhat index |
| `x509` errors | CA not distributed | `additionalTrustBundle`, IDMS, lab: `--dest-skip-tls` |
| `401` on push | Robot not in pull secret | Merge mirror creds |
| Install ImagePullBackOff on core operators | Wrong release image; IDMS missing; pull secret | Mirrored `--image`; `manifests/idms`; merged pull secret |
| Operator CSV stuck | Catalog not applied; wrong `source` name | `CatalogSource` from oc-mirror output; `packagemanifests` |
| Pulls still hit `registry.redhat.io` | IDMS not applied or incomplete | `oc get imagedigestmirrorset`; re-apply from cluster-resources |

After failures, read `working-dir/logs/mirroring_errors_*.txt` — first upstream error matters more than `localhost:55000` symptoms.

---

## Phase summary

```
Phase 0  Discover       → version, operators, storage plan
Phase 1  mirror-registry  → --quayStorage on dedicated disk
Phase 2  oc-mirror      → platform run, then operators; save manifests
Phase 2b Validate       → inventory Quay, archive cluster-resources
Phase 3  Install        → install-config + manifests + mirrored release
Phase 4  OperatorHub    → IDMS, disable defaults, catalogs, subscriptions
Phase 5  Operate        → incremental mirror, upgrades, GC
```

---

## References

- [imageset-examples.md](imageset-examples.md) — copy-paste ImageSetConfiguration
- [BRIEF.md](BRIEF.md) — scope and success criteria
- [Disconnected appendix](../../learning-path/vmware-admins/README.md#appendix-disconnected-and-air-gapped-environments)
- [CIM hub mirror setup](../../rhacm/notes/cim-hub-setup.md)
- [OCP 4.18 disconnected environments](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/disconnected_environments/)
- [oc-mirror v2 (4.18)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/disconnected_environments/about-installing-oc-mirror-v2)
- [mirror-registry install](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/disconnected_environments/installing-mirroring-creating-registry)

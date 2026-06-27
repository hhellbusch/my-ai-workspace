# Disconnected OCP 4.18.14 + Quay — Working Guide

**Audience:** Platform engineer implementing the mirror stack and first disconnected cluster  
**Status:** Working guide — fill blanks as you discover them  
**Scope anchor:** [BRIEF.md](BRIEF.md) · **Index:** [README.md](README.md)  
**Target:** OpenShift **4.18.14** on channel `stable-4.18`

---

## Why this document exists

The brief defines boundaries.
This guide is the **execution path**: what to stand up, in what order, with checks you can run after each slice.

Disconnected work fails when steps are reordered — Quay without TLS trust, mirror without pull secret merge, install without `ImageDigestMirrorSet`, OperatorHub before catalog mirror.
Follow the phases.

**Non-goals (this guide):** RHACM/ArgoCD fleet onboarding · mirroring the full operator catalog · production Quay HA/DR design.

---

## How we are working

| Principle | What it means |
|-----------|---------------|
| **Vertical slices** | Each phase ends with a command or UI check that proves the slice. |
| **Pin versions** | Mirror **4.18.14** exactly until you deliberately widen the range. |
| **Docs follow doing** | Update the worksheet and decision log when reality diverges. |
| **Observable done** | Checkbox = someone else can re-run the verify step. |

---

## Environment worksheet

Fill this in during Phase 0.
Commands below use these variables.

| Variable | Your value | Notes |
|----------|------------|-------|
| `MIRROR_HOST` | | FQDN of Quay / mirror-registry (e.g. `mirror.lab.example.com`) |
| `MIRROR_PORT` | `443` | TLS port |
| `MIRROR_FQDN` | | `${MIRROR_HOST}:${MIRROR_PORT}` if non-443 |
| `MIRROR_REPO_PREFIX` | | Path prefix in Quay (e.g. `ocp4` — match `oc-mirror` destination) |
| `MIRROR_URL` | | `https://${MIRROR_HOST}` or with port |
| `MIRROR_CA_FILE` | | Path to registry CA PEM on workstation |
| `PULL_SECRET` | | `~/.pull-secret.json` from cloud.redhat.com |
| `MIRROR_PULL_SECRET` | | Merged secret including mirror registry creds |
| `OC_MIRROR_WORKSTATION` | | Connected host that runs `oc-mirror` (may be outside air gap) |
| `INSTALL_HOST` | | Bootstrap / `openshift-install` host |
| `AIR_GAP` | `yes` / `no` | `yes` → archive transfer between zones |
| `QUAY_TYPE` | | `mirror-registry` / `enterprise-quay` |
| `INSTALL_METHOD` | | `ipi` / `upi` / `assisted` / other |

**Network checks (run from install subnet and from a future worker node subnet):**

```bash
# TLS + trust
curl -v --cacert "${MIRROR_CA_FILE}" "https://${MIRROR_HOST}/v2/"

# Auth (after Quay is up)
podman login "${MIRROR_HOST}" --cert-dir ... # or docker login
```

---

## Phase 0 — Discover (~2–3 days)

**Goal:** No unknowns that block Quay install or first mirror run.

### Checklist

- [ ] Confirm **4.18.14** is the install target (not “latest 4.18”)
- [ ] Choose **Quay type** (`mirror-registry` vs existing enterprise Quay)
- [ ] Choose **air-gap model** (connected `oc-mirror` → Quay vs archive hop)
- [ ] Choose **install method** (drives RHCOS ISO / assisted mirror needs)
- [ ] List **day-1 operators** to mirror (start small — see starter list below)
- [ ] Confirm DNS, firewall: install hosts + all node subnets → `MIRROR_HOST`
- [ ] Obtain **pull secret** and registry service account if mirroring from `registry.redhat.io`
- [ ] Size storage for first mirror (platform + N operators — plan hundreds of GB)

### Day-1 operator starter list

Edit `imageset-config.yaml` — uncomment what you need:

```yaml
packages:
  # - name: advanced-cluster-management      # ACM hub
  # - name: openshift-gitops-operator          # Argo CD
  # - name: kubevirt-hyperconverged          # OpenShift Virtualization
  # - name: local-storage-operator           # LSO / bare metal
  # - name: metallb-operator                 # bare metal LB
```

### Decision log

| Date | Decision | Choice | Why |
|------|----------|--------|-----|
| | Z-stream pin | `4.18.14` only | Brief default — change if mirroring a range |
| | | | |

**Exit:** Worksheet complete · `imageset-config.yaml` drafted · storage and network signed off.

---

## Phase 1 — Quay mirror registry

**Goal:** Trusted, authenticated registry ready to receive images.

### mirror-registry (greenfield)

Red Hat path for a single-node Quay sized for mirroring.
Follow [mirror-registry installation](https://docs.redhat.com/en/documentation/red_hat_quay/latest/html/red_hat_quay_installation_and_configuration_on_openshift_with_mirror_registry/) for your RHEL version.

**Done when:**

- [ ] `curl https://${MIRROR_HOST}/v2/` succeeds with correct CA
- [ ] `podman login ${MIRROR_HOST}` succeeds
- [ ] Robot account or org/repo created for `${MIRROR_REPO_PREFIX}`
- [ ] CA cert exported for `additionalTrustBundle` and node trust
- [ ] Backup/snapshot approach noted (even if “VM snapshot only” for lab)

### Enterprise Quay (existing)

- [ ] Org/project for OCP mirror content agreed with registry owners
- [ ] Robot account + permissions for `oc-mirror` push
- [ ] TLS cert chain documented; same trust distribution as above

---

## Phase 2 — Mirror content (`oc-mirror`)

**Goal:** `4.18.14` release payload + chosen operators exist in Quay; generated manifests saved.

### 2.1 — Prepare workstation

Use **`oc` and `oc-mirror` from 4.18.14** — not a mismatched client.

```bash
# On a connected machine — example: extract client from release
OCP_VERSION=4.18.14
RELEASE_IMAGE=$(oc adm release info "quay.io/openshift-release-dev/ocp-release:${OCP_VERSION}-multi" \
  -o 'jsonpath={.imageDigest}' 2>/dev/null || true)
# Prefer: download oc-mirror from mirror host after you have first payload,
# or use openshift-install/oc from matching release payload.

oc version
oc mirror --help
```

Install `oc-mirror` plugin per [4.18 docs](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/disconnected_environments/mirroring-images-for-a-disconnected-installation) if not bundled.

### 2.2 — Image set config

Create `imageset-config.yaml` (repo layout example):

```yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v2alpha1
archiveSize: 4
storageConfig:
  registry:
    imageURL: ${MIRROR_HOST}/${MIRROR_REPO_PREFIX}/metadata:latest
    skipTLS: false   # set true only for lab self-signed before CA is trusted
mirror:
  platform:
    channels:
      - name: stable-4.18
        minVersion: 4.18.14
        maxVersion: 4.18.14
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.18
      packages:
        - name: openshift-gitops-operator   # replace with your day-1 list
  additionalImages: []
```

### 2.3 — Merge pull secret

Mirror registry credentials must be in the pull secret `oc-mirror` uses.

```bash
# Template — adjust auth field to match your Quay robot creds
# See: oc mirror help for merge semantics
cp "${PULL_SECRET}" "${MIRROR_PULL_SECRET}"
# Add ${MIRROR_HOST} entry per Red Hat docs (dockerconfigjson merge)
```

### 2.4 — Run mirror

**Connected path** (workstation reaches Red Hat + Quay):

```bash
oc mirror --config=imageset-config.yaml \
  "docker://${MIRROR_HOST}/${MIRROR_REPO_PREFIX}" \
  --dest-skip-tls=false
```

**Air-gapped path** (two hops):

```bash
# Hop 1 — connected zone: mirror to disk archive
oc mirror --config=imageset-config.yaml \
  file://$(pwd)/oc-mirror-archive

# Transfer oc-mirror-archive/ to disconnected zone (sneakernet / one-way)

# Hop 2 — disconnected zone: archive → Quay
oc mirror --from=file://$(pwd)/oc-mirror-archive \
  "docker://${MIRROR_HOST}/${MIRROR_REPO_PREFIX}"
```

**Capture output directory** — `oc-mirror` emits manifests you will apply at install and post-install:

- `ImageDigestMirrorSet`
- `CatalogSource` (mirrored operator index)
- Release image reference / `ImageTagMirrorSet` if generated
- Cluster catalog resources (version-dependent — use what your run produces)

**Done when:**

- [ ] Mirrored release image visible in Quay UI or `curl` API
- [ ] Operator index image present
- [ ] Output manifests saved to Git: `mirror-manifests/4.18.14/`
- [ ] `oc adm release info` against mirrored release digest succeeds from workstation

```bash
# Example — replace digest with value from oc-mirror output
oc adm release info "${MIRROR_HOST}/${MIRROR_REPO_PREFIX}/openshift-release@sha256:..." \
  --pullspecs --insecure=false
```

---

## Phase 3 — Disconnected install (4.18.14)

**Goal:** Cluster installs using only the mirror — no public registry pulls.

Exact steps vary by **install method**.
Common elements:

### 3.1 — Install config fragments

`install-config.yaml` needs at minimum:

- `additionalTrustBundle` — mirror registry CA (PEM inline)
- `imageContentSources` / digest mirrors — prefer applying generated **`ImageDigestMirrorSet`** from `oc-mirror` output (4.18 uses IDMS; can include in `manifests/` at install time per your method)
- `pullSecret` — **merged** secret (`${MIRROR_PULL_SECRET}`)

```yaml
# install-config.yaml (excerpt)
additionalTrustBundle: |
  -----BEGIN CERTIFICATE-----
  # ${MIRROR_CA_FILE} contents
  -----END CERTIFICATE-----
pullSecret: '<contents of MIRROR_PULL_SECRET>'
```

Place `oc-mirror` generated CRs in `manifests/` before `openshift-install create cluster` when your install path supports it.

### 3.2 — Release image

Point install at the **mirrored** release image, not `quay.io/openshift-release-dev/...`.

```bash
# IPI/UPI pattern — image from oc-mirror results / release info
openshift-install agent create cluster --dir=install-dir   # if assisted
# or
openshift-install create cluster --dir=install-dir
```

Use the release image URL/digest documented in your `oc-mirror` output for `4.18.14`.

### 3.3 — Assisted / ACM (if applicable)

If install is via CIM/Assisted Installer on a hub, also configure hub-side mirror per [cim-hub-setup.md](../../rhacm/notes/cim-hub-setup.md):

- `assisted-installer-mirror-config` ConfigMap (`registries.conf` + CA)
- `AgentServiceConfig.spec.mirrorRegistryRef`
- `osImages` with internal RHCOS ISO/rootfs URLs if hub cannot reach `mirror.openshift.com`

**Done when:**

- [ ] Install completes; cluster reports version `4.18.14`
- [ ] `oc get clusterversion` — `Progressing=False`, `Available=True`
- [ ] No ImagePullBackOff on core operators (`oc get co`)
- [ ] Sample `crictl pull` / operator pod uses `${MIRROR_HOST}` (registry logs or node debug)

---

## Phase 4 — OperatorHub (disconnected)

**Goal:** Install one mirrored operator without default catalog internet dependency.

### 4.1 — Apply mirror policy (if not done at install)

```bash
oc apply -f mirror-manifests/4.18.14/imagedigestmirrorset.yaml
# Wait for MCO — nodes updated
oc get mcp
```

### 4.2 — Disable default catalog sources

```bash
oc patch operatorhub cluster --type merge \
  -p '{"spec":{"disableAllDefaultSources":true}}'
```

### 4.3 — Apply mirrored CatalogSource

Use the `CatalogSource` YAML from `oc-mirror` output (points at mirrored `redhat-operator-index`).

```bash
oc apply -f mirror-manifests/4.18.14/catalogsource.yaml
oc get packagemanifests | head   # should list mirrored operators only
```

### 4.4 — Install one operator

```bash
# Example Subscription — adjust channel/name
oc create -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-gitops-operator
  namespace: openshift-operators
spec:
  channel: latest
  name: openshift-gitops-operator
  source: <catalog-source-name-from-oc-mirror>
  sourceNamespace: openshift-marketplace
EOF

oc get csv -n openshift-operators
```

**Done when:**

- [ ] `disableAllDefaultSources=true`
- [ ] Mirrored catalog healthy
- [ ] One operator `Succeeded` with egress blocked or mirror-only pulls verified

---

## Phase 5 — Operate

**Goal:** Repeatable mirror refresh and z-stream upgrade path documented.

### Add an operator later

1. Add `name:` under `packages:` in `imageset-config.yaml`
2. Re-run `oc-mirror` (incremental — unchanged images skipped)
3. Apply updated `CatalogSource` / IDMS if output changed
4. Subscribe as usual

### Z-stream upgrade (4.18.14 → 4.18.x)

1. Widen `maxVersion` in `imageset-config.yaml` (or pin new exact version)
2. Re-run `oc-mirror`
3. Apply updated manifests
4. Run supported cluster upgrade path per [4.18 updating docs](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/updating_clusters/)

### Verify disconnected pulls

```bash
# On a node (debug pod or SSH)
# Confirm registries.conf redirect — path varies by OCP version
oc debug node/<node> -- chroot /host cat /etc/containers/registries.conf

# Cluster-level
oc get imagedigestmirrorset -o yaml
```

---

## Suggested repo layout

```
disconnected-ocp-mirror/          # your Git repo or directory
├── imageset-config.yaml
├── pull-secrets/                 # gitignored
│   └── .gitignore
├── mirror-manifests/
│   └── 4.18.14/
│       ├── imagedigestmirrorset.yaml
│       ├── catalogsource.yaml
│       └── imagecontentsourcepolicy.yaml  # only if legacy; 4.18 greenfield: IDMS
├── install/
│   ├── install-config.yaml       # redact secrets — use secrets manager
│   └── manifests/
└── runbook/
    └── upgrade-4.18.z.md
```

---

## Troubleshooting quick hits

| Symptom | Likely cause | Check |
|---------|--------------|-------|
| `x509: certificate signed by unknown authority` | CA not in trust bundle / `additionalTrustBundle` | Node `registries.conf`, install-config, IDMS |
| `401 Unauthorized` on mirror pull | Pull secret missing mirror creds | Merged `${MIRROR_PULL_SECRET}` on cluster |
| Operator install pulls `registry.redhat.io` | IDMS not applied or incomplete | `oc get imagedigestmirrorset` |
| Operator not in Hub | Catalog not mirrored or default sources still on | `packagemanifests`, `CatalogSource` |
| `oc-mirror` partial failure | Disk space or registry quota | Quay storage, `archiveSize` |
| Install pulls public release image | Wrong release image ref in install | `oc-mirror` output digest |

---

## Phase summary

```
Phase 0  Discover     → worksheet + imageset-config
Phase 1  Quay         → login + CA trusted
Phase 2  oc-mirror    → 4.18.14 + operators in Quay; manifests in Git
Phase 3  Install      → cluster up on mirror only
Phase 4  OperatorHub  → one operator installed disconnected
Phase 5  Operate      → add operator / z-stream runbook
```

---

## Next actions

1. Fill **Environment worksheet** (hostnames, air-gap, install method)
2. Finalize **day-1 operator** list in `imageset-config.yaml`
3. Stand up **Quay** (Phase 1) in lab if not already present
4. Run first **`oc-mirror`** for platform-only if operator list is still TBD — proves pipeline before widening scope
5. Record outcomes in **Decision log** in this guide and in [BRIEF.md](BRIEF.md)

---

## References

- [BRIEF.md](BRIEF.md) — scope and success criteria
- [Disconnected appendix](../../learning-path/vmware-admins/README.md#appendix-disconnected-and-air-gapped-environments)
- [CIM hub mirror setup](../../rhacm/notes/cim-hub-setup.md)
- [OCP 4.18 disconnected environments](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/disconnected_environments/)
- [oc-mirror (4.18)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/disconnected_environments/mirroring-images-for-a-disconnected-installation)
- [Mirroring operator catalogs (4.18)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/disconnected_environments/mirroring-operator-catalogs-for-use-with-disconnected-clusters)

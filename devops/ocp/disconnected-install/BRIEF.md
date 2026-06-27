# Disconnected OCP with Quay

> **Status:** In Progress  
> **Started:** 2026-06-27  
> **Index:** [README.md](README.md)

## Audience and Purpose

**Reader:** Platform engineers and architects standing up or extending OpenShift in an environment without reliable outbound internet — and anyone implementing the mirror registry, mirroring pipeline, and cluster pull redirection.

**Enables:** Scope boundary for the disconnected stack (Quay + `oc-mirror` + cluster mirror policy), sequencing of work, and decisions that must be made before install — without re-litigating the full disconnected-install guide on every session.

## Problem Statement

Clusters cannot pull release images, operator catalogs, or workload images from public registries at install time or steady state. Red Hat's supported pattern is a **local mirror registry** (Quay — typically `mirror-registry` for a single-node footprint, or an existing enterprise Quay) populated with **`oc-mirror`**, plus cluster-level **image digest mirroring** (`ImageDigestMirrorSet`) so nodes redirect pulls to the mirror. Without this foundation, OCP install, upgrades, OperatorHub, and day-2 workloads fail or stall on egress.

This work is needed now because disconnected operation is a hard prerequisite for the target environment — not an optimization.

## Scope

**In scope**

- Mirror registry platform on **Quay** (sizing, TLS, auth, storage, backup posture)
- **`oc-mirror` v2** pipeline: `ImageSetConfiguration`, initial full sync, incremental updates for upgrades
- **Trust chain**: registry CA distribution to install hosts, bootstrap, and cluster (`trustedCA`, `registries.conf` / machine config as required)
- **Disconnected install inputs**: pull secret, mirrored release image, `install-config` mirror settings
- **Post-install mirror policy**: apply `oc-mirror` output (`ImageDigestMirrorSet`; know `ImageContentSourcePolicy` for older clusters)
- **Disconnected OperatorHub**: disable default catalog sources; `CatalogSource` for mirrored operator index; mirror only required operators initially
- **RHCOS / payload hosting** where install or provisioning cannot reach `mirror.openshift.com` (HTTP mirror or registry paths per install method)
- **Operational runbook stubs**: how to add an operator, bump OCP z-stream/minor, verify pull path without internet

**Out of scope**

- Full production DR / multi-site Quay HA design (unless explicitly pulled in)
- Mirroring every Red Hat operator catalog package by default
- Application-team container build pipelines (CI/CD to Quay) — only platform images needed for OCP/ACM/GitOps unless stated otherwise
- Non-OCP registry consumers (generic artifact mirrors, RPM mirrors) except where required for OCP/RHCOS
- Fleet GitOps onboarding (RHACM/ArgoCD) — separate epic; this guide covers the **mirror prerequisite** those flows depend on

## Success Criteria

- [ ] Quay mirror registry reachable from install subnet and all cluster nodes; TLS trusted end-to-end
- [ ] Target OCP release channel/version mirrored via `oc-mirror`; install completes with no public registry pulls
- [ ] `ImageDigestMirrorSet` (or equivalent) applied; `oc adm release info` / sample workload pull resolves to Quay
- [ ] OperatorHub serves mirrored catalog; at least one operator installs successfully while egress is blocked (or verified via registry logs)
- [ ] Documented procedure for incremental mirror update aligned to an OCP upgrade path
- [ ] Gaps and org-specific choices captured in `Key Decisions` (below) — no silent assumptions

## Target release

| Field | Value |
|-------|-------|
| **OCP version** | `4.18.14` |
| **Update channel** | `stable-4.18` |
| **Operator catalog** | `registry.redhat.io/redhat/redhat-operator-index:v4.18` |
| **Mirror policy API** | `ImageDigestMirrorSet` (4.13+; ICSP not needed for greenfield 4.18) |
| **`oc-mirror` client** | Match 4.18 — use `oc` / `oc-mirror` from the 4.18.14 release payload |

Pin mirroring to **exact** z-stream (`4.18.14`), not channel head, unless upgrade-in-place to a newer 4.18.z is an explicit next step.

## Constraints

- Follow [OCP 4.18 disconnected environments](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/disconnected_environments/) documentation
- Mirror content must match **exact** versions under change control — ad-hoc `latest` tags are unsafe for platform images
- Regulated / air-gapped environments often require **fixed egress windows** for mirror refresh; design for offline transfer (`oc-mirror` archive workflow) if the mirror host never has internet
- `oc-mirror` + IDMS over ICSP (OCP 4.13+); ACM assisted install mirror config in [cim-hub-setup.md](../../rhacm/notes/cim-hub-setup.md) if hub provisions clusters

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Mirror registry product | **TBD** — `mirror-registry` (single-node Quay) vs existing enterprise Quay | `mirror-registry` is Red Hat's install-sized default; enterprise Quay if org already operates it |
| OCP target version / channel | **4.18.14** / `stable-4.18` | Pins release payload, RHCOS build, and `redhat-operator-index:v4.18` |
| Connected vs fully air-gapped mirror host | **TBD** | Air-gapped → `oc-mirror` archive + physical/one-way transfer; connected → direct sync to Quay |
| Install method | **TBD** — IPI/UPI, assisted/CIM, or static | Determines RHCOS ISO/rootfs hosting and when IDMS must exist |
| Operators to mirror (initial set) | **TBD** | Mirror minimum for platform (e.g. ACM, GitOps, Virt) — not full catalog |
| Hub in disconnected story | **TBD** | If ACM hub is in scope, MCH/assisted images and `AgentServiceConfig` mirror/`osImages` apply |
| Registry auth model | **TBD** | Pull secret merge, robot accounts, global pull secret on cluster |

## Architecture (reference)

```mermaid
flowchart LR
  subgraph connected["Connected zone (optional)"]
    RH["Red Hat registries"]
    OM["oc-mirror workstation"]
    RH --> OM
  end
  subgraph disconnected["Disconnected zone"]
    Q["Quay mirror registry"]
    CP["Cluster nodes"]
    IH["Install / bootstrap hosts"]
    OM -->|"sync or archive import"| Q
    Q --> CP
    Q --> IH
    IDMS["ImageDigestMirrorSet"] --> CP
  end
```

## Phased delivery (suggested)

| Phase | Outcome |
|-------|---------|
| **0 — Discover** | Install method, network zones, existing Quay, operator shortlist (version locked: 4.18.14) |
| **1 — Quay** | Registry deployed, TLS + auth, storage, backup hook |
| **2 — Mirror** | `ImageSetConfiguration` in Git; initial `oc-mirror` run; verify image presence in Quay |
| **3 — Install** | Disconnected install of first cluster (or lab) using mirrored release + pull secret |
| **4 — OperatorHub** | IDMS applied; default sources disabled; mirrored catalog; one operator proven |
| **5 — Operate** | Upgrade/mirror refresh runbook; optional ACM/CIM mirror alignment |

## Related

- **[Working guide](working-guide.md)** — phased execution path, worksheet, commands, checklists
- [Disconnected environments appendix](../../learning-path/vmware-admins/README.md#appendix-disconnected-and-air-gapped-environments) — `oc-mirror`, IDMS, OperatorHub pattern
- [CIM hub mirror configuration](../../rhacm/notes/cim-hub-setup.md) — assisted install `mirrorRegistryRef`, `osImages`
- [Registry credentials via RHACM](../../rhacm/examples/secret-management/4_registry_credentials/README.md) — pull secret distribution to managed clusters
- [Image registry auth troubleshooting](../troubleshooting/image-registry-auth/README.md) — TLS/RBAC patterns (internal registry; analogous trust issues)
- Red Hat: [Disconnected environments (4.18)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/disconnected_environments/)
- Red Hat: [oc-mirror plugin (4.18)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/disconnected_environments/mirroring-images-for-a-disconnected-installation)
- Red Hat: [mirror-registry](https://docs.redhat.com/en/documentation/red_hat_quay/latest/html/red_hat_quay_installation_and_configuration_on_openshift_with_mirror_registry/)

## ImageSetConfiguration (starter — extend operator list)

```yaml
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v2alpha1
archiveSize: 4
mirror:
  platform:
    channels:
      - name: stable-4.18
        minVersion: 4.18.14
        maxVersion: 4.18.14
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.18
      packages: []   # populate in Phase 0 — e.g. advanced-cluster-management, openshift-gitops-operator
  additionalImages: []   # workload / custom images as identified
```

After mirror run: apply generated `ImageDigestMirrorSet` from `oc-mirror` output; verify with `oc adm release info quay.example.com/ocp4/openshift-release@sha256:...`.

## Open questions (resolve in Phase 0)

1. Upgrade cadence within 4.18.z — pin only `4.18.14`, or mirror a range for in-place z-stream updates?
2. Is the mirror host ever internet-connected, or strictly air-gapped with archive transfer?
3. Greenfield Quay (`mirror-registry`) or integrate with existing Quay org/project layout?
4. Single lab cluster first, or production disconnected install?
5. Is ACM/CIM hub part of the same disconnected boundary?
6. Which operators must be available at day-1 vs day-30?

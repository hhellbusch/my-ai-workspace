---
review:
  status: unreviewed
  notes: "AI-generated 2026-07-08. Port matrix verified against OCP 4.20 IPI bare-metal docs, MCE infrastructure-operator networking, and ACM 2.16 hub/managed-cluster networking. Symptom mappings synthesized from workspace troubleshooting guides and assisted-service/Ironic behavior — not validated end-to-end in this environment."
---

# ACM Bare Metal — Network Ports and Blocked-Port Symptoms

**Audience:** Platform engineers and network teams scoping firewall rules for ACM CIM / Assisted Installer bare-metal cluster provisioning (virtual media path, no provisioning network).

**Purpose:** Map required ports to install phase, traffic direction, and typical symptoms when a path is blocked — so firewall requests cite Red Hat docs and symptoms narrow which rule is missing.

**Scope:** Agent-based install via ACM (`InfraEnv` → `Agent` → `AgentClusterInstall` → Ironic/Metal³). Generic placeholders only; no environment-specific hostnames or IPs.

**Prerequisites:** CIM enabled on hub. See [cim-hub-setup.md](./cim-hub-setup.md).

**Related:**

- [networking-requirements-2.16.md](./networking-requirements-2.16.md) — ongoing hub ↔ managed cluster management (post-install)
- [agent-install-rootfs-ssl-failure.md](../troubleshooting/agent-install-rootfs-ssl-failure.md) — discovery-phase 443 deep dive
- [managed-cluster-lease-not-updated.md](../troubleshooting/managed-cluster-lease-not-updated.md) — klusterlet lease / Unknown status
- [`devops/bare-metal-dev-sandbox/catalog/checks.yaml`](../../bare-metal-dev-sandbox/catalog/checks.yaml) — `network_firewall_install_ports` preflight check IDs
- [`devops/bare-metal-dev-sandbox/HARNESS.md`](../../bare-metal-dev-sandbox/HARNESS.md) — sandbox harness overview

**Official sources:**

- [OCP 4.20 — Ensuring required ports are open (IPI bare metal)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/installing_on_bare_metal/installer-provisioned-infrastructure#ensuring-required-ports-are-open)
- [OCP 4.20 — Port access for out-of-band management (virtual media)](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/installing_on_bare_metal/installer-provisioned-infrastructure#nw-osp-setup-virt-media_oob-management-port-access)
- [MCE — Additional networking (Infrastructure Operator)](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.6/html/multicluster_engine/multicluster_engine_overview#additional-networking-requirements-when-installing-using-the-infrastructure-operator)
- [ACM 2.16 — Networking (hub ↔ managed cluster)](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html-single/networking/index)

---

## Install phases (read this first)

Three network concerns overlap in time but have **different src/dst paths**. Opening the wrong rule set wastes cycles.

```mermaid
flowchart LR
    A[Phase 1: Discovery] -->|hosts → hub 443| B[Agents register]
    B --> C[Phase 2: Ironic install]
    C -->|machine network + OOB| D[BMH provisioned]
    D --> E[Phase 3: ACM import]
    E -->|bidirectional 443 + 6443| F[ManagedCluster healthy]
```

| Phase | When | Traffic path | Primary doc |
|-------|------|--------------|-------------|
| **1 — Discovery** | Hosts boot discovery ISO | Install network → **hub** ingress | MCE Infrastructure Operator |
| **2 — Ironic install** | `AgentClusterInstall` installing; BMH `provisioning` | **Within new cluster** machine network + OOB → CP | OCP 4.20 IPI bare metal |
| **3 — ACM management** | `ManagedCluster` imported | **New cluster ↔ hub** | ACM 2.16 Networking |

> **Virtual media / no provisioning network:** Skip DHCP/TFTP ports (67, 68, 69). Red Hat recommends virtual media for iDRAC10; provisioning network is not tested on that path. Use `idrac-virtualmedia://` (Dell), not `redfish-virtualmedia://`.

---

## Phase 1 — Discovery (install hosts → hub)

Install targets reach the hub's Assisted Installer services over HTTPS. This is **outbound from the install VLAN to hub routes** — not east-west between bare-metal nodes.

| Port | Protocol | Direction | Purpose | If blocked — typical symptoms |
|------|----------|-----------|---------|-------------------------------|
| **443** | HTTPS | Install host → `assisted-service-multicluster-engine.apps.<hub-domain>` | Agent registration, validation, install orchestration | No `Agent` CR on hub; agent service logs show connection timeout or TLS reset; host stuck after ISO boot |
| **443** | HTTPS | Install host → `assisted-image-service-multicluster-engine.apps.<hub-domain>` | Live rootfs download (`coreos.live.rootfs_url`) | Early boot hang; `curl: (35) Connection reset by peer` to assisted-image-service; kernel panic `Unable to mount root fs on unknown-block(0,0)` if rootfs never mounts |
| **443** | HTTPS | Install host → container registries | Image pulls during discovery validation | Agent validations fail on pull connectivity; registry timeout in agent logs |
| **80** | HTTP | Install host → rootfs/ISO source | Disconnected/mirror environments (when HTTP used) | Same as rootfs failure when mirror serves over HTTP only |

**Hub egress (separate rule):** Hub `assisted-image-service` → mirror or `AgentServiceConfig` image source on **443** (or **80** disconnected). Symptom on hub: `InfraEnv` `ImageCreated=False`; ISO never generated.

**Proxy note:** Discovery hosts honor `InfraEnv.spec.proxy` and hub `trustedCA`. See [cim-hub-setup.md](./cim-hub-setup.md). This is independent of Phase 2 TCP rules.

**Deeper guide:** [agent-install-rootfs-ssl-failure.md](../troubleshooting/agent-install-rootfs-ssl-failure.md)

### Example firewall rules (Phase 1)

```
ALLOW TCP <install-vlan-subnet>  →  <hub-ingress-vip>:443
ALLOW TCP <hub-node-subnet>      →  <mirror-or-registry-vip>:443
```

---

## Phase 2 — Ironic / Metal³ install (machine network + OOB)

Per OCP 4.20: *"Certain ports must be open **between cluster nodes**."* Ironic runs on the **cluster being installed** (bootstrap, then control plane) — not on the ACM hub. Firewall drops here show up as BMH stuck in `provisioning`, Ironic log retries, or network-team alerts on **9999** / **6385**.

### Machine network (east-west)

| Port | Protocol | Direction | Purpose | If blocked — typical symptoms |
|------|----------|-----------|---------|-------------------------------|
| **9999** | TCP | Ironic conductor (bootstrap/CP) → each bare-metal node | Ironic Python Agent (IPA) API during deploy | BMH `provisioning` indefinitely; `provisioner.ironic` logs: timeout reaching node; network team sees **drops on 9999**; deploy ramdisk hangs |
| **6385** | TCP | Clients / internal → bootstrap then CP nodes | Ironic API | Install cannot drive provisioning state machine; ironic-conductor errors calling API; drops on **6385** |
| **5050** | TCP | Between cluster nodes | Ironic Inspector API (hardware introspection) | Inspection timeout; BMH stuck `inspecting`; inspector cannot reach nodes |
| **80** | TCP | Nodes → bootstrap/CP | RHCOS image stream (non-cached / certain paths) | Slow or failed image stage when image caching disabled |
| **123** | UDP | All nodes → NTP server | Time sync | TLS/cert validation failures; skew-related agent or ironic errors |

### Out-of-band (BMC) → machine network

| Port | Protocol | Direction | Purpose | If blocked — typical symptoms |
|------|----------|-----------|---------|-------------------------------|
| **6180** | TCP | BMC (OOB subnet) → bootstrap + CP on **machine network** | Virtual media HTTP image (default since OCP 4.13) | Virtual media attach succeeds but deploy image fetch fails; BMH provisioning stalls; BMC cannot pull ramdisk/kernel |
| **6183** | TCP | BMC (OOB subnet) → bootstrap + CP | Virtual media HTTPS image | Same as 6180 when TLS virtual media enabled |

### Internal-only (do not request on perimeter firewall)

| Port | Notes |
|------|-------|
| **6388** | Proxy for 6385 *inside* the cluster (`metal3-state` Service). A `502` on `metal3-state...:6388` is an in-cluster Ironic health issue — not fixed by opening 6388 on the datacenter firewall. |
| **5051** | Proxy for 5050 inside the cluster. |

### Skip unless using a provisioning network

| Port | Purpose |
|------|---------|
| 67, 68 | DHCP on provisioning VLAN |
| 69 | TFTP on provisioning VLAN |
| 8080, 8083 | Image caching from BMC to provisioner (alternative to 6180/6183 path) |

### Example firewall rules (Phase 2)

```
# Machine network — Ironic east-west
ALLOW TCP <bootstrap-ip>, <cp-node-ips>  →  <all-node-machine-ips>:9999
ALLOW TCP <ironic-client-subnet>         →  <bootstrap-ip>, <cp-node-ips>:6385
ALLOW TCP <all-node-machine-ips>       →  <ntp-server-ip>:123

# OOB management → machine network (virtual media)
ALLOW TCP <bmc-oob-subnet>  →  <bootstrap-ip>, <cp-node-ips>:6180
ALLOW TCP <bmc-oob-subnet>  →  <bootstrap-ip>, <cp-node-ips>:6183
```

**MCE doc caveat:** Some MCE tables label 9999/6385 with hub↔spoke direction. For CIM agent install, trust **OCP 4.20** for traffic path: east-west on the **new cluster's machine network**, plus OOB → CP.

---

## Phase 3 — ACM management (new cluster ↔ hub)

Required once the cluster API exists and Hive auto-imports. Bidirectional **443** and **6443**. See [networking-requirements-2.16.md](./networking-requirements-2.16.md).

| Port | Protocol | Direction | Purpose | If blocked — typical symptoms |
|------|----------|-----------|---------|-------------------------------|
| **6443** | HTTPS | Managed cluster → hub API server | Klusterlet registration agent watches hub | `ManagedCluster` `AvailableUnknown`; *"connection check from the managed cluster to the hub cluster has failed"*; stale `ManagedClusterLease`; cluster shows **Unknown** in ACM console |
| **6443** | HTTPS | Hub → managed cluster API | Hub provisions/manages klusterlet | Import incomplete; hub cannot reach spoke API |
| **443** | HTTPS | Managed cluster → hub routes | Metrics and alerts push | Observability gaps; addon status degraded (may not block install) |
| **443** | HTTPS | Hub → managed cluster routes | Log retrieval via work manager | Search console cannot pull pod logs from spoke |

**Critical — klusterlet and proxy:** Registration and work agents use **mTLS to the hub API** and **do not support HTTP proxy**. If the new cluster has a `cluster-wide` proxy, klusterlet traffic must reach hub **6443** directly (bypass or `noProxy`). Symptom matches hub connection check failure even when discovery proxy worked.

**MCE note:** Managed cluster must reach **hub control plane node IPs**, not only a VIP — confirm firewall allows the actual API endpoint set.

### Example firewall rules (Phase 3)

```
ALLOW TCP <new-cluster-node-subnet>  →  <hub-api-endpoint>:6443
ALLOW TCP <new-cluster-node-subnet>  →  <hub-ingress-vip>:443
ALLOW TCP <hub-node-subnet>            →  <new-cluster-api-vip>:6443
ALLOW TCP <hub-node-subnet>            →  <new-cluster-ingress-vip>:443
```

**Deeper guide:** [managed-cluster-lease-not-updated.md](../troubleshooting/managed-cluster-lease-not-updated.md)

---

## Symptom → phase quick lookup

Use this when triaging live — map the symptom back to the phase and port set.

| Symptom | Likely phase | Check ports / path |
|---------|--------------|-------------------|
| No `Agent` CR; discovery ISO boots but host never registers | 1 | 443 to `assisted-service` |
| `curl: (35)` or rootfs URL failure in boot logs | 1 | 443 to `assisted-image-service`; proxy/`trustedCA` |
| Kernel panic `unknown-block(0,0)` at boot | 1 or boot order | Rootfs 443 **or** booted from empty local disk (not firewall) |
| `InfraEnv` `ImageCreated=False` | 1 (hub) | Hub → mirror 443 |
| BMH `provisioning` stuck; drops on **9999** | 2 | Conductor → node:9999 on machine network |
| Drops on **6385**; ironic API errors | 2 | → bootstrap/CP:6385 |
| `metal3-state:6388` 502 in cluster logs | 2 (in-cluster) | Ironic pod health — **not** perimeter 6388 |
| Virtual media attached but deploy fails | 2 | OOB → CP:6180 or 6183 |
| `ManagedCluster` imported; hub connection check failed | 3 | 6443 + 443 bidirectional; klusterlet proxy bypass |
| Cluster **Unknown**; lease not updating | 3 | 6443 managed → hub API |

---

## Preflight automation

The bare-metal dev sandbox encodes Phase 2 port probes as check ID `network_firewall_install_ports` (6180, 6183, 9999, 6385). See [HARNESS.md](../../bare-metal-dev-sandbox/HARNESS.md).

Phase 1 and Phase 3 probes are environment-specific (hub routes, API VIPs) — validate from a jump host on the install VLAN with `curl` to hub routes and API health endpoints.

---

## What to hand the network team

One-page ask (fill placeholders only):

1. **Install VLAN → hub:** TCP 443 to assisted-service and assisted-image-service routes.
2. **Machine network:** TCP 9999 (CP/bootstrap → nodes), TCP 6385 (→ CP/bootstrap), UDP 123 (→ NTP).
3. **OOB → machine network:** TCP 6180 and/or 6183 (BMC subnet → CP/bootstrap).
4. **New cluster ↔ hub:** Bidirectional TCP 443 and 6443; klusterlet must not traverse HTTP proxy.
5. **Hub → mirror:** TCP 443 for ISO/rootfs cache (disconnected: may include 80).

---

*AI-assisted content. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md).*

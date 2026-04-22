# ACM 2.16 — Network Connectivity Requirements

> Source: https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html-single/networking/index

---

## Core Hub ↔ Managed Cluster Connectivity

### Hub Cluster Outbound (hub → managed cluster)

| Protocol | Port | Destination | Purpose |
|---|---|---|---|
| HTTPS | **443** | Managed cluster route IP | Dynamic log retrieval via `klusterlet-addon-workmgr` from search console |
| HTTPS | **6443** | Managed cluster Kubernetes API server IP | Provisioning the klusterlet during cluster import/installation |

### Hub Cluster Inbound (managed cluster → hub)

| Protocol | Port | Source | Purpose |
|---|---|---|---|
| HTTPS | **443** | Managed cluster → hub route IP | Managed cluster pushes metrics and alerts (requires OCP on managed cluster) |
| HTTPS | **6443** | Managed cluster → hub API server IP | Managed cluster watches hub Kubernetes API for changes |

---

### Managed Cluster Inbound (from hub)

| Protocol | Port | Source | Purpose |
|---|---|---|---|
| HTTPS | **443** | Hub → managed cluster route | Log retrieval via `klusterlet-addon-workmgr` |
| HTTPS | **6443** | Hub → managed cluster API server | Klusterlet installation/provisioning |

### Managed Cluster Outbound (to hub and external)

| Protocol | Port | Destination | Purpose |
|---|---|---|---|
| HTTPS | **443** | Hub route IP | Push metrics and alerts |
| HTTPS | **6443** | Hub Kubernetes API server IP | Watches hub API server for changes |
| HTTPS | **443** | Image repository IP | Pull OCP and ACM images |
| HTTPS | **443** | GitHub / Object Store / Helm repo IP | Only required if using Application lifecycle, GitOps, or Argo CD |

---

## Minimum Required Ports for Basic Cluster Management

For a simple "import and manage" scenario (no GitOps, no Submariner):

| From | To | Port | Protocol |
|---|---|---|---|
| Hub cluster | Managed cluster route | 443 | HTTPS |
| Hub cluster | Managed cluster API | 6443 | HTTPS |
| Managed cluster | Hub cluster route | 443 | HTTPS |
| Managed cluster | Hub cluster API | 6443 | HTTPS |
| Managed cluster | Image registry | 443 | HTTPS |

> **Key point:** Connectivity is **bidirectional on both 443 and 6443**. Both clusters must reach each other's API servers (6443) and ingress routes (443). The managed cluster's klusterlet agent initiates outbound connections to the hub, while the hub also reaches out to the managed cluster for log retrieval and initial provisioning.

---

## Additional Internal Namespace Connectivity (NetworkPolicy / Firewall)

These apply inside the clusters and matter for NetworkPolicy or host-level firewall rules.

### Hub cluster (`open-cluster-management` namespace)
- → Kubernetes API: **6443**
- → Console API: **4000**
- → Application UI: **3001**
- → OpenShift DNS: **5353** (Governance component)

### Managed cluster
- `open-cluster-management-agent-addon` → Kube API: **6443**
- `open-cluster-management-addon` → Kube API: **6443** (Governance)

---

## Situational / Optional Connectivity

### ObjectStore (Cluster Backup Operator or Observability long-term storage)
- Hub outbound → ObjectStore: **HTTPS 443**

### Bare Metal with Hive Operator (cluster provisioning only)
- Hub ↔ `libvirt` provisioning host: **Layer 2 or Layer 3 full IP connectivity** (no specific port; only required during initial cluster creation, not upgrades)

### Submariner (optional — cross-cluster pod/service networking)

**What is Submariner?**
Submariner is an optional open-source add-on that creates encrypted network tunnels between the worker/gateway nodes of separate clusters. Without it, ACM-managed clusters are administratively connected (ACM can deploy apps and enforce policies) but workloads running *inside* those clusters cannot communicate with each other directly at the network level.

**When you need it:**
- A pod in Cluster A needs to call a service running in Cluster B
- Shared databases or backends accessed by workloads across multiple clusters
- Active-active multi-cluster workloads requiring direct pod-to-pod communication

**When you don't need it:**
- ArgoCD deploying applications to managed clusters — no Submariner required
- ACM managing cluster lifecycle, policies, or observability — no Submariner required
- Any scenario where workloads are self-contained within a single cluster

For an ACM + ArgoCD setup focused on deployment and management, **Submariner is not required**.

| Port | Protocol | Purpose | Required? |
|---|---|---|---|
| **4500** | UDP | IPsec NAT-T (default, customizable) | Yes |
| **4800** | UDP | VXLAN — intra-cluster with OpenShiftSDN CNI | Yes |
| **4490** | UDP | NAT Discovery | Yes |
| 500 | UDP | IPSec on gateway nodes | Situational |

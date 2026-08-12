---
review:
  status: unreviewed
  notes: "AI-generated 2026-08-03 from ACM fleet operations research session. Cross-references verified against RHACM 2.15–2.16 docs and workspace NVMe ansible example."
---

# Fleet Ad-Hoc Data Gathering on Managed Clusters

> **Audience:** Platform engineers who need to run one-off diagnostics or collect host-level data across many OpenShift clusters registered in RHACM.
> **Purpose:** Choose a pattern when ACM inventory and hub→spoke API access are available, but there is no native “run this command on every node in the fleet” feature.

---

## What ACM does and does not provide

RHACM is a **hub-and-spoke control plane**.
It indexes fleet metadata, distributes Kubernetes manifests, and enforces policies.
It does **not** expose a fleet-wide shell, `kubectl exec`, or `ansible all -m shell` primitive.

| ACM capability | Useful for ad-hoc gathering? |
|----------------|------------------------------|
| [Search](search-setup.md) | **Discovery** — find resources/clusters matching a query (read-only) |
| Cluster Proxy + `clusteradm proxy kubectl` | **Per-cluster API** access from the hub |
| `ManifestWork` / `clusteradm create work` | **Push** a Job or DaemonSet that runs a command on spokes |
| Policies | **Declarative** baseline — not one-off diagnostics |
| ClusterCurator / PolicyAutomation → AAP | **Lifecycle or compliance triggers** — not interactive ad-hoc |

**Mental model:** ACM answers *which clusters* (and optionally targets them).
Something else answers *run this on each node and return output*.

Nodes are **scoped inside each spoke’s API**.
A fleet operation is always: **hub → cluster → node(s)**.

---

## Decision guide

```
Need host-level or node-level data from the fleet?
│
├─ "Find where a condition exists" (failed pods, missing CR, label)
│   → ACM Search (GraphQL / UI)
│
├─ "Run kubectl/oc against one cluster from the hub"
│   → clusteradm proxy kubectl --cluster-name <name> -- <args>
│
├─ "Same K8s-native check on many clusters" (API objects, not host shell)
│   → Loop proxy kubectl, or Search API
│
├─ "Run a host command once" (nvme discover, disk info, sysfs read)
│   → Per-cluster: oc debug node/<name> -- chroot /host …
│   → Fleet: wrapper script or Ansible (see patterns below)
│
├─ "Repeatable fleet diagnostic, Git-reviewed"
│   → ManifestWork + privileged Job/DaemonSet + Placement
│
└─ "Arbitrary commands, external systems, flexible inventory"
│   → ansible-core or AWX/AAP + stolostron.core inventory
```

---

## Pattern 1 — ACM Search (discovery only)

Use when you need to **locate** resources before acting.

Examples:

- Pods in `Failed` state across clusters
- Clusters missing a storage class or operator
- Nodes with a specific label

Search indexes metadata; it does not run commands or return `oc debug` output.
See [search-setup.md](search-setup.md) and [ACM 2.16 Search docs](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html/search/acm-search).

---

## Pattern 2 — Hub-side kubectl per cluster (Cluster Proxy)

With the **cluster proxy** add-on healthy on hub and spokes, run spoke API commands from the hub.
ACM **2.10+** enables cluster proxy and ManagedServiceAccount by default for clusters created or imported via the console; after hub upgrades, verify add-ons are still `Available` — re-enable manually if disabled ([ACM clusters — cluster proxy add-on](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html/clusters/index)).

`clusteradm` is the OCM CLI ([clusteradm proxy kubectl](https://github.com/open-cluster-management-io/clusteradm/blob/main/README.md#cluster-proxy)); install it on the workstation where you run these commands if it is not already present.

```bash
# hub kubeconfig context
clusteradm proxy kubectl --cluster-name prod-east-01 -- get nodes -l node-role.kubernetes.io/worker
clusteradm proxy kubectl --cluster-name prod-east-01 -- get co
```

For fleet scope, loop over managed clusters:

```bash
for c in $(oc get managedclusters -o jsonpath='{.items[*].metadata.name}'); do
  echo "=== $c ==="
  clusteradm proxy kubectl --cluster-name "$c" -- get nodes --no-headers | wc -l
done
```

**Fit:** API-level checks (nodes, CO status, CRs).
**Not fit:** Host-namespace tools (`nvme`, `dmidecode`) without `oc debug`.

Prerequisites: Cluster Proxy addon healthy; hub RBAC to create proxy sessions.
See [OCM Cluster Proxy](https://open-cluster-management.io/docs/getting-started/integration/cluster-proxy/).

---

## Pattern 3 — `oc debug` + per-cluster automation (host-level)

For **host network namespace** or **chroot /host** work, use debug pods on each node.
This is the pattern used in the workspace NVMe fabric check:

- [NVMe discover via oc debug](../../ocp/troubleshooting/nvme-tcp-storage-network/ansible/README.md)
- Playbook: `devops/ocp/troubleshooting/nvme-tcp-storage-network/ansible/nvme-discover.yml`

Single node:

```bash
oc debug node/worker-0 --quiet -- chroot /host \
  nvme discover -t tcp -a 10.100.1.10 -s 4420 -w ens1f0
```

**Fleet extension:** wrap the existing per-cluster playbook:

1. On the hub, list `ManagedCluster` objects (optionally filter by label / Placement).
2. For each cluster: obtain spoke API access (proxy, ManagedServiceAccount token, or kubeconfig).
3. List worker nodes in that cluster.
4. Run the playbook with site-specific `vars.yml` (discovery IPs and `host_iface` often differ per site).

```bash
# Conceptual — one cluster per invocation
ansible-playbook nvme-discover.yml -e @vars-prod-east.yml --forks 8
```

AAP is **not required** — `ansible-core` from a bastion or CI job is enough.
ACM supplies **inventory and connectivity**; Ansible supplies **execution**.

---

## Pattern 4 — ManifestWork + Job or DaemonSet (Kubernetes-native fleet push)

Push a one-shot **Job** (per node or per cluster) or **DaemonSet** (every node) via `ManifestWork`, targeted with Placement:

```bash
clusteradm create work fleet-nvme-check \
  -f job.yaml \
  --placement default/bare-metal-clusters
```

Typical Job spec (simplified):

- `hostNetwork: true`, `hostPID: true`
- Mount host `/` at `/host`
- Command: `chroot /host nvme discover …`
- Results: pod logs, or write to a ConfigMap on the spoke

**When to use:**

- Diagnostic is **stable** and should be **Git-reviewed**
- You want an audit trail as Kubernetes objects
- Operators run from the hub without a separate automation server

**When to avoid:**

- Truly ad-hoc parameters change every run
- Aggregating output across dozens of clusters is painful
- Privileged workload on the entire fleet needs strong change control

See [distribute-yaml-to-all-clusters.md](../examples/distribute-yaml-to-all-clusters.md) and [OCM ManifestWork](https://open-cluster-management.io/docs/concepts/work-distribution/manifestwork/).

---

## Pattern 5 — Ansible / AWX / AAP with ACM inventory

For flexible ad-hoc gathering (shell, modules, external APIs):

1. Enable **ClusterProxy** and **ManagedServiceAccount** addons on hub and spokes.
2. Install [stolostron.core](https://github.com/stolostron/ansible-collection.core) (`ocm_managedcluster` inventory plugin).
3. Run playbooks from AWX/AAP or `ansible-playbook` locally.

Demo reference: [acm-ansible-collection-demo](https://github.com/stolostron/acm-ansible-collection-demo).

**Fit:** Arbitrary commands, CMDB/DNS/ticketing, mixed fleet and external targets.
**Cost:** Controller setup (optional), credential and RBAC management.

For ACM-native **triggered** automation (not interactive ad-hoc), see [acm-ansible-integration.md](acm-ansible-integration.md).

---

## Worked example — NVMe discover across a fleet

| Layer | Tool | Action |
|-------|------|--------|
| Which clusters? | ACM `ManagedCluster` + labels | `-l storage=nvme-tcp` |
| Spoke API | Cluster Proxy / MSA | kubeconfig or `clusteradm proxy` |
| Which nodes? | `oc get nodes` per cluster | workers only |
| Host command | `oc debug` + `chroot /host` | `nvme discover` with `-w <iface>` |
| Orchestration | Ansible playbook (existing) | `--forks` for parallelism |

Prerequisites from the NVMe guides:

- Unique host NQN per node — [nvme-host-nqn-duplicate](../../ocp/troubleshooting/nvme-host-nqn-duplicate/README.md)
- Dual storage NIC design (do not bond storage paths) — [NVMe/TCP README](../../ocp/troubleshooting/nvme-tcp-storage-network/README.md)

---

## Security and operations

| Topic | Guidance |
|-------|----------|
| RBAC | `ManifestWork` write on the hub is high privilege; work-agent applies with broad spoke permissions |
| `oc debug` | Creates privileged pods; restrict who can run fleet wrappers |
| Audit | Prefer Git-reviewed Job manifests over unaudited shell loops for recurring checks |
| Site variance | Keep per-site vars out of git (`vars.yml` gitignored) when they contain IPs or credentials |
| Rate / blast radius | Use `--forks` limits; avoid saturating API servers on large fleets |

**Promotion path:** ad-hoc Ansible loop → parameterized Job in Git → ManifestWork + Placement (or Policy if the check becomes a mandate).

---

## Related reading

| Topic | Location |
|-------|----------|
| ACM + Ansible integration (hooks, not ad-hoc exec) | [acm-ansible-integration.md](acm-ansible-integration.md) |
| Greenfield fleet architecture | [greenfield-fleet-architecture.md](greenfield-fleet-architecture.md) |
| Fleet control spectrum (ACM vs Argo) | [fleet-control-spectrum.md](../../fleet-control-spectrum.md) |
| Push YAML fleet-wide | [distribute-yaml-to-all-clusters.md](../examples/distribute-yaml-to-all-clusters.md) |
| NVMe discover playbook | [nvme-tcp-storage-network/ansible](../../ocp/troubleshooting/nvme-tcp-storage-network/ansible/README.md) |
| ACM Search setup | [search-setup.md](search-setup.md) |

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

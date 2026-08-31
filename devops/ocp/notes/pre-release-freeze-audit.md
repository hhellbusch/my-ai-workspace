---
review:
  status: unreviewed
  notes: "Handoff dump of frozen/one-way/expand-only live values. 2026-08-31."
---

# Pre-release freeze audit

Pull the live values that **cannot** be changed (or cannot be undone) before you hand a cluster to a customer.

> **Audience:** Consultant or platform engineer signing off an ACM / ABI / IPI cluster.
>
> **Purpose:** Compare the frozen contract to the SOW / install-config. If it is wrong, rebuild — do not promise a Day-2 fix.

Catalog (why each field is frozen): [install-config-immutability.md](install-config-immutability.md).
CIDR math: [cluster-network-hostprefix.md](cluster-network-hostprefix.md).

This is **not** a full health check (`co`, operators, etcd). It is the immutability slice.

---

## How to use it

1. Log into the **spoke** (customer cluster). ACM: `oc --kubeconfig` from `ClusterDeployment` or the ManagedCluster import kubeconfig.
2. Paste the dump below. Save stdout with the ticket / handoff pack.
3. Fill the sign-off table against the agreed install-config.
4. If this was ACM Agent-based, also dump hub `AgentClusterInstall.spec.networking` and confirm it matches the spoke `Network` CR.

`jq` is optional; install it if you want the formatted dump.

---

## Spoke dump (frozen / one-way / expand-only)

```bash
echo "=== identity / platform ==="
oc get dns cluster -o jsonpath='baseDomain: {.spec.baseDomain}{"\n"}'
oc get infrastructure cluster -o jsonpath='platform: {.status.platform}{"\ninfrastructureName: "}{.status.infrastructureName}{"\napiServerURL: "}{.status.apiServerURL}{"\ncontrolPlaneTopology: "}{.status.controlPlaneTopology}{"\ninfrastructureTopology: "}{.status.infrastructureTopology}{"\n"}'

echo "=== version / feature gate / capabilities (one-way) ==="
oc get clusterversion version -o jsonpath='version: {.status.desired.version}{"\nchannel: "}{.spec.channel}{"\n"}'
oc get featuregate cluster -o jsonpath='featureSet: {.spec.featureSet}{"\n"}'
# Empty featureSet = Default (good). TechPreviewNoUpgrade is a hard stop for production.
oc get clusterversion version -o jsonpath='spec.capabilities: {.spec.capabilities}{"\nstatus.enabled: "}{.status.capabilities.enabledCapabilities}{"\n"}'

echo "=== cluster / service network (frozen base + hostPrefix; mask expand-only) ==="
oc get network.config.openshift.io cluster -o jsonpath='networkType: {.status.networkType}{"\nclusterNetwork: "}{.spec.clusterNetwork}{"\nserviceNetwork: "}{.spec.serviceNetwork}{"\nserviceNodePortRange: "}{.spec.serviceNodePortRange}{"\n"}'
oc get network.config.openshift.io cluster -o jsonpath='status.clusterNetwork: {.status.clusterNetwork}{"\nstatus.serviceNetwork: "}{.status.serviceNetwork}{"\n"}'

echo "=== OVN (genevePort frozen; join/transit/masquerade/IPsec/MTU are Day-2 — snapshot anyway) ==="
oc get network.operator.openshift.io cluster -o jsonpath='genevePort: {.spec.defaultNetwork.ovnKubernetesConfig.genevePort}{"\nmtu: "}{.spec.defaultNetwork.ovnKubernetesConfig.mtu}{"\nipsec: "}{.spec.defaultNetwork.ovnKubernetesConfig.ipsecConfig}{"\njoin: "}{.spec.defaultNetwork.ovnKubernetesConfig.ipv4.internalJoinSubnet}{"\n"}'
oc get network.operator.openshift.io cluster -o jsonpath='gatewayConfig: {.spec.defaultNetwork.ovnKubernetesConfig.gatewayConfig}{"\n"}'

echo "=== per-node overlay slices (must be hostPrefix inside cluster CIDR) ==="
oc get nodes -o custom-columns=NAME:.metadata.name,ROLE:.metadata.labels.node-role\.kubernetes\.io/control-plane,ARCH:.status.nodeInfo.architecture,PODCIDR:.spec.podCIDR,PODCIDRS:.spec.podCIDRs

echo "=== FIPS (frozen) — MachineConfig present if enabled ==="
oc get machineconfig -o name | grep -i fips || echo "(no *fips MachineConfig — cluster is not FIPS)"

echo "=== cpuPartitioningMode (frozen if AllNodes at install) ==="
oc get machineconfig -o name | grep -i cpu-partitioning || echo "(no cpu-partitioning MachineConfig — workload partitioning not enabled at install)"

echo "=== control-plane count (treat replica count as frozen) ==="
oc get nodes -l node-role.kubernetes.io/control-plane -o name | wc -l
oc get nodes -l node-role.kubernetes.io/master -o name 2>/dev/null | wc -l

echo "=== kubelet maxPods (Day-2, but customers confuse it with hostPrefix) ==="
oc get kubeletconfig
oc get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"  pods="}{.status.allocatable.pods}{"\n"}{end}'
```

Spot-check one node for FIPS and SMT (needs `oc debug`; skip if debug image is blocked):

```bash
NODE=$(oc get nodes -o jsonpath='{.items[0].metadata.name}')
oc debug node/"$NODE" --quiet -- chroot /host sh -c 'echo fips=$(cat /proc/sys/crypto/fips_enabled); lscpu | grep -E "Architecture|Thread"'
```

OVN per-node subnet annotation (confirms the host slice, not the join subnet):

```bash
oc get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"  "}{.metadata.annotations.k8s\.ovn\.org/node-subnets}{"\n"}{end}'
```

---

## Hub dump (ACM Agent-based)

Intent on the hub must match the spoke `Network` CR. Mismatch means the ACI value never landed — rebuild.

```bash
NS=<cluster-namespace>   # often same as ClusterDeployment name
oc -n "$NS" get agentclusterinstall -o jsonpath='{.items[0].spec.networking}{"\n"}'
oc -n "$NS" get agentclusterinstall -o jsonpath='imageSet: {.items[0].spec.imageSetRef.name}{"\n"}'
```

Do **not** treat `Agent` / BMH NIC IPs as `clusterNetwork`. Those are machine/host addresses.

---

## Sign-off (expected vs live)

Copy into the handoff notes. Fail the release if a **Frozen** row disagrees with the SOW.

| Check | Status | Expected | Live | Pass? |
|-------|--------|----------|------|-------|
| `baseDomain` / API URL | Frozen | | | |
| Platform type | Frozen | baremetal / none / … | | |
| FIPS | Frozen | on / off | | |
| `TechPreviewNoUpgrade` | Frozen if on | unset | | |
| `cpuPartitioningMode` | Frozen if on | off / AllNodes | | |
| Control-plane count | Treat frozen | 3 or 1 | | |
| Node architecture | Treat frozen | amd64 / … | | |
| `networkType` | Frozen | OVNKubernetes | | |
| clusterNetwork CIDR **base** | Frozen | e.g. `100.100.0.0` | | |
| clusterNetwork **mask** | Expand-only | e.g. `/15` | | |
| `hostPrefix` | Frozen | e.g. `23` | | |
| Each node `podCIDR` | derived | `/23` inside cluster CIDR, no overlap | | |
| serviceNetwork | Frozen | e.g. `100.99.0.0/16` | | |
| `genevePort` | Frozen | `6081` unless agreed | | |
| NodePort range | Expand-only | default or expanded | | |
| Capabilities | One-way | none extra / listed | | |

Hub ACI `spec.networking` matches spoke `Network` spec/status: yes / no.

---

## What this audit does not decide

Day-2 (wrong ≠ rebuild by itself): join/transit/masquerade, overlay MTU migration, IPsec, Proxy, pull secret, etcd encryption, extra workers, `maxPods`.

Still dump join/MTU/IPsec above so the customer has a baseline.

Not classified here: VIP moves, cloud VPC, HCP — see the catalog “Still not catalogued.”

---

## Related

- [install-config-immutability.md](install-config-immutability.md)
- [cluster-network-hostprefix.md](cluster-network-hostprefix.md)
- [vlan-segmentation.md](../examples/networking/vlan-segmentation.md) — `machineNetwork` is installer-consumed

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

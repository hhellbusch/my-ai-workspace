# MTU Configuration: Node-Level vs Cluster-Level

> **AI Disclosure:** This documentation was created with AI assistance (Claude 3.5 Sonnet via Cursor) on 2026-02-04.

## Quick Answer

**Can you configure a single node with different MTU than the rest of the cluster?**

**No.** All nodes in an OpenShift cluster must have the same cluster network MTU configuration. Having mismatched MTU between nodes will cause networking failures.

---

## Why MTU Must Be Uniform Across the Cluster

### Technical Reasons

1. **OVN-Kubernetes Overlay Network**
   - The overlay network spans all cluster nodes
   - Geneve tunnels connect nodes to each other
   - MTU mismatch breaks pod-to-pod communication across nodes
   - The cluster network MTU is set cluster-wide at installation time

2. **Pod Communication Across Nodes**
   ```
   Pod on Node A (MTU 1400) → Pod on Node B (MTU 1500)
   ```
   - If Node B has higher MTU, it may send packets too large for Node A
   - Node A will drop oversized packets or fragment incorrectly
   - Result: Broken pod-to-pod networking

3. **Cluster Operators and Control Plane**
   - etcd, API server, and other control plane pods communicate across nodes
   - Different MTU values cause control plane instability
   - Can lead to cluster degradation or failure

### OpenShift Architecture

```
┌─────────────────────────────────────────────┐
│           Cluster Network MTU               │
│         (Set cluster-wide: 1400)            │
├─────────────────────────────────────────────┤
│  Node 1        Node 2        Node 3         │
│  MTU 1500      MTU 1500      MTU 1500       │ ← Physical interfaces
│    ↓             ↓             ↓             │
│  OVN 1400      OVN 1400      OVN 1400       │ ← Overlay (must match)
│    ↓             ↓             ↓             │
│  Pods          Pods          Pods           │
└─────────────────────────────────────────────┘

ALL nodes must have same overlay MTU
```

---

## What You're Actually Trying to Solve

When AAP on OpenShift has MTU issues connecting to external hosts, the problem is **not** about individual cluster nodes. It's about the **network path between the cluster and external networks**.

### The Real Problem

```
┌──────────────────┐         ┌───────────┐         ┌──────────────┐
│  AAP Pod         │         │  Network  │         │ External     │
│  MTU 1400        │────────▶│  Devices  │────────▶│ Host         │
│  (on any node)   │         │  (varies) │         │ MTU 1500     │
└──────────────────┘         └───────────┘         └──────────────┘
                                   ▲
                                   │
                          MTU mismatch here
                          (not at cluster nodes)
```

The issue is:
- **Source:** AAP pod on cluster (MTU 1400)
- **Destination:** External host on different network (MTU 1500)
- **Problem:** Intermediate network devices, firewalls, or routers between them

---

## What You CAN Do

### Option 1: Change Cluster-Wide MTU (Disruptive)

If you need to change MTU, you must change it **for the entire cluster**.

**Requirements:**
- Maintenance window (cluster disruption)
- At least two rolling reboots of all nodes
- Affects all workloads

**Process:**
```bash
# Check current MTU
oc get network.operator.openshift.io cluster -o yaml

# Initiate MTU migration (example: 1400 → 1300)
oc patch network.operator.openshift.io cluster --type=merge --patch '
spec:
  migration:
    mtu:
      network:
        from: 1400
        to: 1300
      machine:
        to: 1300
'

# Monitor migration
oc get network.operator.openshift.io cluster -o yaml | grep -A 20 migration
```

**This is NOT recommended for solving AAP SSH issues to external hosts.**

### Option 2: Configure Network Path (Recommended)

Instead of changing cluster MTU, fix the network path between cluster and external networks.

#### A. MSS Clamping on Network Equipment

Configure TCP Maximum Segment Size on routers/firewalls:

```bash
# Example: Cisco router
interface GigabitEthernet0/1
  ip tcp adjust-mss 1360

# Example: Linux iptables (on gateway/router)
iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN \
  -j TCPMSS --set-mss 1360
```

**MSS Calculation:**
```
MSS = Lowest MTU in path - 40
    = 1400 - 40
    = 1360

(40 bytes = 20 byte IP header + 20 byte TCP header)
```

**Why this works:**
- Forces TCP to use smaller segments
- No MTU changes needed
- Works for all pods in cluster
- Non-disruptive

#### B. Enable PMTUD (Path MTU Discovery)

Work with network team to:
1. Allow ICMP Type 3 Code 4 ("Fragmentation Needed") between networks
2. Ensure firewalls don't block ICMP unreachable messages
3. Verify routers properly handle PMTUD

**Test PMTUD:**
```bash
# From AAP pod
oc exec -n <namespace> <pod> -- tracepath <target-host>

# Look for:
# - "pmtu XXXX" messages (PMTUD working)
# - "no reply" (PMTUD blocked)
```

#### C. Configure SSH/Ansible Workarounds

Use valid SSH options to work around MTU issues:

```yaml
# In AAP inventory
ansible_ssh_common_args: '-o IPQoS=throughput -o Compression=yes'

# In ansible.cfg
[ssh_connection]
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o IPQoS=throughput
```

---

## Special Case: Dedicated AAP Worker Nodes

**Question:** "Can I have dedicated worker nodes for AAP with different network configuration?"

**Answer:** You can have dedicated nodes for AAP, but they must still use the same cluster network MTU. However, you can:

### 1. Label Nodes for AAP Workloads

```bash
# Label specific nodes for AAP
oc label node worker-aap-01 aap_node_type=automation
oc label node worker-aap-02 aap_node_type=automation
```

### 2. Configure Node-Level Network Settings

While cluster network MTU must match, you can configure **physical interface** settings differently:

```bash
# On dedicated AAP nodes - adjust physical interface settings
# (must still support cluster MTU of 1400)

# Example: Different routing, static routes, etc.
oc debug node/worker-aap-01
chroot /host

# Can add routes to external networks
ip route add 192.168.100.0/24 via 10.0.1.1 dev ens192

# Can configure additional interfaces
# But overlay MTU must still be 1400
```

### 3. Use Node Selectors for AAP Pods

```yaml
# In AAP AutomationController CR
apiVersion: automationcontroller.ansible.com/v1beta1
kind: AutomationController
metadata:
  name: automationcontroller
spec:
  task_replicas: 3
  task_node_selector:
    aap_node_type: automation
```

**This lets you:**
- Dedicate specific nodes to AAP workloads
- Configure node-level network settings (routes, additional interfaces)
- Still maintain cluster network MTU consistency

**This does NOT let you:**
- Run nodes with different cluster network MTU
- Have different OVN overlay MTU per node
- Bypass cluster network requirements

---

## Real-World Scenarios

### Scenario 1: "I want AAP nodes to reach DMZ network with MTU 1500"

**Wrong approach:**
- ❌ Configure AAP worker nodes with MTU 1500

**Right approach:**
- ✅ Keep all nodes at MTU 1400 (cluster requirement)
- ✅ Configure MSS clamping on firewall between cluster and DMZ
- ✅ Ensure ICMP not blocked between networks
- ✅ Use SSH options in Ansible for workaround

### Scenario 2: "External network requires jumbo frames (MTU 9000)"

**Wrong approach:**
- ❌ Configure some nodes with MTU 9000

**Right approach:**
- ✅ Change entire cluster to jumbo frames (MTU 8900 overlay)
- ✅ Requires maintenance window
- ✅ All nodes must support jumbo frames
- ✅ Network infrastructure must support end-to-end

**Pre-requisites for cluster-wide jumbo frames:**
```bash
# All physical network must support MTU 9000
# Check node interfaces
for node in $(oc get nodes -o name); do
  echo "=== $node ==="
  oc debug $node -- chroot /host ip link show | grep mtu
done

# All must show mtu 9000 on physical interfaces
```

### Scenario 3: "Mixed MTU in datacenter - some hosts 1500, some 9000"

**Wrong approach:**
- ❌ Try to match cluster nodes to external host MTU

**Right approach:**
- ✅ Choose cluster MTU based on **lowest MTU in cluster network** minus 100
- ✅ If cluster network is 1500: use cluster MTU 1400
- ✅ If cluster network is 9000: use cluster MTU 8900
- ✅ Handle external network MTU via MSS clamping or routing

**Decision tree:**
```
What's the MTU on the cluster network?
├─ 1500 (standard Ethernet)
│  └─ Use cluster MTU 1400
│     └─ Handle external 9000 via network config
│
├─ 9000 (jumbo frames)
│  └─ Use cluster MTU 8900
│     └─ Handle external 1500 via MSS clamping
│
└─ Mixed (some 1500, some 9000)
   └─ Use lowest: cluster MTU 1400
      └─ All nodes must use 1400
```

---

## Verification: Is My Cluster MTU Uniform?

### Check Cluster Configuration

```bash
# Check cluster-wide MTU setting
oc get network.config.openshift.io cluster -o jsonpath='{.status.clusterNetwork[0].mtu}'

# Check OVN overlay MTU
oc get network.operator.openshift.io cluster -o jsonpath='{.spec.defaultNetwork.ovnKubernetesConfig.mtu}'

# Should both return same value (e.g., 1400)
```

### Check Each Node

```bash
# Check all nodes
for node in $(oc get nodes -o name | cut -d/ -f2); do
  echo "=== $node ==="
  oc debug node/$node -- chroot /host sh -c "
    echo 'Physical interfaces:'
    ip link show | grep -E '^[0-9]|mtu' | grep -v lo
    echo ''
    echo 'OVN interface:'
    ip link show ovn-k8s-mp0 2>/dev/null | grep mtu || echo 'Not found'
  " 2>/dev/null
done
```

**Expected output:**
```
=== worker-01 ===
Physical interfaces:
2: ens192: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
OVN interface:
5: ovn-k8s-mp0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400

=== worker-02 ===
Physical interfaces:
2: ens192: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500
OVN interface:
5: ovn-k8s-mp0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400
```

**All nodes should show:**
- Physical interfaces: MTU 1500 (or 9000 for jumbo)
- OVN interface: MTU 1400 (or 8900 for jumbo) - **must be identical on all nodes**

### Check Pod MTU

```bash
# Pick any pod
oc exec -n <namespace> <pod> -- ip link show eth0 | grep mtu

# Should match cluster network MTU (e.g., 1400)
```

---

## Summary

### ❌ What You CANNOT Do

- Configure individual nodes with different cluster network MTU
- Run some nodes at MTU 1400 and others at MTU 1500
- Have per-node OVN overlay MTU settings
- Mix jumbo frame and standard MTU nodes in same cluster

### ✅ What You CAN Do

- Change MTU cluster-wide (with maintenance window)
- Configure MSS clamping on network equipment
- Enable PMTUD on network path
- Use SSH/Ansible workarounds
- Label nodes for dedicated workloads (AAP nodes)
- Configure node-level routes and additional interfaces
- Ensure physical interfaces support cluster MTU + 100 bytes

### 🎯 Best Approach for AAP SSH MTU Issues

**Don't change cluster configuration.** Instead:

1. **Network-level fixes** (work with network team)
   - MSS clamping: MSS = cluster_MTU - 40
   - ICMP unblocking for PMTUD
   - QoS policies for AAP traffic

2. **Ansible configuration** (workarounds)
   - `IPQoS=throughput`
   - `Compression=yes`
   - Pipelining enabled

3. **Dedicated AAP nodes** (optional, for organization)
   - Label nodes for AAP workloads
   - Configure routes to external networks
   - Still use same cluster MTU

---

## References

- [OpenShift: Changing cluster network MTU](https://docs.openshift.com/container-platform/latest/networking/changing-cluster-network-mtu.html)
- [OVN-Kubernetes Architecture](https://docs.openshift.com/container-platform/latest/networking/ovn_kubernetes_network_provider/about-ovn-kubernetes.html)
- Main troubleshooting guide: [README.md](README.md)
- Technical accuracy review: [TECHNICAL-ACCURACY-REVIEW.md](TECHNICAL-ACCURACY-REVIEW.md)

---

**Last Updated:** 2026-02-04  
**Key Takeaway:** MTU must be uniform across all cluster nodes. Fix external network connectivity issues at the network boundary, not by changing individual nodes.

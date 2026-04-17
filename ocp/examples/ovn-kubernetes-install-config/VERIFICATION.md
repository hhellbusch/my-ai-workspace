# Post-Installation Verification Guide

Comprehensive verification procedures to confirm your OVN-Kubernetes configuration is working correctly.

## Table of Contents

- [Quick Verification](#quick-verification)
- [Network Operator Status](#network-operator-status)
- [OVN Pod Verification](#ovn-pod-verification)
- [Configuration Verification](#configuration-verification)
- [Node-Level Verification](#node-level-verification)
- [Functional Testing](#functional-testing)
- [IPsec Verification](#ipsec-verification-if-enabled)
- [Performance Validation](#performance-validation)
- [Troubleshooting Failed Verification](#troubleshooting-failed-verification)

---

## Quick Verification

Run these commands immediately after installation completes:

```bash
# 1. Check all cluster operators
oc get co
# All should show: AVAILABLE=True, PROGRESSING=False, DEGRADED=False

# 2. Check network operator specifically
oc get co network
# Expected: network 4.x.x True False False XXm

# 3. Verify network type
oc get network.config.openshift.io cluster -o jsonpath='{.spec.networkType}'
# Expected: OVNKubernetes

# 4. Check OVN pods
oc get pods -n openshift-ovn-kubernetes
# All pods should be Running

# 5. Check all nodes are Ready
oc get nodes
# All should show STATUS=Ready
```

**If all these pass, your basic configuration is correct. Continue with detailed verification below.**

---

## Network Operator Status

### Check Operator Health

```bash
# Detailed operator status
oc get co network -o yaml

# Look for conditions
oc get co network -o jsonpath='{.status.conditions[*].type}{"\n"}{.status.conditions[*].status}'

# Check for any degraded conditions
oc get co network -o jsonpath='{.status.conditions[?(@.type=="Degraded")]}'
```

**Expected:**
- `Available: True`
- `Progressing: False`
- `Degraded: False`

### View Operator Configuration

```bash
# Full network operator configuration
oc get network.operator.openshift.io cluster -o yaml

# View just the OVN config
oc get network.operator.openshift.io cluster -o jsonpath='{.spec.defaultNetwork.ovnKubernetesConfig}' | jq
```

### Check Operator Logs

```bash
# View network operator logs
oc logs -n openshift-network-operator deployment/network-operator --tail=50

# Follow logs in real-time
oc logs -n openshift-network-operator deployment/network-operator -f
```

---

## OVN Pod Verification

### List All OVN Pods

```bash
# Get all OVN-related pods
oc get pods -n openshift-ovn-kubernetes -o wide

# Expected pods per node:
# - ovnkube-node-* (one per node)
# - ovs-node-* (one per node)
# Plus ovnkube-control-plane pods on control plane nodes
```

**Expected Output Example:**
```
NAME                                     READY   STATUS    AGE
ovnkube-control-plane-77b9c8d7b5-abc12   2/2     Running   30m
ovnkube-control-plane-77b9c8d7b5-def34   2/2     Running   30m
ovnkube-control-plane-77b9c8d7b5-ghi56   2/2     Running   30m
ovnkube-node-abcd1                       8/8     Running   30m
ovnkube-node-efgh2                       8/8     Running   30m
ovnkube-node-ijkl3                       8/8     Running   30m
ovs-node-abcd1                           1/1     Running   30m
ovs-node-efgh2                           1/1     Running   30m
ovs-node-ijkl3                           1/1     Running   30m
```

### Check Pod Health

```bash
# Check for any restarting pods
oc get pods -n openshift-ovn-kubernetes --field-selector=status.phase!=Running

# Check pod logs for errors
oc logs -n openshift-ovn-kubernetes <pod-name> -c ovnkube-controller --tail=100

# Check all containers in ovnkube-node pod
oc logs -n openshift-ovn-kubernetes <ovnkube-node-pod> -c ovnkube-controller
oc logs -n openshift-ovn-kubernetes <ovnkube-node-pod> -c ovn-controller
oc logs -n openshift-ovn-kubernetes <ovnkube-node-pod> -c ovn-acl-logging
```

### Verify OVN Database Status

```bash
# Check OVN northbound database
oc exec -n openshift-ovn-kubernetes <ovnkube-control-plane-pod> -c northd -- \
  ovn-nbctl show

# Check OVN southbound database
oc exec -n openshift-ovn-kubernetes <ovnkube-control-plane-pod> -c northd -- \
  ovn-sbctl show
```

---

## Configuration Verification

### Verify Custom Subnet Configuration

```bash
# Check internal join subnet
oc get network.operator.openshift.io cluster \
  -o jsonpath='{.spec.defaultNetwork.ovnKubernetesConfig.ipv4.internalJoinSubnet}'
# Expected: 10.245.0.0/16 (or your configured value)

# Check internal transit switch subnet
oc get network.operator.openshift.io cluster \
  -o jsonpath='{.spec.defaultNetwork.ovnKubernetesConfig.gatewayConfig.ipv4.internalTransitSwitchSubnet}'
# Expected: 10.246.0.0/16 (or your configured value)

# Check internal masquerade subnet
oc get network.operator.openshift.io cluster \
  -o jsonpath='{.spec.defaultNetwork.ovnKubernetesConfig.gatewayConfig.ipv4.internalMasqueradeSubnet}'
# Expected: 169.254.0.0/17 (or your configured value)
```

### Verify MTU Configuration

```bash
# Check configured MTU
oc get network.operator.openshift.io cluster \
  -o jsonpath='{.spec.defaultNetwork.ovnKubernetesConfig.mtu}'
# Expected: 1400 (or your configured value)
```

### Verify Geneve Port

```bash
# Check Geneve port
oc get network.operator.openshift.io cluster \
  -o jsonpath='{.spec.defaultNetwork.ovnKubernetesConfig.genevePort}'
# Expected: 6081 (or your configured value)
```

### Verify Complete Configuration

```bash
# Get entire OVN configuration in readable format
oc get network.operator.openshift.io cluster \
  -o jsonpath='{.spec.defaultNetwork.ovnKubernetesConfig}' | jq '.'
```

---

## Node-Level Verification

### Check Internal Join Interface (ovn-k8s-mp0)

```bash
# Access a node
oc debug node/<node-name>

# Once in debug pod:
chroot /host

# Check ovn-k8s-mp0 interface exists and has correct IP
ip addr show ovn-k8s-mp0

# Expected: IP address from internalJoinSubnet (e.g., 10.245.0.0/16)
# Example output:
# 5: ovn-k8s-mp0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400
#     inet 10.245.0.2/16 brd 10.245.255.255 scope global ovn-k8s-mp0
```

### Check Geneve Interface

```bash
# Still in debug pod on node
ip link show genev_sys_6081

# Expected: Interface exists with correct MTU
# Example output:
# 6: genev_sys_6081: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400
```

### Verify MTU on Interfaces

```bash
# Check MTU on all relevant interfaces
ip -o link show | grep -E '(ovn|genev|br-int)' | awk '{print $2, $5}'

# All should show your configured MTU
```

### Check OVS Bridge

```bash
# View OVS bridge configuration
ovs-vsctl show

# Expected: br-int bridge with genev_sys_6081 port
```

### Verify OVN Controller Status

```bash
# Check OVN controller is connected
ovs-appctl -t ovn-controller connection-status
# Expected: connected

# Check OVN controller stats
ovs-appctl -t ovn-controller ct-stats-show
```

### Exit Debug Session

```bash
# Exit chroot and debug pod
exit
exit
```

---

## Functional Testing

### Test 1: Pod-to-Pod Communication (Same Node)

```bash
# Create two test pods
oc run test-pod-1 --image=registry.access.redhat.com/ubi8/ubi --command -- sleep 3600
oc run test-pod-2 --image=registry.access.redhat.com/ubi8/ubi --command -- sleep 3600

# Wait for pods to be ready
oc wait --for=condition=Ready pod/test-pod-1 --timeout=60s
oc wait --for=condition=Ready pod/test-pod-2 --timeout=60s

# Get pod IPs
POD1_IP=$(oc get pod test-pod-1 -o jsonpath='{.status.podIP}')
POD2_IP=$(oc get pod test-pod-2 -o jsonpath='{.status.podIP}')

echo "Pod 1 IP: $POD1_IP"
echo "Pod 2 IP: $POD2_IP"

# Test connectivity
oc exec test-pod-1 -- ping -c 3 $POD2_IP
oc exec test-pod-2 -- ping -c 3 $POD1_IP

# Expected: 0% packet loss
```

### Test 2: Pod-to-Pod Communication (Different Nodes)

```bash
# Create pods on different nodes
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-pod-node1
spec:
  nodeSelector:
    kubernetes.io/hostname: <node1-name>
  containers:
  - name: test
    image: registry.access.redhat.com/ubi8/ubi
    command: ['sleep', '3600']
---
apiVersion: v1
kind: Pod
metadata:
  name: test-pod-node2
spec:
  nodeSelector:
    kubernetes.io/hostname: <node2-name>
  containers:
  - name: test
    image: registry.access.redhat.com/ubi8/ubi
    command: ['sleep', '3600']
EOF

# Wait and test
oc wait --for=condition=Ready pod/test-pod-node1 --timeout=60s
oc wait --for=condition=Ready pod/test-pod-node2 --timeout=60s

POD1_IP=$(oc get pod test-pod-node1 -o jsonpath='{.status.podIP}')
POD2_IP=$(oc get pod test-pod-node2 -o jsonpath='{.status.podIP}')

oc exec test-pod-node1 -- ping -c 3 $POD2_IP
# Expected: 0% packet loss
```

### Test 3: Pod-to-Service Communication

```bash
# Create a service
oc create deployment test-app --image=registry.access.redhat.com/ubi8/ubi -- sleep 3600
oc scale deployment test-app --replicas=2
oc expose deployment test-app --port=8080

# Wait for deployment
oc wait --for=condition=Available deployment/test-app --timeout=60s

# Get service IP
SERVICE_IP=$(oc get svc test-app -o jsonpath='{.spec.clusterIP}')
echo "Service IP: $SERVICE_IP"

# Test from a pod
oc run test-client --image=registry.access.redhat.com/ubi8/ubi --command -- sleep 3600
oc wait --for=condition=Ready pod/test-client --timeout=60s

oc exec test-client -- ping -c 3 $SERVICE_IP
# Expected: 0% packet loss
```

### Test 4: External Connectivity

```bash
# Test pod can reach external network
oc exec test-pod-1 -- ping -c 3 8.8.8.8
# Expected: 0% packet loss

# Test DNS resolution
oc exec test-pod-1 -- nslookup google.com
# Expected: Successful DNS resolution

# Test external HTTP/HTTPS
oc exec test-pod-1 -- curl -I https://www.google.com
# Expected: HTTP 200 response
```

### Test 5: DNS Resolution

```bash
# Test internal DNS
oc exec test-pod-1 -- nslookup kubernetes.default.svc.cluster.local
# Expected: Resolves to 172.30.0.1 (service network)

# Test external DNS
oc exec test-pod-1 -- nslookup www.redhat.com
# Expected: Resolves to external IP

# Test service DNS
oc exec test-pod-1 -- nslookup test-app.default.svc.cluster.local
# Expected: Resolves to service cluster IP
```

### Test 6: Network Policy (Optional)

```bash
# Create a network policy to deny all ingress
cat <<EOF | oc apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector:
    matchLabels:
      app: isolated
  policyTypes:
  - Ingress
EOF

# Create isolated pod
oc run isolated-pod --image=registry.access.redhat.com/ubi8/ubi \
  --labels=app=isolated --command -- sleep 3600

oc wait --for=condition=Ready pod/isolated-pod --timeout=60s

# Test that policy blocks traffic
ISOLATED_IP=$(oc get pod isolated-pod -o jsonpath='{.status.podIP}')
oc exec test-pod-1 -- timeout 5 ping -c 1 $ISOLATED_IP || echo "Correctly blocked"

# Clean up
oc delete networkpolicy deny-all
oc delete pod isolated-pod
```

### Cleanup Test Resources

```bash
# Delete all test resources
oc delete pod test-pod-1 test-pod-2 test-pod-node1 test-pod-node2 test-client
oc delete deployment test-app
oc delete svc test-app
```

---

## IPsec Verification (If Enabled)

**Only run these if you enabled IPsec encryption.**

### Check IPsec Configuration

```bash
# Verify IPsec mode
oc get network.operator.openshift.io cluster \
  -o jsonpath='{.spec.defaultNetwork.ovnKubernetesConfig.ipsecConfig.mode}'
# Expected: Full (if enabled)
```

### Verify IPsec on Nodes

```bash
# Access a node
oc debug node/<node-name>
chroot /host

# Check IPsec status in OVS
ovs-appctl -t ovs-vswitchd fdb/show br-int | grep -i ipsec

# Check for IPsec tunnels
ip xfrm state
ip xfrm policy

# You should see XFRM states and policies for IPsec tunnels

exit
exit
```

### Test Encrypted Traffic

```bash
# Capture traffic on node to verify encryption
oc debug node/<node-name>
chroot /host

# Install tcpdump if not present
dnf install -y tcpdump

# Capture Geneve traffic (should be encrypted)
tcpdump -i any -nn port 6081 -c 10

# You should see ESP (Encapsulating Security Payload) packets
# indicating encrypted traffic

exit
exit
```

### Verify IPsec Certificate

```bash
# Check IPsec certificates
oc get secrets -n openshift-ovn-kubernetes | grep ipsec

# View certificate details
oc get secret ovn-ipsec-cert -n openshift-ovn-kubernetes -o yaml
```

---

## Performance Validation

### Test Network Throughput

```bash
# Create iperf3 server pod
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: iperf3-server
spec:
  containers:
  - name: iperf3
    image: networkstatic/iperf3
    command: ['iperf3', '-s']
    ports:
    - containerPort: 5201
EOF

# Create iperf3 client pod on different node
cat <<EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: iperf3-client
spec:
  nodeSelector:
    kubernetes.io/hostname: <different-node>
  containers:
  - name: iperf3
    image: networkstatic/iperf3
    command: ['sleep', '3600']
EOF

# Wait for pods
oc wait --for=condition=Ready pod/iperf3-server --timeout=60s
oc wait --for=condition=Ready pod/iperf3-client --timeout=60s

# Get server IP
SERVER_IP=$(oc get pod iperf3-server -o jsonpath='{.status.podIP}')

# Run throughput test
oc exec iperf3-client -- iperf3 -c $SERVER_IP -t 10

# Expected: Depends on your hardware
# - Without IPsec: ~10-40 Gbps (depending on hardware)
# - With IPsec: ~5-10% reduction

# Cleanup
oc delete pod iperf3-server iperf3-client
```

### Test Latency

```bash
# Test latency between pods on different nodes
oc run test-ping-client --image=registry.access.redhat.com/ubi8/ubi \
  --command -- sleep 3600

oc run test-ping-server --image=registry.access.redhat.com/ubi8/ubi \
  --command -- sleep 3600

oc wait --for=condition=Ready pod/test-ping-client --timeout=60s
oc wait --for=condition=Ready pod/test-ping-server --timeout=60s

SERVER_IP=$(oc get pod test-ping-server -o jsonpath='{.status.podIP}')

# Test latency with 100 packets
oc exec test-ping-client -- ping -c 100 -i 0.01 $SERVER_IP

# Expected: 
# - Without IPsec: <1ms on same node, 1-5ms cross-node
# - With IPsec: +0.5-2ms additional latency

# Cleanup
oc delete pod test-ping-client test-ping-server
```

---

## Troubleshooting Failed Verification

### Network Operator Degraded

**Symptom:** `oc get co network` shows `DEGRADED=True`

**Investigation:**
```bash
# Get degraded condition details
oc get co network -o jsonpath='{.status.conditions[?(@.type=="Degraded")].message}'

# Common causes:
# - VIP not in machine network range
# - Subnet overlap
# - Invalid configuration

# Check full operator config
oc get network.operator.openshift.io cluster -o yaml > network-config.yaml
less network-config.yaml
```

### OVN Pods CrashLooping

**Symptom:** OVN pods repeatedly restarting

**Investigation:**
```bash
# Check pod status
oc get pods -n openshift-ovn-kubernetes

# Check logs of failing pod
oc logs -n openshift-ovn-kubernetes <failing-pod> --previous

# Common issues:
# - MTU mismatch (OVN MTU > physical MTU)
# - Geneve port blocked
# - Subnet overlap causing routing issues
```

### Pods Cannot Reach External Network

**Symptom:** Pods can communicate internally but not externally

**Investigation:**
```bash
# Test from pod
oc exec <pod-name> -- ping -c 3 8.8.8.8

# Check masquerade subnet configuration
oc get network.operator.openshift.io cluster \
  -o jsonpath='{.spec.defaultNetwork.ovnKubernetesConfig.gatewayConfig.ipv4.internalMasqueradeSubnet}'

# Check node routing
oc debug node/<node-name>
chroot /host
ip route
iptables -t nat -L -n -v | grep -A 20 POSTROUTING
exit
exit
```

### MTU Issues

**Symptom:** Large packets fail, small packets work

**Investigation:**
```bash
# Test with different packet sizes
oc exec <pod-name> -- ping -c 3 -s 1400 8.8.8.8  # Small packets
oc exec <pod-name> -- ping -c 3 -s 8000 8.8.8.8  # Large packets

# If large packets fail, MTU misconfigured

# Check overlay MTU
oc debug node/<node-name>
chroot /host
ip link show genev_sys_6081 | grep mtu

# Overlay MTU must be <= physical MTU - 100 bytes
```

---

## Complete Verification Script

Save this as `verify-ovn.sh`:

```bash
#!/bin/bash

echo "=== OVN-Kubernetes Verification Script ==="
echo

echo "1. Checking Network Operator Status..."
oc get co network
echo

echo "2. Checking OVN Pods..."
oc get pods -n openshift-ovn-kubernetes
echo

echo "3. Verifying Network Type..."
NETTYPE=$(oc get network.config.openshift.io cluster -o jsonpath='{.spec.networkType}')
echo "Network Type: $NETTYPE"
if [ "$NETTYPE" != "OVNKubernetes" ]; then
  echo "ERROR: Expected OVNKubernetes, got $NETTYPE"
  exit 1
fi
echo

echo "4. Checking OVN Configuration..."
oc get network.operator.openshift.io cluster \
  -o jsonpath='{.spec.defaultNetwork.ovnKubernetesConfig}' | jq '.'
echo

echo "5. Testing Pod Creation..."
oc run verify-test-pod --image=registry.access.redhat.com/ubi8/ubi --command -- sleep 60
sleep 10
oc wait --for=condition=Ready pod/verify-test-pod --timeout=60s
echo "Pod created successfully"
echo

echo "6. Testing External Connectivity..."
oc exec verify-test-pod -- ping -c 3 8.8.8.8
echo

echo "7. Testing DNS..."
oc exec verify-test-pod -- nslookup kubernetes.default.svc.cluster.local
echo

echo "8. Cleanup..."
oc delete pod verify-test-pod
echo

echo "=== Verification Complete ==="
echo "Check output above for any errors"
```

**Run the script:**
```bash
chmod +x verify-ovn.sh
./verify-ovn.sh
```

---

## Changing Configuration Post-Install

### Overview

OVN-Kubernetes configuration can be changed after installation by patching the `network.operator.openshift.io` resource.

**Prerequisites:**
- `cluster-admin` privileges required
- OpenShift CLI (`oc`) installed and configured
- Maintenance window scheduled (allow 30-60 minutes)
- Current configuration documented for rollback

⏱️ **Important Timing:** Configuration changes can take **up to 30 minutes** to fully propagate across the cluster.

### Impact by Parameter Type

Different parameters have different impacts:

| Change Type | Impact | Requires Reboot? | Downtime? |
|-------------|--------|------------------|-----------|
| IPsec mode | None | No | No |
| Policy audit config | None | No | No |
| Internal subnets | OVN pod restart | No | Brief (~30s) |
| Gateway config | OVN pod restart | No | Brief (~30s) |
| MTU | Node-level change | Yes | Per node |
| Geneve port | Node-level change | Yes | Per node |

---

### Changing Internal Subnets

**Scenario:** Need to change OVN internal subnets after installation.

**Steps:**

1. **View current configuration:**
```bash
oc get network.operator.openshift.io cluster \
  -o jsonpath='{.spec.defaultNetwork.ovnKubernetesConfig}' | jq
```

2. **Patch the configuration:**
```bash
oc patch networks.operator.openshift.io cluster --type=merge -p '
{
  "spec": {
    "defaultNetwork": {
      "ovnKubernetesConfig": {
        "ipv4": {
          "internalJoinSubnet": "10.245.0.0/16"
        },
        "gatewayConfig": {
          "ipv4": {
            "internalMasqueradeSubnet": "169.254.0.0/17",
            "internalTransitSwitchSubnet": "10.246.0.0/16"
          }
        }
      }
    }
  }
}'
```

3. **Monitor OVN pod rollout:**
```bash
# Watch OVN pods restart
oc get pods -n openshift-ovn-kubernetes -w

# All pods should restart and return to Running
# Expected downtime: ~30 seconds
```

⏱️ **Important:** Configuration changes can take **up to 30 minutes** to fully propagate across the cluster. Monitor the network operator status during this time.

4. **Verify configuration applied:**
```bash
# Check updated config
oc get network.operator.openshift.io cluster \
  -o jsonpath='{.spec.defaultNetwork.ovnKubernetesConfig}' | jq

# Verify on nodes - should show new IP from internalJoinSubnet
oc debug node/<node-name>
chroot /host
ip addr show ovn-k8s-mp0
# Expected: IP from new internalJoinSubnet (e.g., 10.245.0.x)
exit
exit
```

5. **Validate networking:**
```bash
# Run connectivity test
oc run test-pod --image=registry.access.redhat.com/ubi8/ubi --command -- sleep 300
oc wait --for=condition=Ready pod/test-pod --timeout=60s
oc exec test-pod -- ping -c 3 8.8.8.8
oc delete pod test-pod
```

---

### Changing MTU

**Scenario:** Need to enable jumbo frames or change MTU.

**⚠️ Warning:** Requires node reboot. Plan for maintenance window.

**Steps:**

1. **Patch MTU configuration:**
```bash
oc patch networks.operator.openshift.io cluster --type=merge -p '
{
  "spec": {
    "defaultNetwork": {
      "ovnKubernetesConfig": {
        "mtu": 9000
      }
    }
  }
}'
```

2. **Reboot nodes one at a time:**
```bash
# For each node:
NODE="<node-name>"

# Drain node
oc adm drain $NODE --ignore-daemonsets --delete-emptydir-data --force

# Reboot node (via BMC, SSH, or console)
oc debug node/$NODE -- chroot /host systemctl reboot

# Wait for node to come back (5-10 minutes)
watch oc get nodes

# Verify MTU on node
oc debug node/$NODE
chroot /host
ip link show genev_sys_6081 | grep mtu
# Expected: mtu 9000
exit
exit

# Uncordon node
oc adm uncordon $NODE

# Verify pods schedule back
oc get pods -o wide | grep $NODE
```

3. **Repeat for all nodes**

4. **Verify cluster-wide:**
```bash
# Check all nodes
for node in $(oc get nodes -o name); do
  echo "=== $node ==="
  oc debug $node -- chroot /host ip link show genev_sys_6081 2>/dev/null | grep mtu
done
```

---

### Changing IPsec Mode

**Scenario:** Enable or disable IPsec encryption.

**Steps:**

1. **Enable IPsec:**
```bash
oc patch networks.operator.openshift.io cluster --type=merge \
  -p '{"spec":{"defaultNetwork":{"ovnKubernetesConfig":{"ipsecConfig":{"mode":"Full"}}}}}'
```

2. **Monitor rollout:**
```bash
# Watch OVN pods update
oc get pods -n openshift-ovn-kubernetes -w

# Check IPsec configuration applied
oc get network.operator.openshift.io cluster \
  -o jsonpath='{.spec.defaultNetwork.ovnKubernetesConfig.ipsecConfig.mode}'
# Expected: Full
```

3. **Verify IPsec active:**
```bash
# Check on node
oc debug node/<node-name>
chroot /host
ovs-appctl -t ovs-vswitchd fdb/show br-int | grep -i ipsec
ip xfrm state
# Should show IPsec tunnels
exit
exit
```

4. **Disable IPsec (if needed):**
```bash
oc patch networks.operator.openshift.io cluster --type=merge \
  -p '{"spec":{"defaultNetwork":{"ovnKubernetesConfig":{"ipsecConfig":{"mode":"Disabled"}}}}}'
```

---

### Changing Geneve Port

**Scenario:** Change Geneve encapsulation port.

**⚠️ Warning:** Requires node reboot and firewall rule updates.

**Steps:**

1. **Update firewall rules on all nodes first:**
```bash
# On each node, add new port before changing config
oc debug node/<node-name>
chroot /host
firewall-cmd --permanent --add-port=6082/udp
firewall-cmd --reload
exit
exit
```

2. **Patch configuration:**
```bash
oc patch networks.operator.openshift.io cluster --type=merge -p '
{
  "spec": {
    "defaultNetwork": {
      "ovnKubernetesConfig": {
        "genevePort": 6082
      }
    }
  }
}'
```

3. **Reboot nodes (same process as MTU change above)**

4. **Verify new port in use:**
```bash
oc debug node/<node-name>
chroot /host
ss -ulnp | grep 6082
# Should show ovn process listening on UDP 6082
exit
exit
```

5. **Remove old firewall rule (after all nodes updated):**
```bash
oc debug node/<node-name>
chroot /host
firewall-cmd --permanent --remove-port=6081/udp
firewall-cmd --reload
exit
exit
```

---

### Rollback Configuration Changes

**If changes cause issues:**

1. **Check previous configuration:**
```bash
# View configuration history via etcd backup or documentation

# Or describe the network operator
oc describe network.operator.openshift.io cluster
```

2. **Rollback by patching with previous values:**
```bash
# Example: Rollback to default subnets
oc patch networks.operator.openshift.io cluster --type=merge -p '
{
  "spec": {
    "defaultNetwork": {
      "ovnKubernetesConfig": {
        "ipv4": {
          "internalJoinSubnet": "100.64.0.0/16"
        },
        "gatewayConfig": {
          "ipv4": {
            "internalMasqueradeSubnet": "169.254.169.0/29",
            "internalTransitSwitchSubnet": "100.88.0.0/16"
          }
        }
      }
    }
  }
}'
```

3. **Monitor rollback:**
```bash
oc get pods -n openshift-ovn-kubernetes -w
oc get co network
```

---

### Best Practices for Configuration Changes

1. **Test in non-production first**
   - Always test changes in dev/test environment
   - Verify expected behavior before production

2. **Plan maintenance windows**
   - Brief disruption for subnet changes
   - Node-by-node for MTU/port changes
   - No disruption for IPsec/audit changes

3. **Document current state**
   - Save current config before changes
   - Keep change log for rollback reference

4. **Monitor during changes**
   - Watch network operator status
   - Check OVN pod health
   - Verify connectivity after changes

5. **Validate thoroughly**
   - Run functional tests
   - Check all nodes updated
   - Verify no degraded operators

---

**For troubleshooting guidance, see [README.md](./README.md#troubleshooting)**

**Last Updated:** 2026-02-02


# Accessing Newly Provisioned Worker Nodes

## Quick Access Methods

### Method 1: Using `oc debug node` (Recommended)

This is the OpenShift-native way to access nodes:

```bash
# List all nodes to find your worker
oc get nodes

# Access the worker node
oc debug node/<worker-node-name>

# Once in the debug pod, chroot to access the actual node filesystem
chroot /host

# Now you're in the actual CoreOS system
# You can run commands like:
systemctl status kubelet
journalctl -u kubelet -f
crictl ps
```

**Example:**
```bash
$ oc get nodes
NAME       STATUS   ROLES    AGE   VERSION
master-0   Ready    master   5d    v1.28.2
master-1   Ready    master   5d    v1.28.2
master-2   Ready    master   5d    v1.28.2
worker-0   Ready    worker   1h    v1.28.2

$ oc debug node/worker-0
Starting pod/worker-0-debug ...
To use host binaries, run `chroot /host`
Pod IP: 10.0.0.50
If you don't see a command prompt, try pressing enter.

sh-4.4# chroot /host
sh-5.1# hostname
worker-0
sh-5.1# 
```

---

### Method 2: Direct SSH Access

OpenShift nodes use the `core` user (CoreOS default) and SSH key authentication.

#### Find the SSH Key

The SSH key used during installation should be available:

```bash
# If you have the install directory
ls ~/.ssh/id_rsa*

# Or check what key was used in install-config.yaml
# The public key from install-config becomes authorized on all nodes
```

#### Get the Node IP Address

```bash
# Get internal IP
oc get node <worker-name> -o wide

# Or get more details
oc get node <worker-name> -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}'
echo

# Example output: 10.0.0.50
```

#### SSH to the Node

```bash
# Using the core user (default for CoreOS)
ssh core@<node-ip>

# Or with specific key
ssh -i ~/.ssh/id_rsa core@<node-ip>

# Example:
ssh core@10.0.0.50
```

**If SSH is not working:**
```bash
# Check if SSH service is running (via oc debug)
oc debug node/<worker> -- chroot /host systemctl status sshd

# Check SSH port (should be 22)
oc debug node/<worker> -- chroot /host ss -tlnp | grep :22
```

---

### Method 3: Via BMC Console (If Node Not Joining Cluster)

If the node hasn't joined the cluster yet, use BMC virtual console:

```bash
# Get BMC address for the worker
oc get baremetalhost <worker-bmh-name> -n openshift-machine-api -o jsonpath='{.spec.bmc.address}'

# Example output: redfish-virtualmedia+https://10.0.0.100/redfish/v1/Systems/1
```

Then access BMC web interface:
1. Browse to BMC IP: `https://10.0.0.100`
2. Login with BMC credentials
3. Open virtual console (KVM/SOL)
4. Login as `core` user

**Note:** By default, CoreOS nodes provisioned by OpenShift may not have password authentication enabled. You might only see boot messages.

---

## What to Check After Accessing Node

### 1. Verify Node Status

```bash
# Check hostname
hostname

# Check CoreOS version
rpm-ostree status

# Check system status
systemctl status
```

### 2. Check Kubelet

```bash
# Kubelet status
systemctl status kubelet

# Kubelet logs (recent)
journalctl -u kubelet -n 50

# Follow kubelet logs live
journalctl -u kubelet -f
```

### 3. Check Container Runtime

```bash
# List running containers
crictl ps

# List all containers (including stopped)
crictl ps -a

# Check specific pod
crictl pods

# Get container logs
crictl logs <container-id>
```

### 4. Check Network Configuration

```bash
# Network interfaces
ip addr show

# Routes
ip route show

# DNS
cat /etc/resolv.conf

# Test connectivity to API server
API_SERVER=$(grep server /etc/kubernetes/kubelet.conf | awk '{print $2}')
curl -k $API_SERVER/healthz
```

### 5. Check Machine Config

```bash
# Current machine config
cat /etc/machine-config-daemon/currentconfig

# Machine config daemon logs
journalctl -u machine-config-daemon -n 50
```

### 6. Check Certificates

```bash
# Kubelet certificates
ls -la /var/lib/kubelet/pki/

# Check certificate expiration
openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem -noout -dates 2>/dev/null || echo "No kubelet cert yet"
```

---

## Common Scenarios and What to Check

### Scenario 1: Node Just Provisioned, Not Yet in Cluster

**Where you are:**
- BareMetalHost shows `provisioned`
- Node not yet showing in `oc get nodes`

**What to check:**
```bash
# Access via oc debug or SSH
oc debug node/<node-ip-if-known>

# Or find node by trying to SSH to expected IP
ssh core@<expected-ip>

# Check kubelet is starting
systemctl status kubelet
journalctl -u kubelet -f

# Look for CSR creation errors
journalctl -u kubelet | grep -i "csr\|certificate"

# Check if kubelet can reach API server
curl -k https://<api-vip>:6443/healthz
```

### Scenario 2: Node Shows in Cluster but NotReady

**Where you are:**
- Node appears in `oc get nodes`
- Status shows `NotReady`

**What to check:**
```bash
# Access node
oc debug node/<worker-name>
chroot /host

# Check CNI/networking
ls -la /etc/cni/net.d/
ls -la /opt/cni/bin/

# Check for pod network issues
crictl pods
journalctl -u kubelet | grep -i "network\|cni"

# Check node conditions
kubectl get node <worker-name> -o yaml | grep -A 20 conditions
```

### Scenario 3: Node Ready but Workloads Not Scheduling

**Where you are:**
- Node shows `Ready`
- Pods not being scheduled to this node

**What to check:**
```bash
# From your workstation (not on node)
# Check node labels
oc get node <worker-name> --show-labels

# Check taints
oc describe node <worker-name> | grep -i taint

# Check allocatable resources
oc describe node <worker-name> | grep -A 10 Allocatable

# Remove taints if any
oc adm taint node <worker-name> node.kubernetes.io/not-ready:NoSchedule-
```

---

## Troubleshooting SSH Access

### Issue: "Permission denied (publickey)"

```bash
# 1. Verify which key was used during installation
# Check your install-config.yaml or installation notes

# 2. Try with verbose SSH to see which keys are being tried
ssh -v core@<node-ip>

# 3. Specify the correct key explicitly
ssh -i /path/to/correct/key core@<node-ip>

# 4. Check authorized keys on the node (via oc debug)
oc debug node/<worker> -- chroot /host cat /home/core/.ssh/authorized_keys
```

### Issue: "Connection refused"

```bash
# 1. Verify node IP is correct
oc get node <worker> -o jsonpath='{.status.addresses[*]}'
echo

# 2. Check if SSH daemon is running (via oc debug)
oc debug node/<worker> -- chroot /host systemctl status sshd

# 3. Check firewall
oc debug node/<worker> -- chroot /host firewall-cmd --list-all

# 4. Try from a master node (same network)
oc debug node/master-0 -- chroot /host ssh -o StrictHostKeyChecking=no core@<worker-ip>
```

### Issue: "No route to host"

```bash
# 1. Verify network connectivity
ping <node-ip>

# 2. Check if node is on expected network
oc get node <worker> -o yaml | grep -A 5 addresses

# 3. Try from master node (should be on same network)
oc debug node/master-0 -- chroot /host ping -c 3 <worker-ip>
```

---

## Advanced: Access Node Before It Joins Cluster

If node has been provisioned but hasn't joined the cluster yet:

### Option 1: Find IP from DHCP/Provisioning Network

```bash
# If you have access to provisioning network DHCP server
# Check DHCP leases for new assignment

# Or check from a master node
oc debug node/master-0
chroot /host

# Try to ping/scan the provisioning network
# (If you know the network range)
nmap -sn 192.168.111.0/24  # Example provisioning network

# Or check ARP table
ip neigh show
```

### Option 2: Use Serial Console via BMC

```bash
# Get BMC details
oc get baremetalhost <worker-bmh> -n openshift-machine-api -o yaml | grep -A 5 bmc:

# Access BMC web interface and open serial console
# Login as 'core' user (may need to wait for boot to complete)
```

### Option 3: Check Metal3/Ironic Logs for IP

```bash
# Check Metal3 logs for DHCP assignment
oc logs -n openshift-machine-api deployment/metal3 --tail=100 | grep -i <worker-bmh-name>

# Check for IP assignments
oc logs -n openshift-machine-api deployment/metal3 --tail=200 | grep -i "dhcp\|address"
```

---

## Quick Reference Commands

```bash
# Access node (OpenShift native way)
oc debug node/<worker-name>
chroot /host

# Access node (SSH)
ssh core@<node-ip>

# Get node IP
oc get node <worker-name> -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}'

# Check kubelet status (from within node)
systemctl status kubelet
journalctl -u kubelet -f

# Check containers (from within node)
crictl ps
crictl pods

# Check node from outside
oc describe node <worker-name>
oc get node <worker-name> -o yaml

# Debug network from node
ping 8.8.8.8
curl -k https://<api-vip>:6443/healthz
```

---

## After Accessing the Node

### Verify TLS/Certificate Issue Was Resolved

Since you had a TLS certificate verification issue, verify it's resolved:

```bash
# On the worker node, check that ignition succeeded
journalctl -u ignition-firstboot-complete --no-pager

# Should show: "Ignition: ignition complete."

# Check that kubelet has valid certificates
ls -la /var/lib/kubelet/pki/
openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem -noout -text

# Check kubelet successfully authenticated
journalctl -u kubelet | grep -i "authenticated\|certificate"

# Should NOT see errors like:
# - "x509: certificate has expired"
# - "TLS handshake error"
# - "certificate verification failed"
```

---

## Collecting Diagnostics from Node

If you need to collect information for troubleshooting:

```bash
# On the node, collect key logs
journalctl -u kubelet > /tmp/kubelet.log
journalctl -u ignition-firstboot-complete > /tmp/ignition.log
journalctl -b > /tmp/boot.log

# Copy certificates
mkdir /tmp/certs
cp -r /var/lib/kubelet/pki/* /tmp/certs/ 2>/dev/null

# Network info
ip addr show > /tmp/network-interfaces.txt
ip route show >> /tmp/network-interfaces.txt
cat /etc/resolv.conf >> /tmp/network-interfaces.txt

# Container info
crictl ps -a > /tmp/containers.txt
crictl pods > /tmp/pods.txt

# Copy files out (from your workstation, not on the node)
# If using oc debug:
oc debug node/<worker-name> -- tar czf - /host/tmp/*.log /host/tmp/*.txt | tar xzf - -C /tmp/worker-diagnostics/

# If using SSH:
scp core@<worker-ip>:/tmp/*.{log,txt} /tmp/worker-diagnostics/
```

---

## Security Notes

### SSH Key Management

- CoreOS nodes use SSH key authentication only (no password by default)
- The SSH public key from `install-config.yaml` is deployed to all nodes
- Key is added to `/home/core/.ssh/authorized_keys`

### Default User

- Default user: `core` (not `root`)
- The `core` user has passwordless sudo access
- Switch to root: `sudo -i` (after SSH as core)

### Firewall

- CoreOS comes with firewall enabled
- SSH (port 22) is allowed by default
- Custom ports may be blocked

---

## Related Documentation

- **Main troubleshooting guide**: [README.md](README.md)
- **Quick fixes**: [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
- **Your specific issue**: [YOUR-ISSUE.md](YOUR-ISSUE.md)
- **CSR management**: [../csr-management/README.md](../csr-management/README.md)
- **Network issues**: [../coreos-networking-issues/README.md](../coreos-networking-issues/README.md)

---

## Summary: Getting Started

**Easiest method (if node is in cluster):**
```bash
# 1. Find your worker node name
oc get nodes

# 2. Access it
oc debug node/<worker-name>

# 3. Access actual filesystem
chroot /host

# 4. You're in!
```

**SSH method (if you prefer traditional SSH):**
```bash
# 1. Get node IP
NODE_IP=$(oc get node <worker-name> -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')

# 2. SSH to it
ssh core@$NODE_IP

# 3. Become root if needed
sudo -i
```

**Both methods work equally well - choose based on your preference!**


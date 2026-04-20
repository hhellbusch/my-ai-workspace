# Accessing BareMetalHost Before It Becomes a Node

## The Problem

You have a BareMetalHost defined, it may have booted or be provisioning, but it's not yet joined the cluster as a node. So `oc debug node` won't work because there's no node object yet.

---

## Quick Access Methods

### Method 1: BMC Virtual Console (Most Reliable)

This is the most direct way to access the machine:

#### Step 1: Get BMC Details

```bash
# Replace with your BareMetalHost name
BMH_NAME="worker-0"

# Get BMC address
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.spec.bmc.address}'
echo

# Example output: redfish-virtualmedia+https://10.0.0.100/redfish/v1/Systems/1
# The IP is: 10.0.0.100
```

#### Step 2: Get BMC Credentials

```bash
# Get the secret name
SECRET_NAME=$(oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.spec.bmc.credentialsName}')
echo "Secret: $SECRET_NAME"

# Get username
oc get secret $SECRET_NAME -n openshift-machine-api -o jsonpath='{.data.username}' | base64 -d
echo

# Get password
oc get secret $SECRET_NAME -n openshift-machine-api -o jsonpath='{.data.password}' | base64 -d
echo
```

#### Step 3: Access BMC Console

```bash
# Open browser to BMC IP (use https)
# For example: https://10.0.0.100

# Login with credentials from step 2

# Then:
# - Dell iDRAC: Virtual Console → Launch Virtual Console
# - HP iLO: Remote Console → Launch Console
# - Supermicro IPMI: Remote Control → iKVM/HTML5
# - Redfish standard: Look for "Virtual Media" or "Console"
```

#### Step 4: Login to CoreOS

Once you have console access:
- **Username:** `core`
- **Password:** By default, there is NO password (CoreOS uses SSH keys only)

**To get a login prompt:**
```
# At the console, press Enter a few times
# You may see CoreOS boot messages but no login prompt

# CoreOS by default only allows SSH key authentication
# You won't be able to login via console without setting a password first
```

**To set a password for emergency access (from BMC console during boot):**

You'll need to boot into emergency mode or single-user mode. This is complex - see "Emergency Console Access" section below.

---

### Method 2: Find IP and SSH Directly

If the BareMetalHost has been provisioned and booted successfully, it has an IP. Find it and SSH to it.

#### Step 1: Find the IP Address

**Option A: Check Metal3 Logs**

```bash
# Get Metal3/Ironic pod name
METAL3_POD=$(oc get pods -n openshift-machine-api -l baremetal.openshift.io/cluster-baremetal-operator=metal3-state -o name | head -1)

# Search logs for your BareMetalHost and IP assignment
oc logs -n openshift-machine-api $METAL3_POD --tail=500 | grep -i "$BMH_NAME"

# Look for lines showing DHCP or IP assignment
oc logs -n openshift-machine-api $METAL3_POD --tail=500 | grep -E "$BMH_NAME.*[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"
```

**Option B: Check BareMetalHost Status (May Have IP)**

```bash
# Sometimes the IP is in the status
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o yaml | grep -i "address\|ip"

# Or check the full status
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status}' | jq .
```

**Option C: Scan the Network (If You Know the Subnet)**

```bash
# From a master node, scan the expected subnet
oc debug node/master-0 -- chroot /host nmap -sn 192.168.111.0/24

# Or check ARP table for new entries
oc debug node/master-0 -- chroot /host ip neigh show

# Look for recent entries or MACs matching your hardware
```

**Option D: Check DHCP Server Logs (If Accessible)**

```bash
# If you have access to the DHCP server
# Find recent leases for your MAC address

# Get MAC address from BareMetalHost
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.spec.bootMACAddress}'
echo
```

#### Step 2: SSH to the IP

```bash
# Once you have the IP
WORKER_IP="192.168.111.50"  # Replace with actual IP

# SSH as core user
ssh core@$WORKER_IP

# If that doesn't work, try with your install SSH key explicitly
ssh -i ~/.ssh/id_rsa core@$WORKER_IP

# If still not working, disable strict host key checking
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null core@$WORKER_IP
```

---

### Method 3: Serial Console via BMC (Text Only)

Some BMCs provide serial console access which can be lighter weight than virtual console:

```bash
# Using ipmitool (if you have network access to BMC)
BMC_IP="10.0.0.100"
BMC_USER="admin"
BMC_PASS="password"

# Activate serial over LAN
ipmitool -I lanplus -H $BMC_IP -U $BMC_USER -P $BMC_PASS sol activate

# To exit: Press ~. (tilde then period)
```

Or through Redfish API (more complex, usually use web UI instead).

---

## Detailed: Checking BareMetalHost Status

### Get Complete Status

```bash
BMH_NAME="worker-0"

# Basic status
oc get baremetalhost $BMH_NAME -n openshift-machine-api

# Detailed info
oc describe baremetalhost $BMH_NAME -n openshift-machine-api

# Full YAML with all status fields
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o yaml
```

### Key Status Fields to Check

```bash
# Current state (provisioning, provisioned, available, etc.)
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.provisioning.state}'
echo

# Error messages (if any)
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.errorMessage}'
echo

# Last error
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.errorType}'
echo

# Hardware details (if inspection completed)
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.hardwareDetails}' | jq .

# Operational status
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.operationalStatus}'
echo

# Power state
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.poweredOn}'
echo
```

### Check Recent Events

```bash
# Get events for this BareMetalHost
oc get events -n openshift-machine-api --field-selector involvedObject.name=$BMH_NAME --sort-by='.lastTimestamp'

# Or more readable
oc describe baremetalhost $BMH_NAME -n openshift-machine-api | grep -A 20 "Events:"
```

---

## What State Is Your BareMetalHost In?

Check the current state:

```bash
STATE=$(oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.provisioning.state}')
echo "Current state: $STATE"
```

### State: `inspecting`

**What's happening:**
- Machine is booting from inspection image
- Hardware details being collected
- Usually gets IP from DHCP on provisioning network

**How to access:**
- BMC console (best option)
- Serial console
- SSH to inspection image IP (if you can find it)

**What you'll see:**
- IPA (Ironic Python Agent) running
- May see hardware inventory collection
- Should complete and move to `available` state

### State: `available`

**What's happening:**
- Inspection complete
- Machine is powered off or idle
- Ready to be provisioned

**How to access:**
- Machine may be powered off
- Use BMC to power on and access console
- Once powered on, may boot to inspection image again

### State: `provisioning`

**What's happening:**
- Machine is being written with CoreOS image
- Ignition configuration being applied
- This is where TLS errors would occur

**How to access:**
- BMC console (watch the provisioning process)
- Serial console
- SSH won't work yet (machine being written)

**What to watch for:**
- Boot messages
- Ignition fetch attempt to `https://<api-vip>:22623/config/worker`
- TLS errors would appear here

### State: `provisioned`

**What's happening:**
- CoreOS image written successfully
- Machine has booted with ignition config
- Kubelet trying to join cluster
- NOT YET a node in `oc get nodes`

**How to access:**
- BMC console (should see CoreOS boot messages)
- SSH to machine's IP (if you can find it)
- Serial console

**What to check:**
```bash
# Via BMC console or SSH:
systemctl status kubelet
journalctl -u kubelet -f

# Look for:
# - Kubelet trying to connect to API server
# - CSR creation
# - Certificate issues
```

### State: `error` or `registrationError`

**What's happening:**
- Something went wrong
- Check error messages

**How to access:**
- BMC console to see what's on screen
- Check BareMetalHost error message:
  ```bash
  oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.errorMessage}'
  ```

---

## Emergency: Console Access Without SSH Keys

If you need console access and CoreOS doesn't have password auth enabled:

### Option 1: Boot to Emergency Mode

From BMC console:

1. **Interrupt boot** (press key during GRUB menu)
2. **Edit boot entry** (press 'e' on the CoreOS entry)
3. **Add to kernel command line:**
   ```
   systemd.unit=emergency.target
   ```
4. **Boot** (Ctrl+X or F10)
5. **You'll get a root shell** (may need root password if set)

### Option 2: Add Password via MachineConfig

Create a MachineConfig that sets a password for the `core` user:

```bash
# Generate password hash
PASSWORD="your-password-here"
PASS_HASH=$(python3 -c "import crypt; print(crypt.crypt('${PASSWORD}', crypt.mksalt(crypt.METHOD_SHA512)))")

# Create MachineConfig
cat <<EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 99-worker-console-password
spec:
  config:
    ignition:
      version: 3.2.0
    passwd:
      users:
      - name: core
        passwordHash: "$PASS_HASH"
EOF

# Wait for MachineConfigPool to update
oc get machineconfigpool worker -w

# Then power cycle your BareMetalHost
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'
sleep 10
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'
```

**Note:** This only works if the machine successfully provisions. If it's failing during ignition fetch (TLS error), it won't get this MachineConfig.

---

## Debugging During Provisioning

### Watch Provisioning in Real-Time

**Terminal 1: Watch BareMetalHost Status**
```bash
watch -n 2 'oc get baremetalhost -n openshift-machine-api'
```

**Terminal 2: Watch Metal3 Logs**
```bash
oc logs -n openshift-machine-api deployment/metal3 -f
```

**Terminal 3: BMC Console**
- Open BMC virtual console in browser
- Watch the machine boot and provision

### Look for TLS Error During Provisioning

From BMC console, during boot you should see:

```
# Good output (no TLS error):
[  OK  ] Reached target Multi-User System.
[  OK  ] Reached target Ignition Complete.

# Bad output (TLS error):
Ignition: failed to fetch config: Get "https://10.0.0.1:22623/config/worker": x509: certificate has expired
```

---

## Finding the Machine's IP Address

### Best Method: Check Metal3/Ironic Logs

```bash
BMH_NAME="worker-0"

# Get Metal3 pod
METAL3_POD=$(oc get pods -n openshift-machine-api -l baremetal.openshift.io/cluster-baremetal-operator=metal3-state -o name | head -1)

# Search for IP assignment
oc logs -n openshift-machine-api $METAL3_POD --tail=1000 | grep -i "$BMH_NAME" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'

# Or look for DHCP messages
oc logs -n openshift-machine-api $METAL3_POD --tail=1000 | grep -i "dhcp\|lease" | grep -i "$BMH_NAME"
```

### Alternative: Check from Master Node

```bash
# Access master node
oc debug node/master-0
chroot /host

# Check ARP table for new MAC addresses
ip neigh show

# Get BareMetalHost MAC address to correlate
# (from another terminal)
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.spec.bootMACAddress}'

# Or scan the provisioning network
nmap -sn 192.168.111.0/24  # Replace with your provisioning network CIDR
```

---

## Quick Commands Reference

```bash
# BareMetalHost name
BMH_NAME="worker-0"

# Get current state
oc get baremetalhost $BMH_NAME -n openshift-machine-api

# Get BMC address
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.spec.bmc.address}'

# Get BMC credentials
SECRET_NAME=$(oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.spec.bmc.credentialsName}')
oc get secret $SECRET_NAME -n openshift-machine-api -o jsonpath='{.data.username}' | base64 -d; echo
oc get secret $SECRET_NAME -n openshift-machine-api -o jsonpath='{.data.password}' | base64 -d; echo

# Get error messages
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.errorMessage}'

# Watch Metal3 logs
oc logs -n openshift-machine-api deployment/metal3 -f | grep -i "$BMH_NAME"

# Get events
oc get events -n openshift-machine-api --field-selector involvedObject.name=$BMH_NAME --sort-by='.lastTimestamp'

# Power cycle
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'
sleep 10
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'
```

---

## Recommended Approach for Your Situation

Given that you have a TLS certificate verification error:

### Step 1: Fix the TLS Issue First
Before trying to access the machine, fix the certificate problem:
```bash
# Most likely: certificate expired
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -dates

# If expired, regenerate:
oc delete secret machine-config-server-tls -n openshift-machine-config-operator
oc delete pods -n openshift-machine-config-operator -l k8s-app=machine-config-server
```

### Step 2: Access BMC Console
```bash
# Get BMC details
BMH_NAME="worker-0"
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.spec.bmc.address}'

# Get credentials
SECRET_NAME=$(oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.spec.bmc.credentialsName}')
oc get secret $SECRET_NAME -n openshift-machine-api -o jsonpath='{.data.username}' | base64 -d; echo
oc get secret $SECRET_NAME -n openshift-machine-api -o jsonpath='{.data.password}' | base64 -d; echo

# Open BMC in browser and watch console
```

### Step 3: Retry Provisioning
```bash
# Power cycle to retry with fixed certificate
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'
sleep 10
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'

# Watch in BMC console for TLS error (should be gone now)
```

### Step 4: Once Provisioned, SSH or Wait for Node
```bash
# After successful provisioning, either:

# Option A: SSH if you found the IP
ssh core@<ip-address>

# Option B: Wait for it to become a node, then use oc debug
watch oc get nodes  # Wait for worker to appear
oc debug node/<worker-name>
```

---

## Summary

**Before the machine becomes a node, you have these options:**

1. **BMC Virtual Console** ⭐ (Most reliable)
   - Always works regardless of network/provisioning state
   - Can see boot process and errors in real-time
   - Access BMC web UI with credentials from BareMetalHost secret

2. **Find IP and SSH**
   - Check Metal3 logs for IP assignment
   - SSH as `core` user once machine has booted
   - Requires machine to be in `provisioned` state

3. **Serial Console via BMC**
   - Text-only alternative to virtual console
   - Lighter weight, but less user-friendly

**For your TLS troubleshooting:**
- **Fix the certificate first** (see [YOUR-ISSUE.md](YOUR-ISSUE.md))
- **Use BMC console** to watch provisioning and see if TLS error is gone
- **Once provisioned**, machine will join as node and you can use `oc debug`

The **BMC console is your best bet** for real-time troubleshooting before the machine becomes a node!


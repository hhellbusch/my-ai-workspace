# SSH Connection Refused to BareMetalHost

## What "Connection Refused" Means

**SSH "Connection Refused" indicates:**
- The machine is reachable on the network (not a timeout)
- But port 22 is not open/listening
- SSH service is either not running or not started yet

This is **very common** when the machine failed during provisioning due to the TLS certificate error!

---

## Most Likely Cause: Ignition Failed (TLS Error)

If ignition fetch fails due to the TLS certificate error, the machine boots but **never completes setup**, so SSH is never started.

### Quick Check: Is This Your Issue?

```bash
BMH_NAME="worker-0"  # Replace with your BareMetalHost name

# Check BareMetalHost state
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.provisioning.state}'
echo

# Check for errors
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.errorMessage}'
echo

# Expected if TLS error during provisioning:
# State might be "provisioned" but machine is in a failed state
# or stuck rebooting
```

**The smoking gun:** If the TLS error prevented ignition from completing, SSH never gets configured.

---

## Diagnosis Steps

### Step 1: Verify the Machine is Actually Booted

```bash
BMH_NAME="worker-0"

# Check if machine is powered on
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.poweredOn}'
echo
# Should return: true

# Check operational status
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.operationalStatus}'
echo
# Might show: "OK" or "error"
```

### Step 2: Verify You Have the Correct IP

```bash
# Double-check the IP you're trying to SSH to
# Get it from Metal3 logs:
METAL3_POD=$(oc get pods -n openshift-machine-api -l baremetal.openshift.io/cluster-baremetal-operator=metal3-state -o name | head -1)

echo "Searching Metal3 logs for IP assignment..."
oc logs -n openshift-machine-api $METAL3_POD --tail=1000 | grep -i "$BMH_NAME" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | tail -5

# Try each IP found
```

### Step 3: Test Basic Connectivity

```bash
WORKER_IP="192.168.111.50"  # Replace with your IP

# Ping test
ping -c 3 $WORKER_IP

# Results:
# ✅ Ping works → Machine is on network
# ❌ Ping fails → Wrong IP or network issue
```

### Step 4: Check What Ports Are Open

```bash
# Check if ANY ports are open
nmap -Pn $WORKER_IP

# Or just check SSH specifically
nc -zv $WORKER_IP 22

# Results:
# "Connection refused" → Machine is up but SSH not running
# "Connection timed out" → Machine not responding or firewall blocking
# "Connected" → SSH is running (weird if you got refused earlier)
```

### Step 5: Check BMC Console (THE ANSWER!)

This will show you EXACTLY what's happening:

```bash
# Get BMC details
SECRET_NAME=$(oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.spec.bmc.credentialsName}')

echo "BMC Address:"
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.spec.bmc.address}'
echo

echo "BMC Username:"
oc get secret $SECRET_NAME -n openshift-machine-api -o jsonpath='{.data.username}' | base64 -d
echo

echo "BMC Password:"
oc get secret $SECRET_NAME -n openshift-machine-api -o jsonpath='{.data.password}' | base64 -d
echo

echo ""
echo "Open BMC web interface and check virtual console to see what's actually happening on the machine"
```

---

## Common Scenarios

### Scenario 1: Ignition Failed Due to TLS Error ⭐ (Most Likely)

**What's happening:**
1. Machine boots from provisioned image
2. Ignition tries to fetch config from `https://<api-vip>:22623/config/worker`
3. **TLS certificate verification fails**
4. Ignition fails, machine doesn't complete setup
5. SSH never gets configured/started
6. Machine may reboot repeatedly trying again

**What you'll see:**
- `ping` works (machine is on network)
- `ssh` gives "Connection refused"
- BMC console shows ignition errors

**Fix:**
```bash
# 1. Fix the TLS certificate issue FIRST
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')

# Check if expired
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -dates

# If expired, fix it
oc delete secret machine-config-server-tls -n openshift-machine-config-operator
oc delete pods -n openshift-machine-config-operator -l k8s-app=machine-config-server

# Wait 30 seconds
sleep 30

# Verify new cert
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -dates

# 2. Power cycle the BareMetalHost
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'
sleep 10
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'

# 3. Watch BMC console - should boot successfully now
# 4. Wait a few minutes for SSH to start
# 5. Try SSH again
```

---

### Scenario 2: Machine Still Provisioning

**What's happening:**
- Machine is in the process of being written with CoreOS image
- Image write takes 5-15 minutes
- SSH won't be available until write completes and machine boots

**Check:**
```bash
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.provisioning.state}'
echo

# If state is "provisioning" → Wait for it to complete
```

**Fix:**
Wait for provisioning to complete:
```bash
watch oc get baremetalhost $BMH_NAME -n openshift-machine-api
# Wait for state to change to "provisioned"
```

---

### Scenario 3: Machine in Inspection Image

**What's happening:**
- Machine booted into inspection/discovery image (IPA - Ironic Python Agent)
- This is a minimal image that may not have SSH enabled
- Used for hardware discovery

**Check:**
```bash
# State will be "inspecting"
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.provisioning.state}'
```

**Fix:**
- Wait for inspection to complete
- Or access via BMC console

---

### Scenario 4: Wrong IP Address

**What's happening:**
- You're trying the wrong IP
- DHCP might have assigned different IP
- IP changed between boot attempts

**Check:**
```bash
# Get fresh logs
METAL3_POD=$(oc get pods -n openshift-machine-api -l baremetal.openshift.io/cluster-baremetal-operator=metal3-state -o name | head -1)

# Look for most recent IP
oc logs -n openshift-machine-api $METAL3_POD --tail=100 | grep -i "$BMH_NAME"

# Or scan the network from a master
oc debug node/master-0 -- chroot /host nmap -sn 192.168.111.0/24
```

**Fix:**
Try each IP found in logs

---

### Scenario 5: SSH Service Not Started Yet

**What's happening:**
- Machine booted successfully
- Ignition completed
- But SSH service not started yet (timing issue)

**Check:**
Wait 2-3 minutes and try again

**Or check via BMC console:**
```bash
# From BMC console, check:
systemctl status sshd
journalctl -u sshd
```

---

### Scenario 6: Firewall Blocking SSH

**What's happening:**
- Machine booted and SSH running
- But firewall blocking port 22

**Check (via BMC console):**
```bash
# From BMC console:
systemctl status sshd  # Should be active
ss -tlnp | grep :22    # Should show listening

firewall-cmd --list-all  # Check if SSH allowed
```

**Fix (via BMC console):**
```bash
# Temporarily allow SSH
firewall-cmd --add-service=ssh

# Or disable firewall temporarily for testing
systemctl stop firewalld
```

---

## Step-by-Step Troubleshooting

### Step 1: Check Certificate Status

**This is likely your root cause - check it FIRST:**

```bash
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')

echo "Checking Machine Config Server certificate..."
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -checkend 0 && \
  echo "✅ Certificate is valid" || \
  echo "❌ Certificate EXPIRED - This is why SSH isn't working!"

echo ""
echo "Certificate dates:"
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -dates
```

**If certificate is expired:**
```bash
echo "Certificate is expired. Fixing..."

# Delete expired cert
oc delete secret machine-config-server-tls -n openshift-machine-config-operator

# Restart MCS pods to get new cert
oc delete pods -n openshift-machine-config-operator -l k8s-app=machine-config-server

# Wait
echo "Waiting 30 seconds for new certificate..."
sleep 30

# Verify
echo "New certificate:"
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -dates

echo ""
echo "✅ Certificate fixed. Now retry provisioning your BareMetalHost."
```

### Step 2: Check BareMetalHost Status

```bash
BMH_NAME="worker-0"

echo "=== BareMetalHost Status ==="
oc get baremetalhost $BMH_NAME -n openshift-machine-api

echo ""
echo "=== Provisioning State ==="
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.provisioning.state}'
echo

echo ""
echo "=== Error Message (if any) ==="
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.errorMessage}'
echo

echo ""
echo "=== Powered On? ==="
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.poweredOn}'
echo
```

### Step 3: Access BMC Console

```bash
echo "=== BMC Access Information ==="
echo ""

BMC_ADDR=$(oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.spec.bmc.address}')
BMC_IP=$(echo $BMC_ADDR | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')

SECRET_NAME=$(oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.spec.bmc.credentialsName}')
BMC_USER=$(oc get secret $SECRET_NAME -n openshift-machine-api -o jsonpath='{.data.username}' | base64 -d)
BMC_PASS=$(oc get secret $SECRET_NAME -n openshift-machine-api -o jsonpath='{.data.password}' | base64 -d)

echo "BMC IP: $BMC_IP"
echo "BMC URL: https://${BMC_IP}"
echo "Username: $BMC_USER"
echo "Password: $BMC_PASS"
echo ""
echo "Open this in your browser, login, and access the virtual console"
echo "This will show you EXACTLY what's happening on the machine"
```

### Step 4: Look at BMC Console Output

**What to look for in BMC console:**

✅ **Good (successful):**
```
[  OK  ] Reached target Multi-User System.
[  OK  ] Started OpenSSH server daemon.
Ignition: fetching config from https://10.0.0.1:22623/config/worker
Ignition: config fetched successfully
[  OK  ] Reached target Ignition Complete.
```

❌ **Bad (TLS error):**
```
Ignition: fetching config from https://10.0.0.1:22623/config/worker
Ignition: failed to fetch config: Get "https://10.0.0.1:22623/config/worker": x509: certificate has expired
Ignition: failed
Entering emergency mode
```

❌ **Bad (other error):**
```
Ignition: fetching config from https://10.0.0.1:22623/config/worker
Ignition: failed to fetch config: connection timeout
```

### Step 5: Power Cycle After Fixing Certificate

```bash
echo "Power cycling BareMetalHost..."

# Power off
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'
echo "Powered off, waiting 10 seconds..."
sleep 10

# Power on
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'
echo "Powered on"

echo ""
echo "Watch BMC console to see boot process"
echo "Also monitor with:"
echo "  watch oc get baremetalhost $BMH_NAME -n openshift-machine-api"
```

### Step 6: Wait and Retry SSH

```bash
echo "Waiting for machine to boot and SSH to start (this takes 3-5 minutes)..."
echo ""

# Try SSH every 30 seconds for 5 minutes
for i in {1..10}; do
    echo "Attempt $i/10..."
    
    # Try to connect (with timeout)
    if timeout 5 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 core@$WORKER_IP echo "SSH working!" 2>/dev/null; then
        echo "✅ SSH is now working!"
        break
    else
        echo "   Still not available, waiting 30 seconds..."
        sleep 30
    fi
done
```

---

## Quick Diagnosis Script

Save this as `diagnose-ssh-issue.sh`:

```bash
#!/bin/bash

BMH_NAME="${1:-worker-0}"
WORKER_IP="${2}"

echo "=== Diagnosing SSH Connection Refused ==="
echo "BareMetalHost: $BMH_NAME"
echo ""

# Check certificate
echo "1. Checking Machine Config Server certificate..."
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')
if echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -checkend 0 &>/dev/null; then
    echo "   ✅ Certificate is valid"
else
    echo "   ❌ Certificate EXPIRED - THIS IS YOUR PROBLEM!"
    echo "   Run the fix from Step 1 above"
fi

# Check BMH state
echo ""
echo "2. Checking BareMetalHost state..."
STATE=$(oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.provisioning.state}')
echo "   State: $STATE"

POWERED=$(oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.poweredOn}')
echo "   Powered On: $POWERED"

ERROR=$(oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.errorMessage}')
if [ -n "$ERROR" ]; then
    echo "   ⚠️  Error: $ERROR"
fi

# Get IP if not provided
if [ -z "$WORKER_IP" ]; then
    echo ""
    echo "3. Looking for worker IP in logs..."
    METAL3_POD=$(oc get pods -n openshift-machine-api -l baremetal.openshift.io/cluster-baremetal-operator=metal3-state -o name | head -1)
    WORKER_IP=$(oc logs -n openshift-machine-api $METAL3_POD --tail=500 | grep -i "$BMH_NAME" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | tail -1)
    echo "   Found IP: $WORKER_IP"
fi

# Test connectivity
if [ -n "$WORKER_IP" ]; then
    echo ""
    echo "4. Testing connectivity to $WORKER_IP..."
    
    if ping -c 1 -W 2 $WORKER_IP &>/dev/null; then
        echo "   ✅ Ping successful"
    else
        echo "   ❌ Ping failed - check IP or network"
    fi
    
    if nc -zv -w 2 $WORKER_IP 22 2>&1 | grep -q "succeeded\|open"; then
        echo "   ✅ Port 22 is open"
    else
        echo "   ❌ Port 22 closed/refused"
        echo "   → Machine booted but SSH not started (likely ignition failed)"
    fi
fi

# Get BMC info
echo ""
echo "5. BMC Console Access:"
SECRET_NAME=$(oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.spec.bmc.credentialsName}')
BMC_ADDR=$(oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.spec.bmc.address}')
BMC_IP=$(echo $BMC_ADDR | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')

echo "   URL: https://${BMC_IP}"
echo "   User: $(oc get secret $SECRET_NAME -n openshift-machine-api -o jsonpath='{.data.username}' | base64 -d)"
echo "   Pass: $(oc get secret $SECRET_NAME -n openshift-machine-api -o jsonpath='{.data.password}' | base64 -d)"

echo ""
echo "=== Recommendations ==="
echo "1. Fix the certificate if it's expired (see above)"
echo "2. Open BMC console to see what's actually happening"
echo "3. Power cycle the BareMetalHost after fixing cert"
echo "4. Watch BMC console during boot for ignition errors"
```

---

## Summary

**"Connection refused" almost certainly means:**
- ✅ Machine is on the network (you can reach it)
- ❌ SSH is not running
- 🔥 Most likely cause: **Ignition failed due to TLS error**, so SSH was never started

**To fix:**
1. **Check and fix the certificate** (see Step 1 above)
2. **Access BMC console** to see what's actually happening
3. **Power cycle the machine** after fixing the cert
4. **Watch in BMC console** - you should see successful ignition this time
5. **Wait 3-5 minutes** for SSH to start after successful boot
6. **Try SSH again** - should work now!

**Don't waste time debugging SSH - fix the root cause (TLS certificate) first!**


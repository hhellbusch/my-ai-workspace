# TLS Error But Certificate Not Expired

## Situation

- Worker fails to fetch ignition config
- TLS certificate verification error
- Certificate is NOT expired
- SSH connection refused (ignition failed)

**We need to find out what the ACTUAL TLS error is.**

---

## Step 1: Access BMC Console (CRITICAL - Do This First!)

You need to see the actual error message during boot:

```bash
BMH_NAME="worker-0"  # Replace with your BareMetalHost name

# Get BMC details
SECRET_NAME=$(oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.spec.bmc.credentialsName}')

echo "=== BMC Access Info ==="
BMC_IP=$(oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.spec.bmc.address}' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')

echo "BMC URL: https://${BMC_IP}"
echo "Username: $(oc get secret $SECRET_NAME -n openshift-machine-api -o jsonpath='{.data.username}' | base64 -d)"
echo "Password: $(oc get secret $SECRET_NAME -n openshift-machine-api -o jsonpath='{.data.password}' | base64 -d)"
echo ""
echo "1. Open BMC URL in browser"
echo "2. Login with credentials above"
echo "3. Open Virtual Console"
echo "4. Power cycle the host (see below)"
echo "5. WATCH the console during boot for the EXACT error message"
```

### Power Cycle to See Error

```bash
# Power off
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'
sleep 10

# Power on
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'

# Watch BMC console - look for ignition error messages
```

### What to Look For in Console

Look for lines like:
```
Ignition: fetching config from https://10.0.0.1:22623/config/worker
Ignition: failed to fetch config: <EXACT ERROR HERE>
```

Common error messages:
- `x509: certificate signed by unknown authority`
- `x509: certificate is not valid for any names`
- `TLS handshake timeout`
- `connection timeout`
- `certificate has expired` (but we know it's not this)

**Tell me what the EXACT error message is from the console!**

---

## Common Causes (When Cert Not Expired)

### Cause 1: CA Bundle Mismatch (Most Common)

**What it means:** The worker's ignition has an old/wrong CA certificate bundle, so it doesn't trust the MCS certificate.

#### Check CA Bundle

```bash
# Get the current CA bundle from the cluster
oc get configmap -n openshift-kube-apiserver kube-apiserver-server-ca -o jsonpath='{.data.ca-bundle\.crt}' > /tmp/cluster-ca.crt

# Get the CA bundle in worker machineconfig
oc get machineconfig 99-worker-generated-registries -o yaml | grep -A 100 "kubelet-ca.crt" > /tmp/worker-mc-ca.txt

echo "Cluster CA saved to: /tmp/cluster-ca.crt"
echo "Worker MC CA saved to: /tmp/worker-mc-ca.txt"
echo ""
echo "Compare these files to see if they match"
```

#### Check What CA the MCS Certificate Uses

```bash
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')

# Get the certificate chain
echo | openssl s_client -connect ${API_VIP}:22623 -showcerts 2>/dev/null > /tmp/mcs-cert-chain.txt

# Extract and check the issuer
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -text | grep -A 2 "Issuer:"

echo ""
echo "Full cert chain saved to: /tmp/mcs-cert-chain.txt"
```

#### Fix: Refresh Worker MachineConfig

```bash
# Force worker machineconfig to regenerate with current CA
oc patch machineconfig 99-worker-generated-registries --type merge -p '{"metadata":{"annotations":{"force-refresh":"'$(date +%s)'"}}}'

# Wait for worker MCP to update
echo "Waiting for worker MachineConfigPool to sync..."
oc get machineconfigpool worker -w
# Wait until UPDATED=True, UPDATING=False, DEGRADED=False

# Then retry worker provisioning
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'
sleep 10
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'
```

---

### Cause 2: Time Synchronization Issue

**What it means:** Worker's system clock is wrong (too far in past/future), making the certificate appear invalid.

#### Check Time from BMC Console

Once you have BMC console access:
1. Watch the boot process
2. Look at timestamps in boot messages
3. Or if you can get to a prompt: `date`

#### Check BMC System Time

```bash
# This varies by BMC type. Examples:

# Via Redfish API (if accessible)
BMC_IP="10.0.0.100"
BMC_USER="admin"
BMC_PASS="password"

curl -k -u ${BMC_USER}:${BMC_PASS} https://${BMC_IP}/redfish/v1/Managers/1 | jq .DateTime

# Via ipmitool (if you have network access)
ipmitool -I lanplus -H $BMC_IP -U $BMC_USER -P $BMC_PASS sel time get
```

#### Fix: Correct BMC Time

If BMC time is wrong, fix it through BMC web interface:
1. Login to BMC web UI
2. Navigate to Settings/Configuration
3. Find Date & Time settings
4. Set correct time or configure NTP

#### Fix: Add NTP to Worker Ignition

```bash
# Create MachineConfig to ensure time sync
cat <<EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 99-worker-chrony-ntp-servers
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,$(echo "server 0.pool.ntp.org iburst
server 1.pool.ntp.org iburst
server 2.pool.ntp.org iburst
server 3.pool.ntp.org iburst" | base64 -w0)
        mode: 0644
        path: /etc/chrony.d/99-custom-ntp.conf
        overwrite: true
    systemd:
      units:
      - name: chronyd.service
        enabled: true
EOF

# Wait for MCP to update
oc get machineconfigpool worker -w
```

---

### Cause 3: Certificate SAN Mismatch

**What it means:** The certificate doesn't include the hostname/IP being used in the ignition URL.

#### Check Certificate SANs

```bash
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')

# Check Subject Alternative Names
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -text | grep -A 10 "Subject Alternative Name"

# Should include:
# - DNS:api.<cluster-name>.<domain>
# - DNS:api-int.<cluster-name>.<domain>
# - IP Address:<api-vip>
```

#### Check What URL Worker Is Using

```bash
# Check the ignition config URL
oc get machineconfig 99-worker-generated-registries -o yaml | grep -i "22623\|config/worker"

# Also check infrastructure
oc get infrastructure cluster -o yaml | grep -E "apiServerInternalURI|apiVIP"
```

---

### Cause 4: Network Connectivity Issues

**What it means:** Worker can't properly reach MCS endpoint (intermittent connectivity, MTU issues, etc.)

#### Test MCS Endpoint Connectivity

```bash
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')

# Basic test
curl -kv https://${API_VIP}:22623/healthz

# Detailed TLS test
openssl s_client -connect ${API_VIP}:22623 -showcerts

# From a master node (same network as worker will be)
oc debug node/master-0 -- chroot /host curl -kv https://${API_VIP}:22623/healthz
```

#### Check MTU Settings

```bash
# Check MTU on master nodes
oc debug node/master-0 -- chroot /host ip link show | grep -i mtu

# If you see MTU issues, may need to adjust cluster network MTU
```

---

### Cause 5: HAProxy/Load Balancer Issues

**What it means:** The API VIP/HAProxy has issues serving the MCS endpoint.

#### Check HAProxy Status

```bash
# Check HAProxy on all masters
for node in $(oc get nodes -l node-role.kubernetes.io/master -o jsonpath='{.items[*].metadata.name}'); do
  echo "=== HAProxy on $node ==="
  oc debug node/$node -- chroot /host systemctl status haproxy
  echo ""
done
```

#### Check HAProxy Configuration

```bash
# Check HAProxy config includes MCS (port 22623)
oc debug node/master-0 -- chroot /host cat /etc/haproxy/haproxy.cfg | grep -A 10 "22623"

# Should see backend for machine-config-server
```

#### Check HAProxy Logs

```bash
# Check for errors
oc debug node/master-0 -- chroot /host journalctl -u haproxy -n 100 | grep -i "error\|fail"
```

---

### Cause 6: MCS Pods Not Healthy

**What it means:** Machine Config Server pods have issues.

#### Check MCS Pod Status

```bash
# Get pod status
oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server -o wide

# Check for restarts or issues
oc describe pods -n openshift-machine-config-operator -l k8s-app=machine-config-server

# Check logs for errors
oc logs -n openshift-machine-config-operator -l k8s-app=machine-config-server --tail=100 | grep -i "error\|fail\|tls\|certificate"
```

#### Check Machine Config Operator

```bash
# Check MCO status
oc get clusteroperator machine-config

# Should show:
# NAME             VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE   MESSAGE
# machine-config   4.x.x     True        False         False      Xd

# If degraded, check why
oc describe clusteroperator machine-config
```

---

### Cause 7: Certificate Re-signed But Old CA Still in Use

**What it means:** Certificates were regenerated but worker still has old CA bundle.

#### Check Certificate Age

```bash
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')

# Check when cert was issued
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -text | grep "Not Before"

# Check secret age
oc get secret machine-config-server-tls -n openshift-machine-config-operator -o yaml | grep creationTimestamp
```

#### Force Complete Refresh

```bash
# Delete MCS TLS secret (will regenerate)
oc delete secret machine-config-server-tls -n openshift-machine-config-operator

# Restart MCS pods
oc delete pods -n openshift-machine-config-operator -l k8s-app=machine-config-server

# Force worker MachineConfig refresh
oc patch machineconfig 99-worker-generated-registries --type merge -p '{"metadata":{"annotations":{"force-refresh":"'$(date +%s)'"}}}'

# Wait for MCP
oc get machineconfigpool worker -w

# Wait 1 minute for everything to settle
sleep 60

# Retry worker
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'
sleep 10
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'
```

---

## Detailed Certificate Validation

### Get Complete Certificate Info

```bash
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')

echo "=== Machine Config Server Certificate Details ==="
echo ""

echo "1. Certificate Dates:"
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -dates
echo ""

echo "2. Certificate Subject:"
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -subject
echo ""

echo "3. Certificate Issuer:"
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -issuer
echo ""

echo "4. Subject Alternative Names (SANs):"
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -text | grep -A 10 "Subject Alternative Name"
echo ""

echo "5. Certificate Verification:"
if echo | openssl s_client -connect ${API_VIP}:22623 2>&1 | grep -q "Verify return code: 0"; then
  echo "   ✅ Certificate validates successfully"
else
  VERIFY_CODE=$(echo | openssl s_client -connect ${API_VIP}:22623 2>&1 | grep "Verify return code:" | head -1)
  echo "   ❌ Certificate validation failed: $VERIFY_CODE"
fi
echo ""

echo "6. TLS Handshake Test:"
timeout 5 openssl s_client -connect ${API_VIP}:22623 </dev/null 2>&1 | head -30
```

### Test Certificate with Correct CA

```bash
# Get the cluster CA
oc get configmap -n openshift-kube-apiserver kube-apiserver-server-ca -o jsonpath='{.data.ca-bundle\.crt}' > /tmp/cluster-ca.crt

# Test connection with that CA
openssl s_client -connect ${API_VIP}:22623 -CAfile /tmp/cluster-ca.crt -verify_return_error

# If this succeeds but worker fails, it's a CA bundle mismatch issue
```

---

## Comprehensive Diagnostic Script

```bash
#!/bin/bash

BMH_NAME="${1:-worker-0}"

echo "=== Comprehensive TLS Diagnostic (Certificate Not Expired) ==="
echo "BareMetalHost: $BMH_NAME"
echo ""

# Get API VIP
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')
echo "API VIP: $API_VIP"
echo ""

# Test 1: Certificate details
echo "1. Certificate Expiration:"
DATES=$(echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -dates)
echo "$DATES"
EXPIRY=$(echo "$DATES" | grep "notAfter" | cut -d= -f2)
EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s 2>/dev/null)
NOW_EPOCH=$(date +%s)
DAYS_LEFT=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))
echo "   Days remaining: $DAYS_LEFT"
echo ""

# Test 2: Certificate validation
echo "2. Certificate Verification:"
if echo | openssl s_client -connect ${API_VIP}:22623 2>&1 | grep -q "Verify return code: 0"; then
  echo "   ✅ Validates successfully with system CA"
else
  VERIFY=$(echo | openssl s_client -connect ${API_VIP}:22623 2>&1 | grep "Verify return code:")
  echo "   ⚠️  $VERIFY"
fi
echo ""

# Test 3: SANs
echo "3. Subject Alternative Names:"
SANS=$(echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -text | grep -A 1 "Subject Alternative Name" | tail -1)
echo "$SANS"
if echo "$SANS" | grep -q "$API_VIP"; then
  echo "   ✅ API VIP ($API_VIP) is in SANs"
else
  echo "   ⚠️  API VIP ($API_VIP) NOT in SANs - potential issue!"
fi
echo ""

# Test 4: MCS pods
echo "4. Machine Config Server Pods:"
MCS_READY=$(oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server --no-headers 2>/dev/null | grep -c "Running")
if [ "$MCS_READY" -gt 0 ]; then
  echo "   ✅ $MCS_READY MCS pods running"
else
  echo "   ❌ No MCS pods running!"
fi
echo ""

# Test 5: Endpoint connectivity
echo "5. MCS Endpoint Test:"
HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://${API_VIP}:22623/healthz 2>/dev/null)
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "404" ]; then
  echo "   ✅ Endpoint reachable (HTTP $HTTP_CODE)"
else
  echo "   ❌ Endpoint issue (HTTP $HTTP_CODE)"
fi
echo ""

# Test 6: HAProxy
echo "6. HAProxy Status:"
MASTER_NODE=$(oc get nodes -l node-role.kubernetes.io/master -o jsonpath='{.items[0].metadata.name}')
HAPROXY_STATUS=$(oc debug node/$MASTER_NODE -- chroot /host systemctl is-active haproxy 2>/dev/null)
if [ "$HAPROXY_STATUS" = "active" ]; then
  echo "   ✅ HAProxy active on $MASTER_NODE"
else
  echo "   ⚠️  HAProxy status: $HAPROXY_STATUS"
fi
echo ""

# Test 7: Worker MCP
echo "7. Worker MachineConfigPool:"
MCP_UPDATED=$(oc get machineconfigpool worker -o jsonpath='{.status.conditions[?(@.type=="Updated")].status}' 2>/dev/null)
MCP_DEGRADED=$(oc get machineconfigpool worker -o jsonpath='{.status.conditions[?(@.type=="Degraded")].status}' 2>/dev/null)
echo "   Updated: $MCP_UPDATED"
echo "   Degraded: $MCP_DEGRADED"
if [ "$MCP_UPDATED" = "True" ] && [ "$MCP_DEGRADED" = "False" ]; then
  echo "   ✅ Worker MCP healthy"
else
  echo "   ⚠️  Worker MCP has issues"
fi
echo ""

# Test 8: BareMetalHost status
echo "8. BareMetalHost Status:"
BMH_STATE=$(oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.provisioning.state}' 2>/dev/null)
BMH_ERROR=$(oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.status.errorMessage}' 2>/dev/null)
echo "   State: $BMH_STATE"
if [ -n "$BMH_ERROR" ]; then
  echo "   Error: $BMH_ERROR"
fi
echo ""

echo "=== Next Steps ==="
echo "1. Check BMC console for EXACT error message during boot"
echo "2. Most likely issues based on above:"
if [ "$DAYS_LEFT" -lt 7 ]; then
  echo "   - Certificate expires soon ($DAYS_LEFT days) - consider regeneration"
fi
if ! echo "$SANS" | grep -q "$API_VIP"; then
  echo "   - Certificate SAN mismatch - regenerate certificate"
fi
if [ "$MCP_UPDATED" != "True" ]; then
  echo "   - Worker MachineConfig not updated - wait or force refresh"
fi
echo ""
echo "3. Get BMC access and watch boot:"
SECRET_NAME=$(oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.spec.bmc.credentialsName}' 2>/dev/null)
if [ -n "$SECRET_NAME" ]; then
  BMC_IP=$(oc get baremetalhost $BMH_NAME -n openshift-machine-api -o jsonpath='{.spec.bmc.address}' 2>/dev/null | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
  echo "   BMC: https://${BMC_IP}"
  echo "   User: $(oc get secret $SECRET_NAME -n openshift-machine-api -o jsonpath='{.data.username}' 2>/dev/null | base64 -d)"
  echo "   Pass: $(oc get secret $SECRET_NAME -n openshift-machine-api -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)"
fi
```

---

## Summary

Since certificate is not expired, check:

1. **🔍 BMC Console** - Get EXACT error message (most important!)
2. **📦 CA Bundle** - Worker may have old CA that doesn't trust current cert
3. **🕐 Time Sync** - Worker clock wrong
4. **🏷️  Certificate SANs** - Cert doesn't include API VIP/hostname
5. **🌐 Network** - Connectivity issues to MCS
6. **⚖️  HAProxy** - Load balancer issues
7. **🔄 MCS Pods** - Machine Config Server unhealthy

**Most likely:** CA bundle mismatch or time sync issue.

**First action:** Get the EXACT error from BMC console, then we can pinpoint the fix!


# Quick Reference: Worker Node TLS Certificate Failure

## One-Line Diagnostics

```bash
# Check MCS pods
oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server

# Check certificate expiration (MOST COMMON ISSUE)
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -dates

# Test endpoint
curl -kv https://${API_VIP}:22623/healthz 2>&1 | head -20

# Check BareMetalHost status
oc get baremetalhost -n openshift-machine-api -l node-role.kubernetes.io/worker
```

---

## Most Common Fixes

### Fix 1: Certificate Expired (70% of cases)

```bash
# Delete and recreate MCS TLS secret
oc delete secret machine-config-server-tls -n openshift-machine-config-operator
oc delete pods -n openshift-machine-config-operator -l k8s-app=machine-config-server

# Wait 30 seconds, then verify
sleep 30
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -dates
```

### Fix 2: MCS Pods Not Running (15% of cases)

```bash
# Restart MCS pods
oc delete pods -n openshift-machine-config-operator -l k8s-app=machine-config-server

# Check they come back
oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server -w
```

### Fix 3: Network Connectivity (10% of cases)

```bash
# Test from existing node
oc debug node/master-0 -- chroot /host bash -c "curl -kv https://${API_VIP}:22623/healthz"

# Check HAProxy status on masters
for node in $(oc get nodes -l node-role.kubernetes.io/master -o jsonpath='{.items[*].metadata.name}'); do
  echo "=== $node ==="
  oc debug node/$node -- chroot /host systemctl status haproxy
done
```

### Fix 4: Time Sync Issues (5% of cases)

```bash
# Check BMC time via console or Redfish API
# If time is wrong, fix at BMC level before booting worker

# Or add time sync to worker MachineConfig
cat <<EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 99-worker-chrony-ntp
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,$(echo "pool time.google.com iburst" | base64 -w0)
        mode: 0644
        path: /etc/chrony.d/ntp-servers.conf
EOF
```

---

## Retry Worker Provisioning After Fix

```bash
# Replace <worker-name> with your BareMetalHost name
WORKER_NAME="worker-0"

# Power off
oc patch baremetalhost $WORKER_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'

# Wait 10 seconds
sleep 10

# Power back on
oc patch baremetalhost $WORKER_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'

# Watch status
watch oc get baremetalhost $WORKER_NAME -n openshift-machine-api
```

---

## Troubleshooting Decision Tree

```
TLS Cert Error on Port 22623
    |
    ├─> Check: Is certificate expired?
    |       ├─> YES → Fix 1 (delete secret, restart pods)
    |       └─> NO → Continue
    |
    ├─> Check: Can you reach API_VIP:22623?
    |       ├─> NO → Fix 3 (check network/HAProxy)
    |       └─> YES → Continue
    |
    ├─> Check: Are MCS pods running?
    |       ├─> NO → Fix 2 (restart pods)
    |       └─> YES → Continue
    |
    └─> Check: Is worker node time correct?
            ├─> NO → Fix 4 (fix BMC time/add NTP)
            └─> YES → See full README for advanced troubleshooting
```

---

## Pre-Flight Check Before Adding Workers

```bash
#!/bin/bash
echo "=== Pre-Worker Addition Health Check ==="

# 1. Check MCS pods
echo -e "\n1. Machine Config Server Pods:"
oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server
MCS_READY=$(oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}')
if [ "$MCS_READY" = "True" ]; then
  echo "   ✅ MCS pods are Ready"
else
  echo "   ❌ MCS pods NOT ready"
fi

# 2. Check certificate
echo -e "\n2. Certificate Expiration:"
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')
EXPIRY=$(echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2)
echo "   Expires: $EXPIRY"
EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s)
NOW_EPOCH=$(date +%s)
DAYS_LEFT=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))
if [ $DAYS_LEFT -gt 7 ]; then
  echo "   ✅ Certificate valid for $DAYS_LEFT days"
else
  echo "   ⚠️  Certificate expires in $DAYS_LEFT days - consider renewal"
fi

# 3. Test endpoint
echo -e "\n3. MCS Endpoint Test:"
HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://${API_VIP}:22623/healthz 2>/dev/null)
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "404" ]; then
  echo "   ✅ Endpoint reachable (HTTP $HTTP_CODE)"
else
  echo "   ❌ Endpoint unreachable or error (HTTP $HTTP_CODE)"
fi

# 4. Check worker machineconfig
echo -e "\n4. Worker MachineConfig:"
WORKER_MC_COUNT=$(oc get machineconfig | grep -c worker)
if [ $WORKER_MC_COUNT -gt 0 ]; then
  echo "   ✅ Worker MachineConfigs present ($WORKER_MC_COUNT found)"
else
  echo "   ❌ No worker MachineConfigs found"
fi

echo -e "\n=== Health Check Complete ==="
```

Save as `pre-flight-check.sh` and run before adding workers.

---

## Monitoring Certificate Expiration

```bash
# Add to cron or monitoring system
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')

# Check expiry in seconds
EXPIRY_SEC=$(echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -dates | grep "notAfter" | cut -d= -f2)
EXPIRY_EPOCH=$(date -d "$EXPIRY_SEC" +%s)
NOW_EPOCH=$(date +%s)
DAYS_LEFT=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))

if [ $DAYS_LEFT -lt 30 ]; then
  echo "⚠️  WARNING: MCS certificate expires in $DAYS_LEFT days"
  echo "Run: oc delete secret machine-config-server-tls -n openshift-machine-config-operator"
fi
```

---

## Common Error Messages and What They Mean

| Error Message | Root Cause | Quick Fix |
|---------------|------------|-----------|
| `x509: certificate has expired` | MCS cert expired | Fix 1 |
| `x509: certificate signed by unknown authority` | CA bundle mismatch | See README Solution 2 |
| `connection refused` | MCS not running or firewall | Check pods, HAProxy |
| `connection timeout` | Network issue | Check VIP, routing |
| `dial tcp: lookup ... no such host` | DNS issue | Check cluster DNS |
| `TLS handshake timeout` | Time sync or slow network | Check time, latency |

---

## Emergency Recovery

If nothing works and you need workers NOW:

```bash
# 1. Verify at least MCS pods are running
oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server

# 2. Force complete MCS recreation
oc delete secret machine-config-server-tls -n openshift-machine-config-operator
oc delete pods -n openshift-machine-config-operator -l k8s-app=machine-config-server --force --grace-period=0

# 3. Wait for new pods (may take 2-3 minutes)
oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server -w

# 4. Verify certificate is fresh
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -dates

# 5. Force worker MachineConfig refresh
oc patch machineconfig 99-worker-generated-registries --type merge -p "{\"metadata\":{\"annotations\":{\"force-refresh\":\"$(date +%s)\"}}}"

# 6. Wait for worker MCP to sync
oc get mcp worker -w

# 7. Retry worker provisioning
oc patch baremetalhost <worker-name> -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'
sleep 10
oc patch baremetalhost <worker-name> -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'
```

---

## Success Indicators

### During Provisioning

```bash
# Worker should progress through these states:
oc get baremetalhost <worker-name> -n openshift-machine-api -w

# registering → inspecting → available → provisioning → provisioned
```

### After Provisioning

```bash
# 1. Node appears
oc get nodes | grep <worker-name>

# 2. CSRs created (may need manual approval)
oc get csr | grep <worker-name>

# 3. Node becomes Ready
oc get node <worker-name>
# Should show: Ready

# 4. Machine and MachineSet healthy
oc get machines -n openshift-machine-api | grep worker
oc get machinesets -n openshift-machine-api
```

---

## When to Escalate

Escalate to Red Hat Support if:

1. Certificate is valid but still getting TLS errors
2. MCS pods won't stay running
3. Fresh certificate installation doesn't resolve issue
4. Multiple components showing cert errors (cluster-wide issue)
5. HAProxy/keepalived issues on control plane nodes

Collect these before opening case:

```bash
# Must-gather
oc adm must-gather --dest-dir=/tmp/must-gather

# Specific MCS info
oc get all -n openshift-machine-config-operator -o yaml > /tmp/mco-resources.yaml
oc get machineconfig -o yaml > /tmp/machineconfigs.yaml
oc logs -n openshift-machine-config-operator -l k8s-app=machine-config-server --all-containers > /tmp/mcs-logs.txt

# Certificate details
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')
echo | openssl s_client -connect ${API_VIP}:22623 -showcerts 2>/dev/null > /tmp/mcs-certs.txt
```


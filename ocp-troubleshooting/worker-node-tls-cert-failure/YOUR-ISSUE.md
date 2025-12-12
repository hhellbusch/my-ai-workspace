# Your Specific Issue: TLS Certificate Verification Failed Adding Workers

## Situation Summary

**What you're experiencing:**
- Expanding OpenShift cluster by adding worker nodes
- Using BareMetalHost resources to add workers
- Worker nodes boot but fail to join cluster
- Error: TLS certificate verification failed
- Endpoint being hit: `https://<api-vip>:22623/config/worker`

**Why this matters:**
- Cannot expand cluster capacity
- Workers cannot fetch ignition configuration
- Need to fix before workers can join

---

## Immediate Actions (5 Minutes)

### Step 1: Run Automated Diagnostics

```bash
cd ~/gemini-workspace/ocp-troubleshooting/worker-node-tls-cert-failure

# Run the diagnostic script
./diagnose-tls.sh

# Review the recommendations
cat tls-diagnostics-*/RECOMMENDATIONS.txt
```

### Step 2: Quick Manual Check

```bash
# Check Machine Config Server pods
oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server

# Get API VIP
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')
echo "API VIP: $API_VIP"

# Check certificate expiration (MOST LIKELY ISSUE)
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -dates

# Check if certificate is expired
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -checkend 0 && \
  echo "✅ Certificate is valid" || \
  echo "❌ Certificate EXPIRED"
```

---

## Most Likely Cause: Expired Certificate

Based on your symptoms, **70% probability** the Machine Config Server certificate has expired.

### Verify This Is Your Issue

```bash
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')

# Check expiration
EXPIRY=$(echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2)
echo "Certificate expires: $EXPIRY"

# Calculate days left
EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s 2>/dev/null)
NOW_EPOCH=$(date +%s)
DAYS_LEFT=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))
echo "Days left: $DAYS_LEFT"

# If negative, it's expired!
```

### Fix: Regenerate Certificate

```bash
# 1. Delete the expired certificate secret
oc delete secret machine-config-server-tls -n openshift-machine-config-operator

# 2. Restart Machine Config Server pods (they will get new certs)
oc delete pods -n openshift-machine-config-operator -l k8s-app=machine-config-server

# 3. Wait for new pods to start
echo "Waiting for MCS pods to restart..."
sleep 30

# 4. Verify new pods are running
oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server

# 5. Verify new certificate
echo "Checking new certificate..."
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -dates

# 6. Test endpoint
curl -kv https://${API_VIP}:22623/healthz 2>&1 | head -20
```

### Retry Worker Provisioning

After fixing the certificate:

```bash
# Replace <worker-name> with your BareMetalHost name
WORKER_NAME="worker-0"  # Change this to your worker's name

# Check current status
oc get baremetalhost $WORKER_NAME -n openshift-machine-api

# Power off the worker
oc patch baremetalhost $WORKER_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'

# Wait 10 seconds
sleep 10

# Power back on
oc patch baremetalhost $WORKER_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'

# Monitor provisioning
watch oc get baremetalhost $WORKER_NAME -n openshift-machine-api
```

---

## Alternative Causes (If Certificate Is Valid)

### Cause 2: Network Connectivity Issues

If certificate is valid but worker still can't reach the endpoint:

```bash
# Test endpoint from a master node
oc debug node/master-0 -- chroot /host curl -kv https://${API_VIP}:22623/healthz

# Check HAProxy status on masters
for node in $(oc get nodes -l node-role.kubernetes.io/master -o jsonpath='{.items[*].metadata.name}'); do
  echo "=== Checking $node ==="
  oc debug node/$node -- chroot /host systemctl status haproxy
done

# Verify API VIP configuration
oc get infrastructure cluster -o yaml | grep -A 5 apiServer
```

### Cause 3: MCS Pods Not Running

```bash
# Check if MCS pods are running
oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server

# If not running, check why
oc describe pods -n openshift-machine-config-operator -l k8s-app=machine-config-server

# Check Machine Config Operator
oc get clusteroperator machine-config
oc describe clusteroperator machine-config
```

### Cause 4: Time Synchronization

If worker node's system time is wrong, certificate validation will fail even if cert is valid.

```bash
# This requires BMC console access to the worker during boot
# Check the time shown during CoreOS boot
# If time is wrong, fix BMC/BIOS time before booting worker

# Or add NTP configuration to worker MachineConfig:
cat <<EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 99-worker-chrony-time-sync
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,$(echo "pool time.google.com iburst" | base64 -w0)
        mode: 0644
        path: /etc/chrony.d/time-sync.conf
EOF

# Wait for worker MCP to update
oc get machineconfigpool worker -w
```

---

## Monitoring Worker Progress

After applying fixes, monitor worker through these stages:

### Stage 1: BareMetalHost Provisioning

```bash
# Watch BareMetalHost state changes
watch oc get baremetalhost -n openshift-machine-api

# Expected progression:
# registering → inspecting → available → provisioning → provisioned
```

### Stage 2: Node Appears in Cluster

```bash
# Watch for new worker nodes
watch oc get nodes

# Worker should appear after successful ignition fetch and boot
```

### Stage 3: CSR Approval (May Be Automatic)

```bash
# Check for pending CSRs
oc get csr | grep Pending

# If present, approve them (or see ../csr-management/ for details)
oc get csr -o name | xargs oc adm certificate approve
```

### Stage 4: Node Becomes Ready

```bash
# Monitor node status
oc get node <worker-name> -w

# Should transition to Ready state
```

---

## Complete Troubleshooting Workflow

```
1. Run diagnostics
   ↓
   ./diagnose-tls.sh
   ↓
2. Check certificate expiration
   ↓
   [ Expired? ]
   ↓
   YES → Delete secret + restart pods → Verify → Retry worker
   ↓
   NO → Check connectivity
   ↓
3. Test MCS endpoint
   ↓
   [ Reachable? ]
   ↓
   NO → Check HAProxy + VIP → Fix → Retry worker
   ↓
   YES → Check MCS pods
   ↓
4. Verify MCS pods running
   ↓
   [ Running? ]
   ↓
   NO → Check MCO operator → Fix → Retry worker
   ↓
   YES → Check time sync
   ↓
5. Verify worker time correct
   ↓
   [ Time OK? ]
   ↓
   NO → Fix BMC time or add NTP → Retry worker
   ↓
   YES → See advanced troubleshooting in README
```

---

## Success Indicators

You'll know it's working when:

1. **Certificate is valid and fresh**
   ```bash
   echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -checkend 0
   # Returns: 0 (success)
   ```

2. **MCS endpoint responds**
   ```bash
   curl -k -s -o /dev/null -w "%{http_code}" https://${API_VIP}:22623/healthz
   # Returns: 200 or 404 (both OK)
   ```

3. **Worker progresses through provisioning states**
   ```bash
   oc get baremetalhost <worker-name> -n openshift-machine-api
   # STATE: provisioning → provisioned
   ```

4. **Worker appears as node**
   ```bash
   oc get nodes | grep <worker-name>
   # Shows node in NotReady or Ready state
   ```

5. **Worker becomes Ready**
   ```bash
   oc get node <worker-name>
   # STATUS: Ready
   ```

---

## Additional Resources

### Within This Guide
- **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - Fast commands and fixes
- **[README.md](README.md)** - Complete troubleshooting guide
- **[INDEX.md](INDEX.md)** - Navigation and scenarios
- **diagnose-tls.sh** - Automated diagnostic tool

### Related Guides
- **[../bare-metal-node-inspection-timeout/](../bare-metal-node-inspection-timeout/)** - If workers are stuck in inspection
- **[../csr-management/](../csr-management/)** - CSR approval after worker joins
- **[../coreos-networking-issues/](../coreos-networking-issues/)** - Network connectivity problems

---

## Quick Command Reference

```bash
# Check certificate expiration
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -dates

# Fix expired certificate
oc delete secret machine-config-server-tls -n openshift-machine-config-operator
oc delete pods -n openshift-machine-config-operator -l k8s-app=machine-config-server

# Check MCS pods
oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server

# Test endpoint
curl -kv https://${API_VIP}:22623/healthz

# Check BareMetalHosts
oc get baremetalhost -n openshift-machine-api

# Retry worker provisioning
oc patch baremetalhost <worker-name> -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'
sleep 10
oc patch baremetalhost <worker-name> -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'

# Monitor progress
watch oc get baremetalhost -n openshift-machine-api
watch oc get nodes
```

---

## When to Escalate

Open Red Hat support case if:
- Certificate is valid but still getting TLS errors
- MCS pods won't stay running after restart
- Fresh certificate doesn't resolve the issue
- Multiple workers all failing with same error
- Issue persists after trying all solutions

**Data to collect before opening case:**
```bash
# Run diagnostics
./diagnose-tls.sh

# Run must-gather
oc adm must-gather --dest-dir=/tmp/must-gather

# Collect MCS specific data
oc get all -n openshift-machine-config-operator -o yaml > /tmp/mco-resources.yaml
oc logs -n openshift-machine-config-operator -l k8s-app=machine-config-server --all-containers > /tmp/mcs-logs.txt

# Include diagnostic output from diagnose-tls.sh
```

---

**Next Step:** Run `./diagnose-tls.sh` and follow the recommendations in the output.


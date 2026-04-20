# Troubleshooting: TLS Certificate Verification Failed When Adding Worker Nodes

## Overview

When expanding an OpenShift bare metal cluster by adding worker nodes via BareMetalHost resources, new workers must contact the Machine Config Server (MCS) on port 22623 to retrieve their ignition configuration. If this fails with a TLS certificate verification error, the worker node cannot join the cluster.

## Severity

**HIGH** - Prevents cluster expansion and worker node addition

## Symptoms

- New BareMetalHost workers fail to provision
- Node boots from ISO but fails during ignition fetch
- Console or journal logs show TLS certificate verification errors
- Error message references endpoint: `https://<api-vip>:22623/config/worker`
- Worker node may reboot repeatedly trying to fetch config
- BareMetalHost may show state transitions but node never joins cluster

## 🚨 Quick Diagnostic - Run This First

```bash
# 1. Check BareMetalHost status
oc get baremetalhost -n openshift-machine-api

# 2. Check if any workers are present
oc get nodes -l node-role.kubernetes.io/worker

# 3. Check machine-config-server pods
oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server

# 4. Verify the machine-config-server is serving on port 22623
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')
echo "Testing MCS endpoint at: ${API_VIP}:22623"
curl -v https://${API_VIP}:22623/healthz 2>&1 | grep -E "certificate|TLS|SSL"

# 5. Check certificate expiration
echo | openssl s_client -connect ${API_VIP}:22623 -servername api.cluster.local 2>/dev/null | openssl x509 -noout -dates
```

---

## Root Cause Analysis

### Understanding the Machine Config Server Flow

When a new worker boots:

```
1. Worker boots from ISO/PXE with minimal ignition
   ↓
2. Reaches out to https://<api-vip>:22623/config/worker
   ↓
3. MCS (Machine Config Server) serves full ignition config
   ↓
4. Ignition config includes certificates, kubelet config, etc.
   ↓
5. Worker applies config and joins cluster
```

**When TLS verification fails, step 2 cannot complete.**

### Common Root Causes

| Root Cause | Probability | How to Detect |
|------------|-------------|---------------|
| Certificate expired | 40% | Check cert dates |
| Wrong CA bundle in worker ignition | 30% | Compare CA bundles |
| Time sync issues on worker node | 15% | Check BMC/BIOS time |
| API VIP networking issues | 10% | Test connectivity |
| Corrupted certificates after cluster issues | 5% | Check MCS pod logs |

---

## Detailed Diagnostics

### Step 1: Verify Machine Config Server Health

```bash
# Check MCS pods are running
oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server

# Expected output: All pods Running
# NAME                                    READY   STATUS    RESTARTS   AGE
# machine-config-server-xxxxx             1/1     Running   0          5d

# Check MCS logs for errors
MCS_POD=$(oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server -o name | head -1)
oc logs -n openshift-machine-config-operator $MCS_POD --tail=50

# Look for:
# - Certificate errors
# - "TLS handshake error"
# - "certificate has expired"
```

### Step 2: Verify Certificate Validity

```bash
# Get API VIP
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')
echo "API VIP: $API_VIP"

# Check certificate served by MCS
echo | openssl s_client -connect ${API_VIP}:22623 -servername api.cluster.local 2>/dev/null | openssl x509 -noout -text | grep -A 2 "Validity"

# Expected output:
#         Validity
#             Not Before: <date>
#             Not After : <date>   # Should be in the future!

# Check if certificate is expired
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -checkend 0 && echo "Certificate is valid" || echo "Certificate EXPIRED"
```

### Step 3: Check Worker Ignition Configuration

```bash
# Get the worker machineconfig
oc get machineconfig 99-worker-generated-registries -o yaml > worker-machineconfig.yaml

# Check the CA bundle in the worker ignition
oc get machineconfig 99-worker-generated-registries -o jsonpath='{.spec.config.storage.files[?(@.path=="/etc/kubernetes/kubelet-ca.crt")].contents.source}' | base64 -d

# Compare with actual CA bundle
oc get configmap -n openshift-kube-apiserver kube-apiserver-server-ca -o jsonpath='{.data.ca-bundle\.crt}'
```

### Step 4: Test Connectivity from Bootstrap/Worker Network

```bash
# If you have access to the provisioning network, test from there
# Option A: From an existing worker or control plane node
oc debug node/worker-0 -- chroot /host curl -v https://${API_VIP}:22623/healthz

# Option B: From the bootstrap network (if accessible)
# You may need to check from the provisioning network directly

# Check firewall rules
oc get pods -n openshift-machine-config-operator -o wide
# Note the node hosting MCS, then check firewall on that node

NODE_WITH_MCS=$(oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server -o jsonpath='{.items[0].spec.nodeName}')
oc debug node/${NODE_WITH_MCS} -- chroot /host iptables-save | grep 22623
```

### Step 5: Check BareMetalHost Boot Process

```bash
# Get the failing worker's BareMetalHost name
BMH_NAME="worker-0"  # Replace with your worker name

# Check current state
oc get baremetalhost $BMH_NAME -n openshift-machine-api -o yaml

# Look at recent events
oc get events -n openshift-machine-api --field-selector involvedObject.name=$BMH_NAME --sort-by='.lastTimestamp'

# Check if the node is booting (look for DHCP/PXE events)
oc describe baremetalhost $BMH_NAME -n openshift-machine-api | grep -A 20 "Events:"

# Check metal3 logs for this host
METAL3_POD=$(oc get pods -n openshift-machine-api -l baremetal.openshift.io/cluster-baremetal-operator=metal3-state -o name | head -1)
oc logs -n openshift-machine-api $METAL3_POD --all-containers --tail=100 | grep -i "$BMH_NAME"
```

---

## Solutions

### Solution 1: Certificate Expired - Force Rotation

**When to use:** Certificate verification shows cert is expired

```bash
# Force certificate rotation for machine-config-server
# This will trigger new certificates to be issued

# 1. Delete the machine-config-server secret (it will be recreated)
oc delete secret machine-config-server-tls -n openshift-machine-config-operator

# 2. Restart machine-config-server pods
oc delete pods -n openshift-machine-config-operator -l k8s-app=machine-config-server

# 3. Wait for new pods to start
oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server -w

# 4. Verify new certificate
sleep 30
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -dates

# 5. Retry worker provisioning
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'
sleep 10
oc patch baremetalhost $BMH_NAME -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'
```

### Solution 2: Wrong CA Bundle - Update Worker MachineConfig

**When to use:** CA bundle mismatch detected

```bash
# 1. Get the current CA bundle from kube-apiserver
oc get configmap -n openshift-kube-apiserver kube-apiserver-server-ca -o jsonpath='{.data.ca-bundle\.crt}' > /tmp/correct-ca-bundle.crt

# 2. Check current worker machineconfig
oc get machineconfig 99-worker-generated-registries -o yaml > /tmp/worker-mc-backup.yaml

# 3. Force machineconfig regeneration by triggering MCO
oc patch machineconfig 99-worker-generated-registries --type merge -p '{"metadata":{"annotations":{"force-refresh":"'$(date +%s)'"}}}'

# 4. Wait for machineconfig to sync
oc get mcp worker -w
# Wait until UPDATED=True

# 5. Retry worker provisioning
oc annotate baremetalhost $BMH_NAME -n openshift-machine-api baremetalhost.metal3.io/status-
```

### Solution 3: Time Sync Issues - Fix Worker Node Time

**When to use:** Certificate is valid but worker node time is wrong

This requires console access to the worker node during boot or BMC access:

```bash
# Option A: Via BMC console during boot
# 1. Access BMC virtual console for the worker node
# 2. During CoreOS boot, press ESC to get to console
# 3. Check time: date
# 4. If wrong, this indicates BMC/BIOS time is incorrect

# Option B: Fix BMC time (example for Redfish)
BMC_IP="10.0.0.50"  # Replace with worker's BMC IP
BMC_USER="admin"
BMC_PASS="password"

# Check BMC time
curl -k -u ${BMC_USER}:${BMC_PASS} https://${BMC_IP}/redfish/v1/Managers/1 | jq .DateTime

# Option C: Use NTP in ignition (create custom MachineConfig)
cat <<EOF | oc apply -f -
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 99-worker-chrony
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,$(echo "server time.google.com iburst" | base64 -w0)
        mode: 0644
        path: /etc/chrony.d/time-sync.conf
        overwrite: true
    systemd:
      units:
      - name: chronyd.service
        enabled: true
EOF

# Wait for worker MCP to update
oc get mcp worker -w
```

### Solution 4: Network Connectivity Issues

**When to use:** Cannot reach API VIP from provisioning network

```bash
# 1. Verify API VIP is reachable from provisioning network
# Test from a working node
oc debug node/master-0 -- chroot /host bash -c "ping -c 3 $API_VIP && nc -zv $API_VIP 22623"

# 2. Check if MCS is bound to correct interface
MCS_POD=$(oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server -o name | head -1)
oc rsh -n openshift-machine-config-operator $MCS_POD netstat -tlnp | grep 22623

# 3. Check firewall rules on nodes hosting MCS
for node in $(oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server -o jsonpath='{.items[*].spec.nodeName}'); do
  echo "=== Firewall on $node ==="
  oc debug node/$node -- chroot /host firewall-cmd --list-all
done

# 4. Verify API VIP is configured correctly
oc get infrastructure cluster -o yaml | grep -A 5 apiServer

# 5. Check if HAProxy/keepalived is working
for node in $(oc get nodes -l node-role.kubernetes.io/master -o name); do
  echo "=== Checking $node ==="
  oc debug $node -- chroot /host bash -c "systemctl status haproxy keepalived"
done
```

### Solution 5: Disable Certificate Verification (TEMPORARY WORKAROUND)

**⚠️ WARNING: Only use this as a temporary workaround for testing**

```bash
# This requires modifying the worker ignition to skip TLS verification
# This is NOT RECOMMENDED for production

# 1. Create a custom MachineConfig that modifies ignition fetch
# Note: This is complex and requires careful handling
# Better to fix the root cause with Solutions 1-4 above

# Instead, if you must proceed without fixing certs:
# Use a custom ignition file with "ignition.security.tls.certificateAuthorities" set correctly
```

---

## Prevention and Best Practices

### 1. Monitor Certificate Expiration

```bash
# Create a monitoring script
cat > /tmp/check-mcs-certs.sh <<'EOF'
#!/bin/bash
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')
EXPIRY=$(echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2)
EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s)
NOW_EPOCH=$(date +%s)
DAYS_LEFT=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))

echo "Machine Config Server Certificate:"
echo "  Expires: $EXPIRY"
echo "  Days left: $DAYS_LEFT"

if [ $DAYS_LEFT -lt 30 ]; then
  echo "  ⚠️  WARNING: Certificate expires in less than 30 days"
fi
EOF

chmod +x /tmp/check-mcs-certs.sh
./tmp/check-mcs-certs.sh
```

### 2. Verify Before Adding Workers

```bash
# Before adding new workers, verify MCS is healthy
cat > /tmp/pre-worker-check.sh <<'EOF'
#!/bin/bash
echo "=== Pre-Worker Addition Checks ==="

# 1. MCS pods running
echo "1. Checking MCS pods..."
oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server

# 2. Certificate validity
echo -e "\n2. Checking certificate expiration..."
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -dates

# 3. MCS endpoint reachable
echo -e "\n3. Testing MCS endpoint..."
curl -k -s -o /dev/null -w "HTTP Status: %{http_code}\n" https://${API_VIP}:22623/healthz

# 4. Worker MachineConfig present
echo -e "\n4. Checking worker MachineConfig..."
oc get machineconfig | grep worker | head -5

echo -e "\n✅ Pre-checks complete. Review output above before proceeding."
EOF

chmod +x /tmp/pre-worker-check.sh
./tmp/pre-worker-check.sh
```

### 3. Keep Time Synchronized

Ensure all BMCs have correct time:

```bash
# Check BMC time for all workers before adding
for bmh in $(oc get baremetalhost -n openshift-machine-api -o name); do
  echo "=== $bmh ==="
  BMC_ADDR=$(oc get $bmh -n openshift-machine-api -o jsonpath='{.spec.bmc.address}')
  echo "BMC: $BMC_ADDR"
  # Extract IP (this is simplified, adjust for your environment)
  # Then check BMC time via Redfish API
done
```

---

## Advanced Troubleshooting

### Get Detailed Logs from Worker Boot Process

If you have BMC console access:

```bash
# 1. Access BMC console during worker boot
# 2. Watch for ignition errors during boot
# 3. Look for messages like:
#    "failed to fetch config: Get https://...:22623/config/worker: x509: certificate..."

# 4. If you can interrupt boot, check from CoreOS emergency console:
# - Check time: date
# - Check network: ip a; ping <api-vip>
# - Check DNS: dig api.<cluster>.<domain>
# - Manual curl test: curl -v https://<api-vip>:22623/healthz
```

### Regenerate All Machine Config Server Certificates

```bash
# Nuclear option: Force regeneration of all MCS certificates
# This should only be done during a maintenance window

# 1. Backup current secrets
oc get secret -n openshift-machine-config-operator machine-config-server-tls -o yaml > /tmp/mcs-tls-backup.yaml

# 2. Delete the secret
oc delete secret machine-config-server-tls -n openshift-machine-config-operator

# 3. Delete all MCS pods
oc delete pods -n openshift-machine-config-operator -l k8s-app=machine-config-server

# 4. Wait for recreation
oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server -w

# 5. Verify new certificates
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -text | grep -A 10 "Validity"
```

### Check for Cluster-Wide Certificate Issues

```bash
# If this is part of broader cert issues
oc get clusteroperators | grep -v "True.*False.*False"

# Check certificate signing
oc get csr

# Check for expired cluster certificates
for secret in $(oc get secrets -A -o json | jq -r '.items[] | select(.type=="kubernetes.io/tls") | "\(.metadata.namespace)/\(.metadata.name)"'); do
  echo "Checking $secret"
  CERT=$(oc get secret -n $(echo $secret | cut -d/ -f1) $(echo $secret | cut -d/ -f2) -o jsonpath='{.data.tls\.crt}' 2>/dev/null)
  if [ -n "$CERT" ]; then
    echo "$CERT" | base64 -d | openssl x509 -noout -checkend 0 2>/dev/null || echo "  ⚠️  EXPIRED"
  fi
done
```

---

## Quick Reference - Common Commands

```bash
# Check MCS health
oc get pods -n openshift-machine-config-operator -l k8s-app=machine-config-server

# Check certificate expiration
API_VIP=$(oc get infrastructure cluster -o jsonpath='{.status.apiServerInternalURI}' | cut -d: -f2 | tr -d '/')
echo | openssl s_client -connect ${API_VIP}:22623 2>/dev/null | openssl x509 -noout -dates

# Test MCS endpoint
curl -kv https://${API_VIP}:22623/healthz

# Check worker MachineConfig
oc get machineconfig | grep worker

# Check BareMetalHost status
oc get baremetalhost -n openshift-machine-api

# Force MCS restart
oc delete pods -n openshift-machine-config-operator -l k8s-app=machine-config-server

# Retry worker provisioning
oc patch baremetalhost <worker-name> -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'
sleep 10
oc patch baremetalhost <worker-name> -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'
```

---

## Related Issues

- **CSR approval for new workers**: See [../csr-management/README.md](../csr-management/README.md)
- **BareMetalHost inspection issues**: See [../bare-metal-node-inspection-timeout/README.md](../bare-metal-node-inspection-timeout/README.md)
- **Networking issues**: See [../coreos-networking-issues/README.md](../coreos-networking-issues/README.md)

---

## Success Criteria

You'll know the issue is resolved when:

1. **Worker can fetch ignition config successfully**
   ```bash
   # No TLS errors in logs
   ```

2. **BareMetalHost provisions successfully**
   ```bash
   oc get baremetalhost <worker-name> -n openshift-machine-api
   # STATE should progress: registering → provisioning → provisioned
   ```

3. **Worker node joins cluster**
   ```bash
   oc get nodes
   # Worker appears in node list
   ```

4. **CSRs created and approved** (if manual approval required)
   ```bash
   oc get csr | grep <worker-name>
   # Should see Approved,Issued
   ```

5. **Worker becomes Ready**
   ```bash
   oc get node <worker-name>
   # STATUS: Ready
   ```

---

## Additional Resources

- [OpenShift Documentation: Machine Config Server](https://docs.openshift.com/container-platform/latest/post_installation_configuration/machine-configuration-tasks.html)
- [Red Hat KCS: TLS handshake errors in Machine Config Server](https://access.redhat.com/solutions/)
- [Bare Metal Operator Documentation](https://github.com/metal3-io/baremetal-operator)


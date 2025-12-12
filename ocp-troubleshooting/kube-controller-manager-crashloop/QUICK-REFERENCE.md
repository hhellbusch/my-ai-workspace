# Quick Reference: kube-controller-manager Crash Loop

## One-Line Diagnostics

```bash
# Status check
oc get pods -n openshift-kube-controller-manager && oc get co kube-controller-manager

# Get logs
oc logs -n openshift-kube-controller-manager -l app=kube-controller-manager --tail=50 --previous

# Check events
oc get events -n openshift-kube-controller-manager --sort-by='.lastTimestamp' | tail -20
```

## Common Issues & Quick Fixes

### Certificate Expired
```bash
# Fix
oc delete secret kube-controller-manager-client-cert-key -n openshift-kube-controller-manager
watch oc get pods -n openshift-kube-controller-manager
```

### API Server Unreachable
```bash
# Check
oc get pods -n openshift-kube-apiserver
oc get pods -n openshift-etcd
# Fix the dependency first
```

### OOMKilled
```bash
# Check
oc describe pod -n openshift-kube-controller-manager -l app=kube-controller-manager | grep -A 3 "Last State"
oc adm top nodes
# May need infrastructure scaling
```

### Configuration Error
```bash
# Review
oc get kubecontrollermanager cluster -o yaml
# Restore or patch as needed
```

## Troubleshooting Decision Tree

```
Crash Loop Detected
    |
    ├─> Check Logs
    |     ├─> Certificate Error? → Delete secret, wait for regeneration
    |     ├─> Connection Error? → Check API server & etcd
    |     ├─> OOMKilled? → Check node resources
    |     ├─> Config Error? → Review & fix configuration
    |     └─> Webhook Timeout? → Check webhook services
    |
    ├─> Check Dependencies
    |     ├─> etcd healthy? → Fix etcd first
    |     ├─> API server healthy? → Fix API server first
    |     └─> Disk space? → Free up space
    |
    └─> Emergency Recovery
          ├─> Force pod regeneration (on node)
          └─> Generate must-gather for support
```

## Must-Collect Data

```bash
# Quick collection script
cat > collect-kcm-data.sh << 'EOF'
#!/bin/bash
OUTDIR="kcm-debug-$(date +%Y%m%d-%H%M%S)"
mkdir -p $OUTDIR
oc get pods -n openshift-kube-controller-manager -o wide > $OUTDIR/pods.txt
oc logs -n openshift-kube-controller-manager -l app=kube-controller-manager --tail=500 > $OUTDIR/current.log 2>&1
oc logs -n openshift-kube-controller-manager -l app=kube-controller-manager --previous > $OUTDIR/previous.log 2>&1
oc get events -n openshift-kube-controller-manager --sort-by='.lastTimestamp' > $OUTDIR/events.txt
oc get co kube-controller-manager -o yaml > $OUTDIR/operator.yaml
oc describe pod -n openshift-kube-controller-manager -l app=kube-controller-manager > $OUTDIR/describe.txt
tar czf $OUTDIR.tar.gz $OUTDIR/
echo "Data collected in $OUTDIR.tar.gz"
EOF
chmod +x collect-kcm-data.sh
./collect-kcm-data.sh
```

## Log Pattern Matching

```bash
# Find the error quickly
ERROR_PATTERNS=(
  "certificate"
  "x509"
  "connection refused"
  "timeout"
  "OOM"
  "killed"
  "invalid"
  "etcd"
  "failed to"
)

for pattern in "${ERROR_PATTERNS[@]}"; do
  echo "=== Checking for: $pattern ==="
  oc logs -n openshift-kube-controller-manager -l app=kube-controller-manager --tail=200 | grep -i "$pattern" | tail -3
done
```

## Critical Checks Matrix

| Check | Command | Expected Result |
|-------|---------|----------------|
| Pod Status | `oc get pods -n openshift-kube-controller-manager` | Running (not CrashLoopBackOff) |
| Restart Count | Same command + `-o wide` | Low/stable restart count |
| Operator Status | `oc get co kube-controller-manager` | Available=True, Degraded=False |
| API Server | `oc get pods -n openshift-kube-apiserver` | All Running |
| etcd | `oc get pods -n openshift-etcd` | All Running |
| Certificates | `oc get secrets -n openshift-kube-controller-manager` | Secrets present |
| Node Resources | `oc adm top nodes` | Sufficient memory/CPU |

## When to Escalate

- ✅ **Try yourself**: Certificate, single pod restart, clear error message
- ⚠️ **Consider escalating**: Multiple control plane components affected, no clear error
- 🚨 **Escalate immediately**: Production cluster, >1hr downtime, data loss risk

## Emergency Contact Commands

```bash
# Start must-gather (run in background, takes 5-10 minutes)
oc adm must-gather &

# Inspect specific namespace
oc adm inspect namespace/openshift-kube-controller-manager \
  --dest-dir=kcm-inspect-$(date +%Y%m%d-%H%M%S)
```


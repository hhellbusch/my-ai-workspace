# Quick Reference: Bare Metal Node Inspection Timeout

## One-Line Diagnostics

```bash
# Check all BareMetalHost status
oc get baremetalhost -n openshift-machine-api

# Get failing host details
oc describe baremetalhost master-2 -n openshift-machine-api | tail -30

# Check Ironic inspector logs
oc logs -n openshift-machine-api -l baremetal.openshift.io/cluster-baremetal-operator=metal3-state -c ironic-inspector --tail=50
```

## Common Issues & Quick Fixes

### BMC Not Reachable
```bash
# Test connectivity
BMC_IP=$(oc get baremetalhost master-2 -n openshift-machine-api -o jsonpath='{.spec.bmc.address}' | grep -oP '\d+\.\d+\.\d+\.\d+')
curl -k https://${BMC_IP}/redfish/v1/Systems

# Fix: Disable cert verification
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '{"spec":{"bmc":{"disableCertificateVerification":true}}}'
```

### Wrong Credentials
```bash
# Fix: Update secret
oc delete secret master-2-bmc-secret -n openshift-machine-api
oc create secret generic master-2-bmc-secret -n openshift-machine-api \
  --from-literal=username=CORRECT_USER \
  --from-literal=password=CORRECT_PASS
```

### Stuck in Failed State
```bash
# Fix: Clear status and retry
oc annotate baremetalhost master-2 -n openshift-machine-api baremetalhost.metal3.io/status-
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '{"spec":{"online":false}}'
sleep 10
oc patch baremetalhost master-2 -n openshift-machine-api --type merge -p '{"spec":{"online":true}}'
```

### Inspection Timeout
```bash
# Fix: Increase timeout
oc patch provisioning provisioning-configuration --type merge -p '{"spec":{"inspectTimeout":"3600"}}'
```

## Troubleshooting Decision Tree

```
Node Stuck in Inspecting
    |
    ├─> Can you ping BMC IP?
    |     NO  → Check network/firewall/BMC configuration
    |     YES → Continue
    |
    ├─> Can you curl BMC Redfish endpoint?
    |     NO  → Check credentials, disable cert verification
    |     YES → Continue
    |
    ├─> Is node powered on?
    |     NO  → Check power management, try manual power on
    |     YES → Continue
    |
    ├─> Does IPA boot and call back?
    |     NO  → Check DHCP, PXE boot, network connectivity
    |     YES → Continue
    |
    └─> Hardware detection issues
          → Check RAID configuration
          → Check NIC drivers
          → Increase timeout
```

## Quick Collection Script

```bash
# Save diagnostic data
cat > collect-bmh-data.sh << 'EOF'
#!/bin/bash
BMH=${1:-master-2}
OUT="bmh-diag-$(date +%Y%m%d-%H%M%S)"
mkdir -p $OUT

oc get baremetalhost $BMH -n openshift-machine-api -o yaml > $OUT/bmh.yaml
oc describe baremetalhost $BMH -n openshift-machine-api > $OUT/bmh-describe.txt
oc get pods -n openshift-machine-api > $OUT/pods.txt

IRONIC=$(oc get pods -n openshift-machine-api -l baremetal.openshift.io/cluster-baremetal-operator=metal3-state -o name | head -1)
oc logs -n openshift-machine-api $IRONIC -c ironic-inspector --tail=200 > $OUT/inspector.log 2>&1
oc logs -n openshift-machine-api $IRONIC -c ironic-conductor --tail=200 > $OUT/conductor.log 2>&1
oc logs -n openshift-machine-api deployment/metal3 --tail=200 > $OUT/metal3.log 2>&1

tar czf $OUT.tar.gz $OUT/
echo "Collected: $OUT.tar.gz"
EOF
chmod +x collect-bmh-data.sh
./collect-bmh-data.sh master-2
```

## Critical Checks Matrix

| Check | Command | What to Look For |
|-------|---------|------------------|
| BMH State | `oc get bmh -n openshift-machine-api` | Should progress past `inspecting` |
| BMC IP | Extract from BMH spec | Must be pingable |
| BMC Auth | Test with curl | Should return Redfish JSON |
| Ironic Logs | Check inspector logs | Look for connection/timeout errors |
| Power State | Check BMH status | Should be `true` |
| DHCP | Check metal3 logs | Node should get IP during boot |

## Fast Comparison Check

```bash
# Compare working vs failing node
diff <(oc get bmh master-0 -n openshift-machine-api -o yaml | grep -A 30 "^spec:") \
     <(oc get bmh master-2 -n openshift-machine-api -o yaml | grep -A 30 "^spec:")
```

## Emergency Recovery

```bash
# Nuclear option: Delete and recreate
oc get bmh master-2 -n openshift-machine-api -o yaml > master-2-backup.yaml
oc delete bmh master-2 -n openshift-machine-api

# Edit master-2-backup.yaml:
# - Remove status section
# - Remove metadata.resourceVersion
# - Fix any known issues

oc create -f master-2-backup.yaml
```

## When to Escalate

- ✅ **Try yourself**: BMC connectivity, credentials, cert verification
- ⚠️ **Consider escalating**: Hardware compatibility, complex RAID issues
- 🚨 **Escalate immediately**: BMC completely inaccessible, consistent kernel panics

## Most Likely Causes (Ordered)

1. **BMC connectivity** (70%) - Wrong IP, credentials, or cert issues
2. **Network/DHCP** (15%) - Node can't get IP or reach Ironic
3. **Stale state** (10%) - Previous failed attempt needs clearing
4. **Hardware** (5%) - RAID, NIC drivers, compatibility

## Quick Test BMC Access

```bash
# One-liner to test everything
BMH=master-2; \
BMC_IP=$(oc get bmh $BMH -n openshift-machine-api -o jsonpath='{.spec.bmc.address}' | grep -oP '\d+\.\d+\.\d+\.\d+'); \
SECRET=$(oc get bmh $BMH -n openshift-machine-api -o jsonpath='{.spec.bmc.credentialsName}'); \
USER=$(oc get secret $SECRET -n openshift-machine-api -o jsonpath='{.data.username}' | base64 -d); \
PASS=$(oc get secret $SECRET -n openshift-machine-api -o jsonpath='{.data.password}' | base64 -d); \
echo "Testing BMC at $BMC_IP with user $USER..."; \
ping -c 2 $BMC_IP && \
curl -k -u "$USER:$PASS" -s https://$BMC_IP/redfish/v1/Systems | jq . || echo "FAILED"
```

## Success Criteria

✅ **Resolved** when:
- BareMetalHost state changes to `available` or `provisioned`
- Node appears in `oc get nodes` (after full provisioning)
- Hardware details populated in BMH status
- No inspection errors in logs

## Common Mistakes

1. ❌ Wrong BMC path (e.g., `/redfish/v1/Systems/1` vs `/redfish/v1/Systems/System.Embedded.1`)
2. ❌ Using HTTP when BMC requires HTTPS
3. ❌ Not disabling cert verification for self-signed certs
4. ❌ Forgetting to power on the host (`spec.online: true`)
5. ❌ Copy-paste error in BMC IP address
6. ❌ Wrong protocol (`redfish://` vs `redfish-virtualmedia+https://`)


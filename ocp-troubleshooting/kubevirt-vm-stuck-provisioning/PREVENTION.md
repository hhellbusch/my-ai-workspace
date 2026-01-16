# Prevention Guide - Avoiding KubeVirt VM Provisioning Issues

This document provides strategies to prevent VM provisioning issues related to webhooks and OADP/Velero configuration.

## 1. Webhook Health Monitoring

### Automated Monitoring Script

Create a monitoring script to regularly check webhook health:

```bash
#!/bin/bash
# webhook-health-check.sh
# Run this periodically (e.g., via cron or as a monitoring probe)

set -euo pipefail

# Configuration
ALERT_EMAIL="admin@example.com"
SLACK_WEBHOOK_URL=""  # Optional: Add Slack webhook for alerts

# Check for Velero KubeVirt webhooks
WEBHOOKS=$(oc get mutatingwebhookconfigurations 2>/dev/null | grep -i velero | grep -i kubevirt || echo "")

if [ -z "$WEBHOOKS" ]; then
    # No webhook found - this is OK if not using OADP
    exit 0
fi

# Check each webhook's service
echo "$WEBHOOKS" | while read -r line; do
    WEBHOOK_NAME=$(echo "$line" | awk '{print $1}')
    
    # Get service details
    SERVICE_NAME=$(oc get mutatingwebhookconfigurations "$WEBHOOK_NAME" -o jsonpath='{.webhooks[0].clientConfig.service.name}' 2>/dev/null || echo "")
    SERVICE_NAMESPACE=$(oc get mutatingwebhookconfigurations "$WEBHOOK_NAME" -o jsonpath='{.webhooks[0].clientConfig.service.namespace}' 2>/dev/null || echo "")
    
    if [ -z "$SERVICE_NAME" ] || [ -z "$SERVICE_NAMESPACE" ]; then
        echo "ERROR: Cannot determine service for webhook $WEBHOOK_NAME"
        continue
    fi
    
    # Check if service exists
    if ! oc get svc "$SERVICE_NAME" -n "$SERVICE_NAMESPACE" &>/dev/null; then
        echo "ALERT: Webhook $WEBHOOK_NAME references missing service $SERVICE_NAME in namespace $SERVICE_NAMESPACE"
        echo "This will prevent VM provisioning!"
        
        # Send alert (implement based on your infrastructure)
        # send_alert "Webhook service missing" "$WEBHOOK_NAME"
        
        exit 1
    fi
    
    # Check service endpoints
    ENDPOINTS=$(oc get endpoints "$SERVICE_NAME" -n "$SERVICE_NAMESPACE" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null || echo "")
    
    if [ -z "$ENDPOINTS" ]; then
        echo "WARNING: Webhook service $SERVICE_NAME has no endpoints"
        echo "This may prevent VM provisioning!"
        
        exit 1
    fi
    
    echo "✓ Webhook $WEBHOOK_NAME is healthy"
done
```

### Schedule the Health Check

**Option 1: CronJob in OpenShift**

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: webhook-health-check
  namespace: openshift-cnv
spec:
  schedule: "*/15 * * * *"  # Every 15 minutes
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: webhook-monitor
          containers:
          - name: health-check
            image: image-registry.openshift-image-registry.svc:5000/openshift/cli:latest
            command:
            - /bin/bash
            - -c
            - |
              # Paste health check script here
          restartPolicy: OnFailure
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: webhook-monitor
  namespace: openshift-cnv
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: webhook-monitor
rules:
- apiGroups: ["admissionregistration.k8s.io"]
  resources: ["mutatingwebhookconfigurations"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["services", "endpoints"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: webhook-monitor
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: webhook-monitor
subjects:
- kind: ServiceAccount
  name: webhook-monitor
  namespace: openshift-cnv
```

**Option 2: Local Cron**

```bash
# Add to crontab
crontab -e

# Add line:
*/15 * * * * /path/to/webhook-health-check.sh >> /var/log/webhook-health.log 2>&1
```

## 2. OADP/Velero Best Practices

### Proper OADP Installation

Always install OADP with proper configuration:

```yaml
apiVersion: oadp.openshift.io/v1alpha1
kind: DataProtectionApplication
metadata:
  name: dpa-instance
  namespace: openshift-adp
spec:
  configuration:
    velero:
      defaultPlugins:
        - openshift
        - aws  # or azure, gcp, etc.
        - kubevirt  # Include this for VM support
    restic:
      enable: true  # For volume backups
  backupLocations:
    - velero:
        config:
          region: us-east-1
          profile: default
        credential:
          key: cloud
          name: cloud-credentials
        default: true
        objectStorage:
          bucket: oadp-backup-bucket
          prefix: velero
        provider: aws
```

### Validate After OADP Changes

After any OADP operator upgrade or configuration change:

```bash
# Validation script
#!/bin/bash

echo "Validating OADP installation..."

# Check operator
if ! oc get pods -n openshift-adp | grep oadp-operator | grep Running; then
    echo "ERROR: OADP operator not running"
    exit 1
fi

# Check Velero deployment
if ! oc get deployment -n openshift-adp velero &>/dev/null; then
    echo "ERROR: Velero deployment not found"
    exit 1
fi

# Check Velero pod
if ! oc get pods -n openshift-adp -l component=velero | grep Running; then
    echo "ERROR: Velero pod not running"
    exit 1
fi

# Check KubeVirt plugin
VELERO_POD=$(oc get pod -n openshift-adp -l component=velero -o name | head -1)
if ! oc exec -n openshift-adp $VELERO_POD -- velero plugin get | grep kubevirt; then
    echo "WARNING: KubeVirt plugin not loaded"
fi

# Check webhook service
if ! oc get svc kubevirt-velero-annotations-remover -n openshift-adp &>/dev/null; then
    echo "WARNING: Webhook service not found"
fi

echo "✓ OADP validation complete"
```

## 3. Change Management Procedures

### Before OADP Upgrades

```bash
# Pre-upgrade checklist script
#!/bin/bash

echo "=== Pre-OADP Upgrade Checklist ==="
echo ""

# 1. Document current state
echo "[1] Documenting current state..."
oc get dpa -n openshift-adp -o yaml > dpa-backup-$(date +%Y%m%d).yaml
oc get mutatingwebhookconfigurations | grep velero > webhooks-backup-$(date +%Y%m%d).txt

# 2. Test current backups
echo "[2] Testing current backup..."
velero backup get | head -10

# 3. Check for running VMs
echo "[3] Checking running VMs..."
oc get vm -A | grep -c Running || true

# 4. Document webhook state
echo "[4] Documenting webhook state..."
oc get mutatingwebhookconfigurations | grep velero | while read -r line; do
    WEBHOOK_NAME=$(echo "$line" | awk '{print $1}')
    oc get mutatingwebhookconfigurations "$WEBHOOK_NAME" -o yaml > "webhook-$WEBHOOK_NAME-$(date +%Y%m%d).yaml"
done

echo ""
echo "✓ Pre-upgrade documentation complete"
echo "Proceed with upgrade, then run post-upgrade validation"
```

### After OADP Upgrades

```bash
# Post-upgrade validation script
#!/bin/bash

echo "=== Post-OADP Upgrade Validation ==="
echo ""

# Wait for operator to stabilize
echo "Waiting 60 seconds for operator to stabilize..."
sleep 60

# Run validation
./webhook-health-check.sh

# Test VM creation
echo "Testing VM creation..."
cat <<EOF | oc apply -f - &>/dev/null
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: upgrade-test-vm
  namespace: default
spec:
  running: false
  template:
    spec:
      domain:
        devices:
          disks:
            - name: containerdisk
              disk: {}
        resources:
          requests:
            memory: 64Mi
      volumes:
        - name: containerdisk
          containerDisk:
            image: quay.io/kubevirt/cirros-container-disk-demo
EOF

if oc get vm upgrade-test-vm -n default &>/dev/null; then
    echo "✓ VM creation successful"
    oc delete vm upgrade-test-vm -n default
else
    echo "✗ VM creation failed - investigate immediately"
    exit 1
fi

echo ""
echo "✓ Post-upgrade validation complete"
```

## 4. Alerting Configuration

### Prometheus Alert Rules

If using OpenShift monitoring, add alert rules:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: kubevirt-webhook-alerts
  namespace: openshift-cnv
spec:
  groups:
  - name: kubevirt-webhooks
    interval: 5m
    rules:
    # Alert if webhook service is missing
    - alert: KubeVirtWebhookServiceMissing
      expr: |
        kube_service_info{service="kubevirt-velero-annotations-remover",namespace="openshift-adp"} == 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "KubeVirt Velero webhook service is missing"
        description: "The webhook service for KubeVirt Velero integration is missing. This will prevent VM provisioning."
    
    # Alert if webhook has no endpoints
    - alert: KubeVirtWebhookNoEndpoints
      expr: |
        kube_endpoint_address_available{endpoint="kubevirt-velero-annotations-remover",namespace="openshift-adp"} == 0
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "KubeVirt Velero webhook has no endpoints"
        description: "The webhook service exists but has no healthy endpoints."
    
    # Alert if VMs are stuck provisioning
    - alert: KubeVirtVMStuckProvisioning
      expr: |
        kubevirt_vm_running_status_last_transition_timestamp_seconds > 300
        and kubevirt_vm_running_status == 0
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "KubeVirt VM stuck in provisioning"
        description: "VM {{ $labels.name }} in namespace {{ $labels.namespace }} has been stuck provisioning for over 10 minutes."
```

## 5. Documentation and Training

### Maintain Runbooks

Keep runbooks updated with:
- Current OADP configuration
- Webhook troubleshooting procedures
- Emergency contacts
- Recent incident learnings

### Train Team Members

Ensure team members know:
- How to identify webhook issues
- Quick fix procedures
- When to escalate
- Where to find documentation

### Regular Drills

Periodically test recovery procedures:
```bash
# Test drill script (in non-production)
#!/bin/bash

echo "=== Recovery Drill ==="
echo "This will temporarily break VM provisioning for testing"
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    exit 0
fi

# Simulate webhook failure
WEBHOOK_NAME=$(oc get mutatingwebhookconfigurations | grep kubevirt | grep velero | awk '{print $1}')
oc patch mutatingwebhookconfigurations $WEBHOOK_NAME --type='json' \
  -p='[{"op": "replace", "path": "/webhooks/0/clientConfig/service/namespace", "value": "nonexistent"}]'

echo ""
echo "Webhook broken. Try to:"
echo "1. Identify the issue"
echo "2. Apply the fix"
echo "3. Verify resolution"
echo ""
echo "When done, restore with:"
echo "oc patch mutatingwebhookconfigurations $WEBHOOK_NAME --type='json' \\"
echo "  -p='[{\"op\": \"replace\", \"path\": \"/webhooks/0/clientConfig/service/namespace\", \"value\": \"openshift-adp\"}]'"
```

## 6. Configuration Management

### GitOps for OADP

Manage OADP configuration via GitOps:

```yaml
# gitops/oadp/dpa.yaml
apiVersion: oadp.openshift.io/v1alpha1
kind: DataProtectionApplication
metadata:
  name: dpa-instance
  namespace: openshift-adp
spec:
  # ... configuration
```

Benefits:
- Version control of configuration
- Automated deployment
- Audit trail of changes
- Easy rollback if needed

### Configuration Validation Pipeline

Add validation to CI/CD:

```yaml
# .github/workflows/validate-oadp.yml
name: Validate OADP Configuration
on:
  pull_request:
    paths:
      - 'gitops/oadp/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Validate YAML
        run: |
          yamllint gitops/oadp/
      
      - name: Check KubeVirt plugin
        run: |
          if ! grep -q "kubevirt" gitops/oadp/dpa.yaml; then
            echo "ERROR: KubeVirt plugin not configured"
            exit 1
          fi
      
      - name: Dry-run apply
        run: |
          oc apply --dry-run=server -f gitops/oadp/
```

## 7. Capacity Planning

Ensure sufficient resources:

```bash
# Resource monitoring script
#!/bin/bash

echo "=== Resource Capacity Check ==="

# Check node resources
echo "[1] Node capacity:"
oc describe nodes | grep -A 5 "Allocated resources"

# Check storage
echo "[2] Storage capacity:"
oc get pv | grep Available

# Check for resource pressure
echo "[3] Resource pressure events:"
oc get events -A | grep -i "insufficient\|pressure" | tail -10

# Recommend actions if needed
```

## Quick Reference: Prevention Checklist

- [ ] Webhook health monitoring configured
- [ ] OADP properly installed with KubeVirt plugin
- [ ] Validation script runs after OADP changes
- [ ] Change management procedures documented
- [ ] Pre/post upgrade checklists in place
- [ ] Prometheus alerts configured
- [ ] Team trained on troubleshooting
- [ ] Runbooks maintained and accessible
- [ ] Recovery drills scheduled quarterly
- [ ] Configuration managed via GitOps
- [ ] Validation in CI/CD pipeline
- [ ] Resource capacity monitored

## Summary

The key to prevention is:
1. **Monitoring**: Know when webhooks become unhealthy
2. **Validation**: Always verify after changes
3. **Documentation**: Keep procedures current and accessible
4. **Training**: Ensure team can respond quickly
5. **Automation**: Use scripts and alerts to catch issues early

By implementing these practices, you can significantly reduce the likelihood of VM provisioning issues related to webhooks and OADP configuration.


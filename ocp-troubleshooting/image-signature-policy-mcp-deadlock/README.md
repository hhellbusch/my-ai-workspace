# Image Signature Policy Rejection Blocking MCP Rollout

## Applies To

- **OpenShift Container Platform**: 4.6 and later
- **Platforms**: All (Bare Metal, VMware, AWS, Azure, GCP, etc.)
- **Symptom Severity**: HIGH - Cluster stuck in partially-configured state

## Symptom

Pods fail to pull images from Red Hat registries with signature validation errors, preventing MachineConfigPool (MCP) updates from completing.

**Common error messages:**
```
Failed to pull image "registry.redhat.io/redhat/certified-operator-index:v4.18": SignatureValidationFailed: copying system image from manifest list: Source image rejected: Running image docker://registry.redhat.io/redhat/certified-operator-index:v4.18 is rejected by policy.
```

```
Failed to pull image "registry.redhat.io/openshift4/ose-*": SignatureValidationFailed
```

**Critical Deadlock Scenario:**
- MachineConfigPool has pending changes that need to roll out
- Pods required for the rollout cannot start due to signature validation policy
- Cannot update signature policy via MachineConfig because MCP is blocked
- **Result: Cluster stuck in partially-configured state**

## Root Causes

1. **Missing or Restrictive Container Signature Policy**: `/etc/containers/policy.json` on cluster nodes is rejecting Red Hat registry images
2. **Disconnected Environment Misconfiguration**: Air-gapped clusters without proper signature configuration for mirrored registries
3. **Custom Security Policies**: Organization-specific security policies enforcing strict signature verification
4. **MachineConfig Race Condition**: Policy-fixing MachineConfig cannot apply because earlier MachineConfig is blocked by the policy issue
5. **Missing GPG Keys**: Red Hat GPG keys not present or not referenced correctly in policy.json

## Investigation Workflow

### 1. Confirm Signature Policy Rejection

```bash
# Check for image pull failures
oc get pods -A | grep -E "ImagePullBackOff|ErrImagePull"

# Get detailed error from affected pod
oc describe pod <pod-name> -n <namespace> | grep -A10 "Events:"

# Look for "rejected by policy" messages
oc get events -A | grep -i "rejected by policy"
```

**What to look for:**
- "SignatureValidationFailed" errors
- "rejected by policy" messages
- References to specific registry paths (registry.redhat.io, registry.access.redhat.com)

### 2. Check Image Registry Configuration

```bash
# Verify registry is in allowedRegistries
oc get image.config.openshift.io/cluster -o yaml

# Look for registrySources configuration
oc get image.config.openshift.io/cluster -o jsonpath='{.spec.registrySources}' | jq .
```

**Expected configuration:**
```yaml
spec:
  registrySources:
    allowedRegistries:
    - registry.redhat.io
    - registry.access.redhat.com
    - catalog.redhat.com
    # ... other registries
```

**If registry.redhat.io is present but still getting errors → signature policy issue, not registry access issue**

### 3. Check MachineConfigPool Status

```bash
# Check MCP status
oc get mcp

# Look for UPDATED=False and UPDATING=True
oc get mcp -o wide

# Get detailed MCP status
oc describe mcp master
oc describe mcp worker

# Check what's pending
oc get mcp -o yaml | grep -A30 "conditions:"
```

**What to look for:**
- `MACHINECOUNT` vs `READYMACHINECOUNT` vs `UPDATEDMACHINECOUNT`
- Degraded conditions
- Pending machine configs

### 4. Check Existing Signature Policy on Nodes

```bash
# SSH to a node and check current policy
oc debug node/<node-name>

# Once in the debug pod
chroot /host

# View current policy
cat /etc/containers/policy.json

# Exit debug pod
exit
exit
```

**Example of problematic policy (missing Red Hat registries):**
```json
{
  "default": [{"type": "reject"}],
  "transports": {
    "docker": {
      "quay.io": [{"type": "insecureAcceptAnything"}]
    }
  }
}
```

**Example of working policy (includes Red Hat registries):**
```json
{
  "default": [{"type": "insecureAcceptAnything"}],
  "transports": {
    "docker-daemon": {
      "": [{"type": "insecureAcceptAnything"}]
    },
    "docker": {
      "registry.redhat.io": [
        {
          "type": "signedBy",
          "keyType": "GPGKeys",
          "keyPath": "/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release"
        }
      ],
      "registry.access.redhat.com": [
        {
          "type": "signedBy",
          "keyType": "GPGKeys",
          "keyPath": "/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release"
        }
      ]
    }
  }
}
```

### 5. Identify the Deadlock

```bash
# Check if there's a pending MC that would fix the policy
oc get machineconfig | grep -i "policy\|container\|signature"

# See recent machine configs
oc get machineconfig --sort-by=.metadata.creationTimestamp | tail -10

# Check if any MC contains policy.json
for mc in $(oc get machineconfig -o name); do
  echo "=== $mc ==="
  oc get $mc -o yaml | grep -A5 "policy.json" || echo "No policy.json found"
done
```

## Resolution

### Manual Fix (Required for Deadlock Scenarios)

When MCP is blocked and cannot roll out the policy fix via MachineConfig, you must manually update `/etc/containers/policy.json` on all affected nodes.

**Use the provided script:** `manual-fix-signature-policy.sh`

#### Manual Fix Script Usage

```bash
# Make script executable
chmod +x manual-fix-signature-policy.sh

# Run the script (requires cluster-admin access)
./manual-fix-signature-policy.sh

# The script will:
# 1. Identify all nodes
# 2. Back up existing policy.json
# 3. Deploy new policy.json
# 4. Restart CRI-O to apply changes
# 5. Verify the fix
```

#### Manual Fix - Step by Step

If you prefer to do it manually or need to understand what the script does:

**Step 1: Create the corrected policy.json**

```bash
cat > /tmp/policy.json << 'EOF'
{
  "default": [
    {
      "type": "insecureAcceptAnything"
    }
  ],
  "transports": {
    "docker-daemon": {
      "": [{"type": "insecureAcceptAnything"}]
    },
    "docker": {
      "registry.redhat.io": [
        {
          "type": "signedBy",
          "keyType": "GPGKeys",
          "keyPath": "/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release"
        }
      ],
      "registry.access.redhat.com": [
        {
          "type": "signedBy",
          "keyType": "GPGKeys",
          "keyPath": "/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release"
        }
      ],
      "catalog.redhat.com": [
        {
          "type": "signedBy",
          "keyType": "GPGKeys",
          "keyPath": "/etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release"
        }
      ]
    }
  }
}
EOF
```

**Step 2: Apply to all nodes**

```bash
# Get list of all nodes
NODES=$(oc get nodes -o jsonpath='{.items[*].metadata.name}')

# For each node
for NODE in $NODES; do
  echo "=== Fixing $NODE ==="
  
  # Backup existing policy
  oc debug node/$NODE -- chroot /host bash -c \
    "cp /etc/containers/policy.json /etc/containers/policy.json.backup.$(date +%Y%m%d-%H%M%S)"
  
  # Deploy new policy
  cat /tmp/policy.json | oc debug node/$NODE -- chroot /host bash -c \
    "cat > /etc/containers/policy.json"
  
  # Restart CRI-O to pick up the new policy
  oc debug node/$NODE -- chroot /host bash -c \
    "systemctl restart crio"
  
  echo "✓ $NODE fixed"
  echo ""
done
```

**Step 3: Verify the fix**

```bash
# Check that CRI-O is running on all nodes
for NODE in $NODES; do
  echo "=== $NODE ==="
  oc debug node/$NODE -- chroot /host bash -c \
    "systemctl status crio | head -3"
done

# Verify policy.json is correct
for NODE in $NODES; do
  echo "=== $NODE ==="
  oc debug node/$NODE -- chroot /host bash -c \
    "cat /etc/containers/policy.json | jq '.transports.docker | keys'"
done
```

**Step 4: Verify pod recovery**

```bash
# Wait a few minutes for pods to restart and pull images
sleep 120

# Check if previously failing pods are now running
oc get pods -A | grep -E "ImagePullBackOff|ErrImagePull"

# Should return no results or significantly fewer results
```

**Step 5: Allow MCP to complete**

```bash
# Watch MCP progress
watch oc get mcp

# Wait for UPDATED=True and UPDATING=False
# This may take 30-60 minutes depending on cluster size

# Check for any degraded conditions
oc get mcp -o yaml | grep -A5 "degraded"
```

### Permanent Fix via MachineConfig

After manually fixing the nodes and allowing the MCP to complete, deploy a MachineConfig to ensure the policy persists:

**Create:** `signature-policy-machineconfig.yaml`

```yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 99-master-container-signature-policy
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,ewogICJkZWZhdWx0IjogWwogICAgewogICAgICAidHlwZSI6ICJpbnNlY3VyZUFjY2VwdEFueXRoaW5nIgogICAgfQogIF0sCiAgInRyYW5zcG9ydHMiOiB7CiAgICAiZG9ja2VyLWRhZW1vbiI6IHsKICAgICAgIiI6IFt7InR5cGUiOiAiaW5zZWN1cmVBY2NlcHRBbnl0aGluZyJ9XQogICAgfSwKICAgICJkb2NrZXIiOiB7CiAgICAgICJyZWdpc3RyeS5yZWRoYXQuaW8iOiBbCiAgICAgICAgewogICAgICAgICAgInR5cGUiOiAic2lnbmVkQnkiLAogICAgICAgICAgImtleVR5cGUiOiAiR1BHS2V5cyIsCiAgICAgICAgICAia2V5UGF0aCI6ICIvZXRjL3BraS9ycG0tZ3BnL1JQTS1HUEctS0VZLXJlZGhhdC1yZWxlYXNlIgogICAgICAgIH0KICAgICAgXSwKICAgICAgInJlZ2lzdHJ5LmFjY2Vzcy5yZWRoYXQuY29tIjogWwogICAgICAgIHsKICAgICAgICAgICJ0eXBlIjogInNpZ25lZEJ5IiwKICAgICAgICAgICJrZXlUeXBlIjogIkdQR0tleXMiLAogICAgICAgICAgImtleVBhdGgiOiAiL2V0Yy9wa2kvcnBtLWdwZy9SUE0tR1BHLUtFWS1yZWRoYXQtcmVsZWFzZSIKICAgICAgICB9CiAgICAgIF0sCiAgICAgICJjYXRhbG9nLnJlZGhhdC5jb20iOiBbCiAgICAgICAgewogICAgICAgICAgInR5cGUiOiAic2lnbmVkQnkiLAogICAgICAgICAgImtleVR5cGUiOiAiR1BHS2V5cyIsCiAgICAgICAgICAia2V5UGF0aCI6ICIvZXRjL3BraS9ycG0tZ3BnL1JQTS1HUEctS0VZLXJlZGhhdC1yZWxlYXNlIgogICAgICAgIH0KICAgICAgXQogICAgfQogIH0KfQo=
        filesystem: root
        mode: 420
        path: /etc/containers/policy.json
---
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 99-worker-container-signature-policy
spec:
  config:
    ignition:
      version: 3.2.0  # For OCP 4.6-4.15. Use 3.4.0 for OCP 4.16+
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,ewogICJkZWZhdWx0IjogWwogICAgewogICAgICAidHlwZSI6ICJpbnNlY3VyZUFjY2VwdEFueXRoaW5nIgogICAgfQogIF0sCiAgInRyYW5zcG9ydHMiOiB7CiAgICAiZG9ja2VyLWRhZW1vbiI6IHsKICAgICAgIiI6IFt7InR5cGUiOiAiaW5zZWN1cmVBY2NlcHRBbnl0aGluZyJ9XQogICAgfSwKICAgICJkb2NrZXIiOiB7CiAgICAgICJyZWdpc3RyeS5yZWRoYXQuaW8iOiBbCiAgICAgICAgewogICAgICAgICAgInR5cGUiOiAic2lnbmVkQnkiLAogICAgICAgICAgImtleVR5cGUiOiAiR1BHS2V5cyIsCiAgICAgICAgICAia2V5UGF0aCI6ICIvZXRjL3BraS9ycG0tZ3BnL1JQTS1HUEctS0VZLXJlZGhhdC1yZWxlYXNlIgogICAgICAgIH0KICAgICAgXSwKICAgICAgInJlZ2lzdHJ5LmFjY2Vzcy5yZWRoYXQuY29tIjogWwogICAgICAgIHsKICAgICAgICAgICJ0eXBlIjogInNpZ25lZEJ5IiwKICAgICAgICAgICJrZXlUeXBlIjogIkdQR0tleXMiLAogICAgICAgICAgImtleVBhdGgiOiAiL2V0Yy9wa2kvcnBtLWdwZy9SUE0tR1BHLUtFWS1yZWRoYXQtcmVsZWFzZSIKICAgICAgICB9CiAgICAgIF0sCiAgICAgICJjYXRhbG9nLnJlZGhhdC5jb20iOiBbCiAgICAgICAgewogICAgICAgICAgInR5cGUiOiAic2lnbmVkQnkiLAogICAgICAgICAgImtleVR5cGUiOiAiR1BHS2V5cyIsCiAgICAgICAgICAia2V5UGF0aCI6ICIvZXRjL3BraS9ycG0tZ3BnL1JQTS1HUEctS0VZLXJlZGhhdC1yZWxlYXNlIgogICAgICAgIH0KICAgICAgXQogICAgfQogIH0KfQo=
        filesystem: root
        mode: 420
        path: /etc/containers/policy.json
```

**Decode the base64 to see the policy:**
```bash
echo "ewogICJkZWZhdWx0IjogWwogICAgewogICAgICAidHlwZSI6ICJpbnNlY3VyZUFjY2VwdEFueXRoaW5nIgogICAgfQogIF0sCiAgInRyYW5zcG9ydHMiOiB7CiAgICAiZG9ja2VyLWRhZW1vbiI6IHsKICAgICAgIiI6IFt7InR5cGUiOiAiaW5zZWN1cmVBY2NlcHRBbnl0aGluZyJ9XQogICAgfSwKICAgICJkb2NrZXIiOiB7CiAgICAgICJyZWdpc3RyeS5yZWRoYXQuaW8iOiBbCiAgICAgICAgewogICAgICAgICAgInR5cGUiOiAic2lnbmVkQnkiLAogICAgICAgICAgImtleVR5cGUiOiAiR1BHS2V5cyIsCiAgICAgICAgICAia2V5UGF0aCI6ICIvZXRjL3BraS9ycG0tZ3BnL1JQTS1HUEctS0VZLXJlZGhhdC1yZWxlYXNlIgogICAgICAgIH0KICAgICAgXSwKICAgICAgInJlZ2lzdHJ5LmFjY2Vzcy5yZWRoYXQuY29tIjogWwogICAgICAgIHsKICAgICAgICAgICJ0eXBlIjogInNpZ25lZEJ5IiwKICAgICAgICAgICJrZXlUeXBlIjogIkdQR0tleXMiLAogICAgICAgICAgImtleVBhdGgiOiAiL2V0Yy9wa2kvcnBtLWdwZy9SUE0tR1BHLUtFWS1yZWRoYXQtcmVsZWFzZSIKICAgICAgICB9CiAgICAgIF0sCiAgICAgICJjYXRhbG9nLnJlZGhhdC5jb20iOiBbCiAgICAgICAgewogICAgICAgICAgInR5cGUiOiAic2lnbmVkQnkiLAogICAgICAgICAgImtleVR5cGUiOiAiR1BHS2V5cyIsCiAgICAgICAgICAia2V5UGF0aCI6ICIvZXRjL3BraS9ycG0tZ3BnL1JQTS1HUEctS0VZLXJlZGhhdC1yZWxlYXNlIgogICAgICAgIH0KICAgICAgXQogICAgfQogIH0KfQo=" | base64 -d | jq .
```

**Apply the MachineConfig (only AFTER manual fix and MCP completion):**

```bash
# Apply the machine config
oc apply -f signature-policy-machineconfig.yaml

# This will trigger another MCP rollout, but this time it should succeed
watch oc get mcp
```

## Prevention

### 1. Include Signature Policy in Initial Cluster Configuration

When deploying new clusters, include container signature policy in your install-config or day-2 automation:

```yaml
# In install-config.yaml or as day-2 MachineConfig
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 99-master-container-signature-policy
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,<base64-encoded-policy>
        filesystem: root
        mode: 420
        path: /etc/containers/policy.json
```

### 2. Use GitOps to Manage Signature Policies

Store signature policy MachineConfigs in Git and deploy via ArgoCD:

```yaml
# argo-examples/apps/cluster-config/signature-policy/
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: container-signature-policy
  namespace: openshift-gitops
spec:
  destination:
    namespace: openshift-config
    server: https://kubernetes.default.svc
  project: cluster-config
  source:
    path: machineconfigs/signature-policy
    repoURL: https://github.com/your-org/cluster-config
    targetRevision: main
  syncPolicy:
    automated:
      prune: false
      selfHeal: true
```

### 3. Test Signature Policies Before Production

In dev/test environments:

```bash
# Deploy the signature policy MC
oc apply -f signature-policy-machineconfig.yaml

# Wait for MCP to complete
watch oc get mcp

# Verify all operators can pull images
oc get pods -A | grep -E "ImagePull|Error"

# Check specific Red Hat operator catalogs
oc get catalogsource -n openshift-marketplace
oc get pods -n openshift-marketplace
```

### 4. Monitor MCP Health

Set up alerts for MCP degradation:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: mcp-health-alerts
  namespace: openshift-monitoring
spec:
  groups:
  - name: mcp-health
    interval: 30s
    rules:
    - alert: MCPDegraded
      expr: mcp_machine_config_pool_degraded_machine_count > 0
      for: 15m
      labels:
        severity: warning
      annotations:
        summary: "MachineConfigPool {{ $labels.machine_config_pool }} is degraded"
        description: "MCP has degraded machines for more than 15 minutes"
    
    - alert: MCPUpdateStuck
      expr: mcp_machine_config_pool_updated_machine_count < mcp_machine_config_pool_machine_count
      for: 2h
      labels:
        severity: critical
      annotations:
        summary: "MachineConfigPool {{ $labels.machine_config_pool }} update stuck"
        description: "MCP has been updating for more than 2 hours"
```

### 5. Document Container Registry Requirements

Create a registry requirements document:

```markdown
# Container Registry Configuration

## Required Registries
- registry.redhat.io (Red Hat operators, images)
- registry.access.redhat.com (Red Hat base images)
- catalog.redhat.com (Red Hat operator catalogs)
- quay.io (Community operators)
- gcr.io (Google container registry)
- k8s.gcr.io (Kubernetes images)

## Signature Verification Requirements
- Red Hat registries MUST have signature verification enabled
- Use GPG key: /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
- Default policy: Accept signed images, reject unsigned

## Pull Secrets
- Red Hat pull secret required for registry.redhat.io
- Configured in install-config.yaml
- Updated via: oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=<path>
```

## Related Issues

- Image pull failures due to registry authentication: See `../api-slowness-web-console/`
- MCP stuck updating: See MCP troubleshooting sections
- Disconnected cluster image mirroring: See ImageContentSourcePolicy / ImageDigestMirrorSet configuration

## References

- [Red Hat KB: Container Image Signature Verification](https://access.redhat.com/articles/5131451)
- [OpenShift Documentation: Image Signature Verification](https://docs.openshift.com/container-platform/latest/security/container_security/security-container-signature.html)
- [containers-policy.json man page](https://github.com/containers/image/blob/main/docs/containers-policy.json.5.md)
- [Red Hat GPG Keys](https://access.redhat.com/security/team/key/)

## AI Disclosure

This troubleshooting guide was created with AI assistance and reviewed for technical accuracy. Last updated: 2026-02-10.

# ManagedServiceAccounts with RHACM

Create and manage ServiceAccounts on managed clusters with tokens automatically stored on the RHACM Hub cluster.

## Overview

`ManagedServiceAccount` (MSA) is an RHACM feature that:

1. Creates a ServiceAccount on a managed cluster
2. Generates and retrieves the token
3. Stores the token as a Secret on the Hub cluster
4. Automatically rotates the token on schedule
5. Provides centralized access management

This is ideal for automation tools, CI/CD pipelines, and cross-cluster services that need to access managed clusters.

## Use Cases

- **CI/CD Pipeline Access** - Jenkins, Tekton, GitHub Actions accessing clusters
- **Automation Tools** - Ansible, Terraform, custom scripts
- **Monitoring/Observability** - External monitoring agents
- **Cross-cluster Services** - Hub-based services managing workloads
- **Emergency Access** - Break-glass credentials with controlled permissions

## Architecture

```
┌─────────────────────────────────────────────┐
│            RHACM Hub Cluster                │
│                                             │
│  ManagedServiceAccount CRD                  │
│         ↓                                   │
│  Token Secret (stored on Hub)               │
│         ↓                                   │
│  Use token to access managed cluster ────┐  │
└───────────────────────────────────────────┼──┘
                                            │
                                            │
┌───────────────────────────────────────────▼──┐
│         Managed Cluster                      │
│                                              │
│  ServiceAccount created                      │
│  RoleBinding applied (via Policy)            │
│  Token generated & rotated                   │
└──────────────────────────────────────────────┘
```

## How It Works

1. **Create MSA on Hub**: Define the ServiceAccount in the managed cluster's namespace
2. **RHACM Creates SA**: ServiceAccount created on the managed cluster
3. **Token Retrieved**: Token automatically retrieved and stored on Hub
4. **Apply RBAC**: Use Policy to grant permissions (Role/ClusterRole bindings)
5. **Use Token**: Automation uses token from Hub to access managed cluster

## Prerequisites

- RHACM 2.5+ (ManagedServiceAccount introduced in 2.5)
- Managed clusters connected and available
- RBAC permissions to create ManagedServiceAccount resources

## Quick Start

### 1. Create a ManagedServiceAccount

```bash
# Apply MSA for a specific cluster
oc apply -f basic-managed-service-account.yaml

# Wait for token to be created (~10-30 seconds)
oc get managedserviceaccount -n <cluster-name>
```

### 2. Grant Permissions via Policy

```bash
# Apply RBAC policy to grant permissions to the ServiceAccount
oc apply -f rbac-policy.yaml
oc apply -f placement-binding.yaml
```

### 3. Retrieve and Use the Token

```bash
# Get the token secret name
SECRET_NAME=$(oc get managedserviceaccount my-automation-sa \
  -n <cluster-name> \
  -o jsonpath='{.status.tokenSecretRef.name}')

# Extract the token
TOKEN=$(oc get secret $SECRET_NAME -n <cluster-name> \
  -o jsonpath='{.data.token}' | base64 -d)

# Use the token to access the managed cluster
CLUSTER_API=$(oc get managedcluster <cluster-name> \
  -o jsonpath='{.spec.managedClusterClientConfigs[0].url}')

oc --token="$TOKEN" --server="$CLUSTER_API" get nodes
```

## Example Configurations

### Example 1: Basic Read-Only Access

Create a ServiceAccount with read-only cluster access:

```yaml
# basic-managed-service-account.yaml
apiVersion: authentication.open-cluster-management.io/v1alpha1
kind: ManagedServiceAccount
metadata:
  name: readonly-automation
  namespace: prod-cluster-1  # Managed cluster namespace on Hub
spec:
  rotation: {}  # Enable automatic token rotation
```

Then grant view permissions:

```yaml
# rbac-readonly-policy.yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: msa-readonly-rbac
  namespace: rhacm-policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: grant-readonly-access
      spec:
        remediationAction: enforce
        severity: medium
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: rbac.authorization.k8s.io/v1
            kind: ClusterRoleBinding
            metadata:
              name: readonly-automation-binding
            roleRef:
              apiGroup: rbac.authorization.k8s.io
              kind: ClusterRole
              name: view  # Built-in read-only role
            subjects:
            - kind: ServiceAccount
              name: readonly-automation
              namespace: open-cluster-management-managed-serviceaccount
```

### Example 2: Namespace-Scoped Deployment Access

ServiceAccount that can manage deployments in specific namespace:

```yaml
apiVersion: authentication.open-cluster-management.io/v1alpha1
kind: ManagedServiceAccount
metadata:
  name: app-deployer
  namespace: prod-cluster-1
spec:
  rotation:
    enabled: true
    validity: 720h  # 30 days
---
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: msa-deployer-rbac
  namespace: rhacm-policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: create-deployer-role
      spec:
        remediationAction: enforce
        severity: medium
        object-templates:
        # Create a custom Role
        - complianceType: musthave
          objectDefinition:
            apiVersion: rbac.authorization.k8s.io/v1
            kind: Role
            metadata:
              name: deployment-manager
              namespace: production-apps
            rules:
            - apiGroups: ["apps"]
              resources: ["deployments", "replicasets"]
              verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
            - apiGroups: [""]
              resources: ["pods", "services"]
              verbs: ["get", "list", "watch"]
        # Bind the Role to the ServiceAccount
        - complianceType: musthave
          objectDefinition:
            apiVersion: rbac.authorization.k8s.io/v1
            kind: RoleBinding
            metadata:
              name: app-deployer-binding
              namespace: production-apps
            roleRef:
              apiGroup: rbac.authorization.k8s.io
              kind: Role
              name: deployment-manager
            subjects:
            - kind: ServiceAccount
              name: app-deployer
              namespace: open-cluster-management-managed-serviceaccount
```

### Example 3: CI/CD Pipeline Access

ServiceAccount for CI/CD with specific permissions:

```yaml
apiVersion: authentication.open-cluster-management.io/v1alpha1
kind: ManagedServiceAccount
metadata:
  name: cicd-pipeline
  namespace: prod-cluster-1
  annotations:
    purpose: "GitHub Actions deployment pipeline"
    team: "platform-engineering"
spec:
  rotation:
    enabled: true
    validity: 2160h  # 90 days
---
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: msa-cicd-rbac
  namespace: rhacm-policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: cicd-custom-role
      spec:
        remediationAction: enforce
        severity: high
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: rbac.authorization.k8s.io/v1
            kind: ClusterRole
            metadata:
              name: cicd-deployer
            rules:
            # Deployments and StatefulSets
            - apiGroups: ["apps"]
              resources: ["deployments", "statefulsets", "daemonsets"]
              verbs: ["get", "list", "watch", "create", "update", "patch"]
            # Services and ConfigMaps
            - apiGroups: [""]
              resources: ["services", "configmaps", "secrets"]
              verbs: ["get", "list", "watch", "create", "update", "patch"]
            # Read-only access to pods and logs
            - apiGroups: [""]
              resources: ["pods", "pods/log"]
              verbs: ["get", "list", "watch"]
            # Ingress/Routes for OpenShift
            - apiGroups: ["route.openshift.io"]
              resources: ["routes"]
              verbs: ["get", "list", "watch", "create", "update", "patch"]
        - complianceType: musthave
          objectDefinition:
            apiVersion: rbac.authorization.k8s.io/v1
            kind: ClusterRoleBinding
            metadata:
              name: cicd-pipeline-binding
            roleRef:
              apiGroup: rbac.authorization.k8s.io
              kind: ClusterRole
              name: cicd-deployer
            subjects:
            - kind: ServiceAccount
              name: cicd-pipeline
              namespace: open-cluster-management-managed-serviceaccount
```

## Token Rotation

### Automatic Rotation

```yaml
spec:
  rotation:
    enabled: true
    validity: 8760h  # 1 year
```

When enabled:
- RHACM monitors token expiration
- Generates new token before expiration
- Updates the secret on the Hub
- Old token remains valid until expiration

### Manual Rotation

Force immediate rotation by deleting the token secret:

```bash
SECRET_NAME=$(oc get managedserviceaccount my-sa \
  -n <cluster-name> \
  -o jsonpath='{.status.tokenSecretRef.name}')

oc delete secret $SECRET_NAME -n <cluster-name>

# RHACM will recreate it within ~30 seconds
```

## Validation

### Check MSA Status

```bash
# View ManagedServiceAccount
oc get managedserviceaccount -n <cluster-name>

# Detailed status
oc get managedserviceaccount <msa-name> -n <cluster-name> -o yaml

# Look for:
# status.conditions - Should show "Ready"
# status.tokenSecretRef.name - Name of the secret containing token
# status.expirationTimestamp - When token expires
```

### Verify ServiceAccount on Managed Cluster

```bash
# Check ServiceAccount exists
oc --context=<cluster-name> get sa \
  -n open-cluster-management-managed-serviceaccount

# Check RBAC bindings
oc --context=<cluster-name> get clusterrolebinding | grep <sa-name>
```

### Test Token Access

```bash
# Extract token
TOKEN=$(oc get secret <secret-name> -n <cluster-name> \
  -o jsonpath='{.data.token}' | base64 -d)

# Get cluster API endpoint
CLUSTER_API=$(oc get managedcluster <cluster-name> \
  -o jsonpath='{.spec.managedClusterClientConfigs[0].url}')

# Test authentication
oc --token="$TOKEN" --server="$CLUSTER_API" --insecure-skip-tls-verify=true auth can-i get pods

# Test actual access
oc --token="$TOKEN" --server="$CLUSTER_API" --insecure-skip-tls-verify=true get nodes
```

## Integration Examples

### GitHub Actions

```yaml
# .github/workflows/deploy.yaml
name: Deploy to Cluster
on: [push]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Install OpenShift CLI
      run: |
        curl -LO https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz
        tar xzf oc.tar.gz && sudo mv oc /usr/local/bin/
    
    - name: Deploy to Cluster
      env:
        CLUSTER_TOKEN: ${{ secrets.MANAGED_CLUSTER_TOKEN }}
        CLUSTER_API: ${{ secrets.MANAGED_CLUSTER_API }}
      run: |
        oc --token="$CLUSTER_TOKEN" \
           --server="$CLUSTER_API" \
           --insecure-skip-tls-verify=true \
           apply -f manifests/
```

Store the token in GitHub Secrets:
```bash
# Extract token
TOKEN=$(oc get secret <secret-name> -n <cluster-name> \
  -o jsonpath='{.data.token}' | base64 -d)

# Add to GitHub repo secrets
gh secret set MANAGED_CLUSTER_TOKEN --body "$TOKEN"
```

### Ansible Integration

```yaml
# inventory.yml
all:
  children:
    managed_clusters:
      hosts:
        prod-cluster-1:
          ansible_connection: local
          k8s_auth:
            api_key: "{{ lookup('env', 'CLUSTER_TOKEN') }}"
            host: "{{ lookup('env', 'CLUSTER_API') }}"
            validate_certs: false

# playbook.yml
- name: Deploy application
  hosts: managed_clusters
  tasks:
  - name: Apply manifests
    kubernetes.core.k8s:
      state: present
      definition: "{{ lookup('file', 'app-deployment.yaml') | from_yaml }}"
      api_key: "{{ k8s_auth.api_key }}"
      host: "{{ k8s_auth.host }}"
      validate_certs: "{{ k8s_auth.validate_certs }}"
```

### Terraform

```hcl
# Configure Kubernetes provider with MSA token
provider "kubernetes" {
  host  = var.cluster_api
  token = var.cluster_token
  insecure = true  # Use proper CA cert in production
}

# Deploy resources
resource "kubernetes_deployment" "app" {
  metadata {
    name = "my-app"
    namespace = "production"
  }
  # ... deployment spec
}
```

## Security Best Practices

### 1. Principle of Least Privilege

Grant only the minimum permissions needed:

```yaml
# Bad: Cluster-admin access
roleRef:
  kind: ClusterRole
  name: cluster-admin  # Too permissive!

# Good: Specific permissions
roleRef:
  kind: Role
  name: deployment-manager  # Limited scope
```

### 2. Token Storage

- **Never commit tokens to Git**
- Store in secure secret managers (Vault, AWS Secrets Manager)
- Use CI/CD platform's secret storage
- Rotate regularly

### 3. Namespace Isolation

ServiceAccounts are created in `open-cluster-management-managed-serviceaccount` namespace by default. This namespace is managed by RHACM.

### 4. Audit Logging

Enable audit logging to track token usage:

```bash
# On managed cluster, check apiserver audit logs
oc logs -n openshift-kube-apiserver <apiserver-pod> | grep "authentication.k8s.io/serviceaccount"
```

### 5. Token Expiration

Set reasonable expiration periods:

```yaml
spec:
  rotation:
    validity: 720h  # 30 days - good balance
    # Not: 87600h (10 years) - too long!
```

## Troubleshooting

### MSA Not Creating Token

```bash
# Check MSA status
oc get managedserviceaccount <name> -n <cluster-namespace> -o yaml

# Look for errors in status.conditions
# Common issues:
# - Cluster not available
# - RBAC permissions issue on managed cluster
# - ManagedServiceAccount addon not enabled
```

### "Unauthorized" When Using Token

```bash
# Check if ServiceAccount has permissions
oc --context=<cluster-name> auth can-i <verb> <resource> \
  --as=system:serviceaccount:open-cluster-management-managed-serviceaccount:<sa-name>

# Example:
oc --context=<cluster-name> auth can-i get pods \
  --as=system:serviceaccount:open-cluster-management-managed-serviceaccount:cicd-pipeline
```

### Token Expired

```bash
# Check expiration
oc get managedserviceaccount <name> -n <cluster-namespace> \
  -o jsonpath='{.status.expirationTimestamp}'

# Force rotation (delete secret)
oc delete secret <token-secret> -n <cluster-namespace>
```

## Advanced Usage

### Multi-Cluster Deployment Script

```bash
#!/bin/bash
# deploy-to-all-clusters.sh

HUB_NAMESPACE="rhacm-policies"

# Get all managed clusters
CLUSTERS=$(oc get managedcluster -o jsonpath='{.items[*].metadata.name}')

for cluster in $CLUSTERS; do
  if [ "$cluster" = "local-cluster" ]; then
    continue
  fi
  
  echo "Deploying to $cluster..."
  
  # Get MSA token
  SECRET_NAME=$(oc get managedserviceaccount cicd-pipeline \
    -n $cluster \
    -o jsonpath='{.status.tokenSecretRef.name}')
  
  TOKEN=$(oc get secret $SECRET_NAME -n $cluster \
    -o jsonpath='{.data.token}' | base64 -d)
  
  # Get cluster API
  CLUSTER_API=$(oc get managedcluster $cluster \
    -o jsonpath='{.spec.managedClusterClientConfigs[0].url}')
  
  # Deploy
  oc --token="$TOKEN" \
     --server="$CLUSTER_API" \
     --insecure-skip-tls-verify=true \
     apply -f manifests/
  
  echo "✓ Deployed to $cluster"
done
```

## Next Steps

- [Example 3: External Secrets Operator](../3_external_secrets_operator/) - Production secret management
- [Example 4: Registry Credentials](../4_registry_credentials/) - Practical registry secret distribution
- [Example 6: Advanced Patterns](../6_advanced_patterns/) - Complex scenarios

## References

- [ManagedServiceAccount API Reference](https://github.com/stolostron/managed-serviceaccount)
- [RHACM Authentication Documentation](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/)
- [Kubernetes ServiceAccount Documentation](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)


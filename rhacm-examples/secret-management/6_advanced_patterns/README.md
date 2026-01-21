# Advanced Secret Management Patterns with RHACM

Advanced patterns and best practices for complex secret management scenarios.

## Overview

This section covers:
- **Hub Secret References** - Load secrets from Hub into policies
- **Conditional Secret Distribution** - Different secrets based on cluster labels
- **Secret Rotation Strategies** - Automated rotation workflows
- **Multi-Source Secrets** - Combining secrets from multiple sources
- **Secret Templates** - Dynamic secret generation

## Pattern 1: Hub Secret References

### Overview

Instead of hardcoding secrets in policies, reference secrets stored on the Hub cluster using the `fromSecret` template function.

**Requirements:**
- RHACM 2.8+ (for `fromSecret` function)
- Secret must exist in the Hub cluster
- RBAC permissions to read the Hub secret

### Syntax

```yaml
'{{hub fromSecret "namespace" "secret-name" "key" hub}}'
```

### Example 1: Basic Hub Secret Reference

**Step 1: Create secret on Hub cluster**
```bash
# Create a namespace for sensitive data
oc create namespace rhacm-secrets

# Create the secret on Hub
oc create secret generic database-master-password \
  -n rhacm-secrets \
  --from-literal=password='SuperSecretP@ssw0rd123' \
  --from-literal=username='app_admin'
```

**Step 2: Reference in policy**
```yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: database-secret-from-hub
  namespace: rhacm-policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: create-db-secret
      spec:
        remediationAction: enforce
        severity: high
        namespaceSelector:
          include:
          - production-apps
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: Secret
            metadata:
              name: database-credentials
              namespace: production-apps
            type: Opaque
            stringData:
              # Reference secrets from Hub cluster
              username: '{{hub fromSecret "rhacm-secrets" "database-master-password" "username" hub}}'
              password: '{{hub fromSecret "rhacm-secrets" "database-master-password" "password" hub}}'
              host: "postgres-prod.example.com"
              port: "5432"
```

### Example 2: Registry Credentials from Hub

**Step 1: Create registry secret on Hub**
```bash
# Create docker registry secret on Hub
kubectl create secret docker-registry hub-registry-credentials \
  -n rhacm-secrets \
  --docker-server=quay.io \
  --docker-username=my-user \
  --docker-password=my-token \
  --docker-email=user@example.com
```

**Step 2: Distribute to managed clusters**
```yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: registry-creds-from-hub
  namespace: rhacm-policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: distribute-registry-secret
      spec:
        remediationAction: enforce
        severity: high
        namespaceSelector:
          include:
          - production-apps
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: Secret
            metadata:
              name: registry-credentials
              namespace: production-apps
            type: kubernetes.io/dockerconfigjson
            data:
              # Reference the entire dockerconfigjson from Hub
              .dockerconfigjson: '{{hub fromSecret "rhacm-secrets" "hub-registry-credentials" ".dockerconfigjson" hub}}'
```

### Example 3: TLS Certificates from Hub

```yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: tls-cert-from-hub
  namespace: rhacm-policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: distribute-tls-cert
      spec:
        remediationAction: enforce
        severity: high
        namespaceSelector:
          include:
          - production-apps
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: Secret
            metadata:
              name: app-tls-certificate
              namespace: production-apps
            type: kubernetes.io/tls
            data:
              tls.crt: '{{hub fromSecret "rhacm-secrets" "wildcard-tls-cert" "tls.crt" hub}}'
              tls.key: '{{hub fromSecret "rhacm-secrets" "wildcard-tls-cert" "tls.key" hub}}'
```

## Pattern 2: Conditional Secret Distribution

Distribute different secrets based on cluster labels or properties.

### Example: Environment-Specific Secrets

```yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: environment-specific-secrets
  namespace: rhacm-policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: conditional-db-secret
      spec:
        remediationAction: enforce
        severity: high
        namespaceSelector:
          include:
          - my-app
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: Secret
            metadata:
              name: database-credentials
              namespace: my-app
            type: Opaque
            stringData:
              # Use different Hub secrets based on cluster label
              username: '{{hub fromSecret "rhacm-secrets" (printf "%s-db-creds" (index (lookup "cluster.open-cluster-management.io/v1" "ManagedCluster" "" "").metadata.labels "environment")) "username" hub}}'
              password: '{{hub fromSecret "rhacm-secrets" (printf "%s-db-creds" (index (lookup "cluster.open-cluster-management.io/v1" "ManagedCluster" "" "").metadata.labels "environment")) "password" hub}}'
              # Result: production-db-creds, staging-db-creds, etc.
```

This requires creating Hub secrets like:
```bash
oc create secret generic production-db-creds -n rhacm-secrets \
  --from-literal=username=prod_user \
  --from-literal=password=prod_pass

oc create secret generic staging-db-creds -n rhacm-secrets \
  --from-literal=username=staging_user \
  --from-literal=password=staging_pass
```

## Pattern 3: Secret Rotation Strategy

### Manual Rotation Process

1. **Update Hub Secret**
```bash
# Update the master secret on Hub
oc create secret generic database-master-password \
  -n rhacm-secrets \
  --from-literal=username='app_admin' \
  --from-literal=password='NewSecretP@ssw0rd456' \
  --dry-run=client -o yaml | oc apply -f -
```

2. **Trigger Policy Reevaluation**
```bash
# Add annotation to force policy update
oc annotate policy database-secret-from-hub \
  -n rhacm-policies \
  policy.open-cluster-management.io/trigger-update="$(date +%s)"
```

3. **Verify Distribution**
```bash
# Check policy compliance
oc get policy database-secret-from-hub -n rhacm-policies

# Verify on managed cluster
oc --context=managed-cluster get secret database-credentials \
  -n production-apps -o yaml
```

### Automated Rotation with External Secrets Operator

For production, use ESO with dynamic secrets:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: rotated-credentials
  namespace: production-apps
spec:
  refreshInterval: 1h  # Auto-refresh every hour
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: database-credentials
    creationPolicy: Owner
  data:
  - secretKey: password
    remoteRef:
      key: database/creds/dynamic-role  # Vault dynamic secret
      property: password
```

## Pattern 4: Multi-Source Secret Composition

Combine secrets from multiple sources into one secret.

```yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: multi-source-secret
  namespace: rhacm-policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: composite-secret
      spec:
        remediationAction: enforce
        severity: high
        namespaceSelector:
          include:
          - production-apps
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: Secret
            metadata:
              name: application-config
              namespace: production-apps
            type: Opaque
            stringData:
              # Database credentials from one Hub secret
              db-username: '{{hub fromSecret "rhacm-secrets" "database-creds" "username" hub}}'
              db-password: '{{hub fromSecret "rhacm-secrets" "database-creds" "password" hub}}'
              
              # API keys from another Hub secret
              api-key: '{{hub fromSecret "rhacm-secrets" "api-keys" "primary" hub}}'
              api-secret: '{{hub fromSecret "rhacm-secrets" "api-keys" "secret" hub}}'
              
              # TLS cert from third Hub secret
              tls-cert: '{{hub fromSecret "rhacm-secrets" "tls-cert" "tls.crt" hub}}'
              
              # Static values
              environment: "production"
              log-level: "info"
```

## Pattern 5: Secret Templates with Dynamic Values

Generate secrets with dynamic values using hub templates.

```yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: templated-secret
  namespace: rhacm-policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: dynamic-secret
      spec:
        remediationAction: enforce
        severity: medium
        namespaceSelector:
          include:
          - production-apps
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: Secret
            metadata:
              name: app-config
              namespace: production-apps
              labels:
                cluster: '{{hub (index (lookup "cluster.open-cluster-management.io/v1" "ManagedCluster" "" "").metadata.labels "name") hub}}'
            type: Opaque
            stringData:
              # Cluster-specific configuration
              cluster-name: '{{hub (index (lookup "cluster.open-cluster-management.io/v1" "ManagedCluster" "" "").metadata.labels "name") hub}}'
              cluster-region: '{{hub (index (lookup "cluster.open-cluster-management.io/v1" "ManagedCluster" "" "").metadata.labels "region") hub}}'
              
              # Credentials from Hub
              api-token: '{{hub fromSecret "rhacm-secrets" "api-tokens" "token" hub}}'
              
              # Generate connection string with cluster-specific values
              service-url: 'https://api-{{hub (index (lookup "cluster.open-cluster-management.io/v1" "ManagedCluster" "" "").metadata.labels "name") hub}}.example.com'
```

## RBAC for Hub Secrets

Grant RHACM permission to read Hub secrets.

**Universal Approach (Recommended):**

```bash
# Works for all RHACM versions
oc adm policy add-role-to-group view \
  system:serviceaccounts:open-cluster-management \
  -n rhacm-secrets
```

**Or use the setup script:**

```bash
./setup-hub-secret-rbac.sh rhacm-secrets
```

**Alternative - Specific ServiceAccount (if needed):**

The ServiceAccount name varies by RHACM version:
- RHACM 2.6-2.8: `governance-policy-propagator`
- RHACM 2.9-2.11: `governance-policy-framework`
- RHACM 2.12+: `governance-policy-addon-controller` (may vary)

Use `./verify-serviceaccount.sh` to identify your specific ServiceAccount, then:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: rhacm-secret-reader
  namespace: rhacm-secrets
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view
subjects:
# Universal approach - all ServiceAccounts in namespace
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:serviceaccounts:open-cluster-management
```

## Security Best Practices

### 1. Separate Namespace for Hub Secrets

```bash
# Create dedicated namespace
oc create namespace rhacm-secrets

# Apply strict RBAC
oc adm policy add-role-to-user view system:serviceaccount:open-cluster-management:governance-policy-propagator -n rhacm-secrets
```

### 2. Encrypt Hub Secrets at Rest

```bash
# Verify etcd encryption is enabled
oc get apiserver cluster -o yaml | grep encryption

# Enable if not already
oc patch apiserver cluster --type=merge \
  -p '{"spec":{"encryption":{"type":"aescbc"}}}'
```

### 3. Audit Secret Access

```bash
# Check who can view secrets in rhacm-secrets namespace
oc adm policy who-can get secrets -n rhacm-secrets

# Review audit logs
oc adm node-logs --role=master --path=kube-apiserver/audit.log \
  | grep '"namespace":"rhacm-secrets"'
```

### 4. Secret Versioning

Keep track of secret changes:

```bash
# Add version label when updating
oc label secret database-master-password \
  -n rhacm-secrets \
  version=v2 --overwrite

# Add change annotation
oc annotate secret database-master-password \
  -n rhacm-secrets \
  last-rotated="$(date -Iseconds)" --overwrite
```

## Troubleshooting

### fromSecret Not Working

```bash
# Check RHACM version (need 2.8+)
oc get multiclusterhub -n open-cluster-management -o yaml | grep currentVersion

# Check if secret exists on Hub
oc get secret -n rhacm-secrets

# Check RBAC permissions
oc get rolebinding -n rhacm-secrets | grep open-cluster-management

# Verify ServiceAccount (run helper script)
./verify-serviceaccount.sh
```

### Policy Shows "Template Error"

```bash
# View policy status
oc get policy <policy-name> -n rhacm-policies -o yaml

# Common issues:
# - Incorrect namespace name
# - Incorrect secret name
# - Incorrect key name
# - Missing quotes around template

# Test template syntax
# The template must be within single quotes
stringData:
  password: '{{hub fromSecret "namespace" "secret" "key" hub}}'
```

### Secret Not Updating on Managed Cluster

```bash
# Force policy reevaluation
oc annotate policy <policy-name> -n rhacm-policies \
  policy.open-cluster-management.io/trigger-update="$(date +%s)"

# Check ManifestWork
oc get manifestwork -n <cluster-namespace>

# Delete and let it recreate
oc delete manifestwork <manifestwork-name> -n <cluster-namespace>
```

## Complete Working Example

Here's a complete end-to-end example:

```bash
# 1. Create Hub secret namespace
oc create namespace rhacm-secrets

# 2. Create secrets on Hub
oc create secret generic prod-database \
  -n rhacm-secrets \
  --from-literal=username=prod_admin \
  --from-literal=password='P@ssw0rd123' \
  --from-literal=host=postgres-prod.example.com

oc create secret generic prod-api-keys \
  -n rhacm-secrets \
  --from-literal=api-key='ak_prod_123456' \
  --from-literal=api-secret='as_prod_secret789'

# 3. Apply policy
cat <<EOF | oc apply -f -
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: production-app-secrets
  namespace: rhacm-policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: app-secrets-from-hub
      spec:
        remediationAction: enforce
        severity: high
        namespaceSelector:
          include:
          - production-apps
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: Secret
            metadata:
              name: application-secrets
              namespace: production-apps
            type: Opaque
            stringData:
              DB_USERNAME: '{{hub fromSecret "rhacm-secrets" "prod-database" "username" hub}}'
              DB_PASSWORD: '{{hub fromSecret "rhacm-secrets" "prod-database" "password" hub}}'
              DB_HOST: '{{hub fromSecret "rhacm-secrets" "prod-database" "host" hub}}'
              API_KEY: '{{hub fromSecret "rhacm-secrets" "prod-api-keys" "api-key" hub}}'
              API_SECRET: '{{hub fromSecret "rhacm-secrets" "prod-api-keys" "api-secret" hub}}'
              DATABASE_URL: 'postgresql://{{hub fromSecret "rhacm-secrets" "prod-database" "username" hub}}:{{hub fromSecret "rhacm-secrets" "prod-database" "password" hub}}@{{hub fromSecret "rhacm-secrets" "prod-database" "host" hub}}:5432/myapp'
EOF

# 4. Create PlacementRule and PlacementBinding
cat <<EOF | oc apply -f -
apiVersion: apps.open-cluster-management.io/v1
kind: PlacementRule
metadata:
  name: production-clusters
  namespace: rhacm-policies
spec:
  clusterSelector:
    matchLabels:
      environment: production
---
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  name: bind-prod-secrets
  namespace: rhacm-policies
placementRef:
  name: production-clusters
  kind: PlacementRule
subjects:
- name: production-app-secrets
  kind: Policy
EOF
```

## Additional Examples

- **[copysecretdata-examples.yaml](./copysecretdata-examples.yaml)** - 10 examples using copySecretData
- **[placement-by-labels.yaml](./placement-by-labels.yaml)** - 10 examples filtering clusters by labels
- **[COPYSECRETDATA-VS-FROMSECRET.md](./COPYSECRETDATA-VS-FROMSECRET.md)** - Complete comparison guide

## References

- [RHACM Policy Templates](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.11/html/governance/governance#template-functions)
- [Hub Template Functions](https://github.com/stolostron/go-template-utils)
- [Policy Collection Examples](https://github.com/stolostron/policy-collection)


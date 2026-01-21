# External Secrets Operator Integration with RHACM

Deploy and manage External Secrets Operator (ESO) across multiple clusters using RHACM, enabling secure secret synchronization from external stores like Vault, AWS Secrets Manager, and Azure Key Vault.

## Overview

External Secrets Operator (ESO) extends Kubernetes with Custom Resources to synchronize secrets from external secret management systems:

- **Centralized Secret Management** - Secrets stored in external systems (Vault, AWS SM, GCP SM, Azure KV)
- **Automatic Synchronization** - Secrets automatically sync to Kubernetes
- **Secret Rotation** - Supports automatic rotation and refresh
- **Audit Trail** - External stores provide detailed audit logs
- **Access Control** - Fine-grained permissions via external store

## Architecture

```
┌─────────────────────────────────────────────┐
│          RHACM Hub Cluster                  │
│                                             │
│  Policies:                                  │
│  ├── Install ESO Operator                   │
│  ├── Configure SecretStore                  │
│  └── Create ExternalSecret                  │
│                                             │
└──────────────┬──────────────────────────────┘
               │
               │ Distributes to
               │
    ┌──────────┴──────────┐
    │                     │
┌───▼──────────┐    ┌────▼─────────┐
│  Cluster 1   │    │  Cluster 2   │
│              │    │              │
│  ESO         │    │  ESO         │
│  SecretStore │    │  SecretStore │
│  ↓           │    │  ↓           │
└──┼───────────┘    └──┼───────────┘
   │                   │
   │ Pull secrets      │
   │                   │
┌──▼───────────────────▼──┐
│  External Secret Store  │
│  (Vault / AWS / Azure)  │
└─────────────────────────┘
```

## Use Cases

- **Production Application Secrets** - Database credentials, API keys
- **Multi-Environment Deployments** - Different secrets per environment
- **Compliance Requirements** - Audit trails and access control
- **Dynamic Secrets** - Vault dynamic database credentials
- **Certificate Management** - TLS certificates from external CA

## Prerequisites

- RHACM Hub with managed clusters
- External secret store (Vault, AWS Secrets Manager, etc.)
- Authentication configured (IAM roles, service accounts, tokens)
- Network connectivity from managed clusters to secret store

## Supported Secret Stores

| Provider | Authentication Methods | Notes |
|----------|----------------------|-------|
| **HashiCorp Vault** | Token, AppRole, Kubernetes, JWT | Most feature-rich |
| **AWS Secrets Manager** | IAM Role, Access Key | IRSA recommended |
| **AWS Parameter Store** | IAM Role, Access Key | Lower cost than SM |
| **Azure Key Vault** | Managed Identity, Service Principal | AAD Pod Identity |
| **Google Secret Manager** | Workload Identity, Service Account | GKE recommended |
| **Doppler** | Token | Simple API-based |

## Quick Start

### 1. Install ESO Operator on Managed Clusters

```bash
# Apply policy to install ESO
oc apply -f install-eso-operator-policy.yaml
oc apply -f placement-all-clusters.yaml
oc apply -f placement-binding.yaml

# Wait for compliance
oc get policy install-external-secrets-operator -n rhacm-policies -w
```

### 2. Configure SecretStore

```bash
# For Vault example
oc apply -f vault-secretstore-policy.yaml

# For AWS Secrets Manager example
oc apply -f aws-secretstore-policy.yaml
```

### 3. Create ExternalSecret

```bash
# Create ExternalSecret to sync specific secrets
oc apply -f database-external-secret-policy.yaml

# Verify secret created on managed cluster
oc --context=<cluster-name> get secret database-credentials -n my-app
```

## Example Configurations

### Example 1: HashiCorp Vault Integration

Install ESO and configure Vault backend:

```yaml
# vault-secretstore-policy.yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: vault-secretstore-config
  namespace: rhacm-policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  # Create namespace for app
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: create-app-namespace
      spec:
        remediationAction: enforce
        severity: low
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: Namespace
            metadata:
              name: my-app
  
  # Create Vault token secret
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: create-vault-token
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
              name: vault-token
              namespace: my-app
            type: Opaque
            stringData:
              token: "hvs.XXXXXXXXXXXXXXX"  # Use real token or reference Hub secret
  
  # Configure SecretStore
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: configure-vault-secretstore
      spec:
        remediationAction: enforce
        severity: high
        namespaceSelector:
          include:
          - my-app
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: external-secrets.io/v1beta1
            kind: SecretStore
            metadata:
              name: vault-backend
              namespace: my-app
            spec:
              provider:
                vault:
                  server: "https://vault.example.com:8200"
                  path: "secret"
                  version: "v2"
                  auth:
                    tokenSecretRef:
                      name: vault-token
                      key: token
```

Create an ExternalSecret:

```yaml
# vault-external-secret-policy.yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: vault-database-secret
  namespace: rhacm-policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: sync-database-credentials
      spec:
        remediationAction: enforce
        severity: high
        namespaceSelector:
          include:
          - my-app
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: external-secrets.io/v1beta1
            kind: ExternalSecret
            metadata:
              name: database-credentials
              namespace: my-app
            spec:
              refreshInterval: 1h
              secretStoreRef:
                name: vault-backend
                kind: SecretStore
              target:
                name: database-credentials
                creationPolicy: Owner
                template:
                  engineVersion: v2
                  data:
                    # Template the secret format
                    DATABASE_URL: "postgresql://{{ .username }}:{{ .password }}@postgres.example.com:5432/myapp"
              data:
              - secretKey: username
                remoteRef:
                  key: database/production
                  property: username
              - secretKey: password
                remoteRef:
                  key: database/production
                  property: password
```

### Example 2: AWS Secrets Manager with IRSA

Use IAM Roles for Service Accounts (IRSA) for secure AWS authentication:

```yaml
# aws-secretstore-policy.yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: aws-secretstore-config
  namespace: rhacm-policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: create-app-namespace
      spec:
        remediationAction: enforce
        severity: low
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: Namespace
            metadata:
              name: my-app
  
  # Create ServiceAccount with IAM role annotation (for EKS/ROSA)
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: create-eso-serviceaccount
      spec:
        remediationAction: enforce
        severity: medium
        namespaceSelector:
          include:
          - my-app
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: ServiceAccount
            metadata:
              name: external-secrets
              namespace: my-app
              annotations:
                eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/external-secrets-role"
  
  # Configure ClusterSecretStore (cluster-wide)
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: configure-aws-cluster-secretstore
      spec:
        remediationAction: enforce
        severity: high
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: external-secrets.io/v1beta1
            kind: ClusterSecretStore
            metadata:
              name: aws-secrets-manager
            spec:
              provider:
                aws:
                  service: SecretsManager
                  region: us-east-1
                  auth:
                    jwt:
                      serviceAccountRef:
                        name: external-secrets
                        namespace: my-app
```

ExternalSecret using AWS:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-config
  namespace: my-app
spec:
  refreshInterval: 15m
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: app-config
    creationPolicy: Owner
  dataFrom:
  - extract:
      key: prod/my-app/config  # AWS Secret name
```

### Example 3: Azure Key Vault with Managed Identity

```yaml
# azure-secretstore-policy.yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: azure-keyvault-config
  namespace: rhacm-policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: configure-azure-secretstore
      spec:
        remediationAction: enforce
        severity: high
        namespaceSelector:
          include:
          - my-app
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: external-secrets.io/v1beta1
            kind: SecretStore
            metadata:
              name: azure-keyvault
              namespace: my-app
            spec:
              provider:
                azurekv:
                  authType: ManagedIdentity
                  vaultUrl: "https://my-keyvault.vault.azure.net"
                  identityId: "00000000-0000-0000-0000-000000000000"  # Client ID
```

## Secret Templating

ESO supports templating to transform secret data:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: templated-secret
  namespace: my-app
spec:
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: app-config
    creationPolicy: Owner
    template:
      engineVersion: v2
      data:
        # Create connection string from individual fields
        DATABASE_URL: "postgresql://{{ .db_username }}:{{ .db_password }}@{{ .db_host }}:5432/{{ .db_name }}"
        
        # Create config file
        config.yaml: |
          database:
            host: {{ .db_host }}
            username: {{ .db_username }}
            password: {{ .db_password }}
          redis:
            url: {{ .redis_url }}
  data:
  - secretKey: db_username
    remoteRef:
      key: database/prod
      property: username
  - secretKey: db_password
    remoteRef:
      key: database/prod
      property: password
  - secretKey: db_host
    remoteRef:
      key: database/prod
      property: host
  - secretKey: db_name
    remoteRef:
      key: database/prod
      property: name
  - secretKey: redis_url
    remoteRef:
      key: cache/prod
      property: url
```

## Validation

### Verify ESO Installation

```bash
# Check operator is installed
oc --context=<cluster-name> get csv -n openshift-operators | grep external-secrets

# Check ESO pods running
oc --context=<cluster-name> get pods -n openshift-operators | grep external-secrets

# Check CRDs installed
oc --context=<cluster-name> get crd | grep external-secrets.io
```

### Verify SecretStore

```bash
# Check SecretStore/ClusterSecretStore
oc --context=<cluster-name> get secretstore -A
oc --context=<cluster-name> get clustersecretstore

# Check SecretStore status
oc --context=<cluster-name> get secretstore vault-backend -n my-app -o yaml

# Look for:
# status.conditions - Should show "Ready: True"
```

### Verify ExternalSecret Sync

```bash
# Check ExternalSecret status
oc --context=<cluster-name> get externalsecret -n my-app

# Should show READY: True, STATUS: SecretSynced

# View details
oc --context=<cluster-name> describe externalsecret database-credentials -n my-app

# Check generated Kubernetes secret
oc --context=<cluster-name> get secret database-credentials -n my-app -o yaml

# Verify secret data
oc --context=<cluster-name> get secret database-credentials -n my-app \
  -o jsonpath='{.data.username}' | base64 -d
```

## Troubleshooting

### ExternalSecret Not Syncing

```bash
# Check ExternalSecret events
oc --context=<cluster-name> describe externalsecret <name> -n <namespace>

# Common issues:
# - "SecretStore not found" - SecretStore not created yet
# - "Authentication failed" - Invalid credentials
# - "Secret not found" - Path doesn't exist in external store
# - "Permission denied" - Insufficient IAM/RBAC permissions

# Check ESO controller logs
oc --context=<cluster-name> logs -n openshift-operators \
  -l app.kubernetes.io/name=external-secrets -f
```

### SecretStore Not Ready

```bash
# Check SecretStore conditions
oc --context=<cluster-name> get secretstore <name> -n <namespace> -o yaml

# Test authentication manually
# For Vault:
curl -H "X-Vault-Token: $TOKEN" https://vault.example.com:8200/v1/secret/data/test

# For AWS:
aws secretsmanager get-secret-value --secret-id prod/my-app/config --region us-east-1
```

### Network Connectivity Issues

```bash
# Test connectivity from cluster to external store
oc --context=<cluster-name> run -it --rm debug \
  --image=curlimages/curl --restart=Never \
  -- curl -v https://vault.example.com:8200

# Check for proxy requirements, firewall rules, VPN
```

## Security Best Practices

### 1. Use IAM/Managed Identities

Prefer workload identity over static credentials:

- **AWS**: IAM Roles for Service Accounts (IRSA)
- **Azure**: Managed Identity / AAD Pod Identity
- **GCP**: Workload Identity
- **Vault**: Kubernetes auth method

### 2. Limit SecretStore Scope

Use namespace-scoped `SecretStore` instead of `ClusterSecretStore` when possible:

```yaml
kind: SecretStore  # Namespace-scoped
metadata:
  namespace: my-app
```

### 3. Implement RBAC

Restrict who can create ExternalSecrets:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: external-secret-creator
  namespace: my-app
rules:
- apiGroups: ["external-secrets.io"]
  resources: ["externalsecrets"]
  verbs: ["create", "update", "patch"]
```

### 4. Use Secret Rotation

```yaml
spec:
  refreshInterval: 1h  # Sync every hour
  target:
    creationPolicy: Owner  # ESO manages secret lifecycle
```

### 5. Monitor and Alert

- Monitor ExternalSecret sync status
- Alert on sync failures
- Track secret access in external store audit logs

## Advanced Patterns

### Multi-Source Secrets

Combine secrets from multiple sources:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: multi-source
  namespace: my-app
spec:
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: combined-config
  dataFrom:
  - extract:
      key: database/prod
  - extract:
      key: cache/prod
  - extract:
      key: api-keys/prod
```

### Environment-Specific Secrets

Use label selectors to distribute different secrets per environment:

```yaml
# Production clusters get production secrets
apiVersion: apps.open-cluster-management.io/v1
kind: PlacementRule
metadata:
  name: production-clusters
spec:
  clusterSelector:
    matchLabels:
      environment: production
---
# Policy references Vault path: secret/prod/...
```

## Next Steps

- [Example 4: Registry Credentials](../4_registry_credentials/) - Practical registry integration
- [Example 5: Database Secrets](../5_database_secrets/) - Complete database credential workflow
- [Example 6: Advanced Patterns](../6_advanced_patterns/) - Complex scenarios

## References

- [External Secrets Operator Documentation](https://external-secrets.io/)
- [ESO API Reference](https://external-secrets.io/latest/api/externalsecret/)
- [Provider Guides](https://external-secrets.io/latest/provider/aws-secrets-manager/)
- [RHACM Policy Collection](https://github.com/stolostron/policy-collection)


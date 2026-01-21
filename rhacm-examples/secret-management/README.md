# RHACM Secret Management

Complete examples for managing secrets across multiple Kubernetes clusters using Red Hat Advanced Cluster Management (RHACM).

## Overview

Managing secrets across multiple clusters is challenging. RHACM provides several approaches:

1. **Policy-Based Distribution** - Push secrets from Hub to managed clusters
2. **ManagedServiceAccounts** - Create cluster access credentials stored on Hub
3. **External Secrets Operator** - Sync from external secret stores (Vault, AWS SM, etc.)

## ⚠️ RHACM 2.15+ Compliance

**All examples use RHACM 2.15+ best practices:**

- ✅ `Placement` API (not deprecated `PlacementRule`)
- ✅ `ManagedClusterSet` for cluster grouping
- ✅ `ManagedClusterSetBinding` for namespace access
- ✅ Hub secret references via `fromSecret` template
- ✅ Tolerations for cluster unavailability

See [../RHACM-2.15-BEST-PRACTICES.md](../RHACM-2.15-BEST-PRACTICES.md) for details.

## When to Use Each Approach

| Approach | Best For | Pros | Cons |
|----------|----------|------|------|
| Policy-Based | Simple configs, registry creds, CA certs | Easy setup, Hub controlled | Secrets in Hub & spoke clusters |
| ManagedServiceAccount | Automation access, CI/CD | Token rotation, Hub storage | Access credentials only |
| External Secrets Operator | App secrets, production | Centralized store, audit trail | Additional infrastructure |

## Examples

### 1. Basic Secret Distribution
Learn the fundamentals of distributing secrets using RHACM Policies.

**Use Cases:**
- Distribute CA certificates
- Share configuration secrets
- Deploy namespace-scoped secrets

[View Example →](./1_basic_secret_distribution/)

### 2. ManagedServiceAccounts
Create and manage ServiceAccounts on remote clusters with tokens stored on the Hub.

**Use Cases:**
- CI/CD pipeline access
- Automation tooling credentials
- Cross-cluster service communication

[View Example →](./2_managed_service_accounts/)

### 3. External Secrets Operator Integration
Deploy and configure ESO across clusters to sync from external secret stores.

**Use Cases:**
- Production application secrets
- Database credentials
- API keys and tokens
- Certificate management

[View Example →](./3_external_secrets_operator/)

### 4. Registry Credentials
Practical example for distributing container registry pull secrets.

**Use Cases:**
- Private registry access
- Mirror registry credentials
- Multi-registry configurations

[View Example →](./4_registry_credentials/)

### 5. Database Secrets
Complete workflow for managing database credentials across environments.

**Use Cases:**
- PostgreSQL/MySQL credentials
- Connection strings
- Environment-specific configs

[View Example →](./5_database_secrets/)

### 6. Advanced Patterns
Complex scenarios and best practices.

**Patterns:**
- Secret rotation strategies
- Multi-environment deployments
- Conditional secret distribution
- Template-based secret generation

[View Example →](./6_advanced_patterns/)

## Quick Start

### Prerequisites

```bash
# Verify RHACM is installed
oc get multiclusterhub -n open-cluster-management

# List managed clusters
oc get managedclusters

# Verify policy framework
oc get crd policies.policy.open-cluster-management.io
```

### Basic Example

1. Create a namespace for policies:
```bash
oc create namespace rhacm-policies
```

2. Apply a basic secret distribution policy:
```bash
oc apply -f 1_basic_secret_distribution/simple-secret-policy.yaml
```

3. Verify distribution:
```bash
# Check policy compliance
oc get policies -A

# Check on managed cluster
oc --context=<managed-cluster> get secret -n target-namespace
```

## Architecture Patterns

### Hub-and-Spoke Model

```
┌─────────────────────────────────────────┐
│           RHACM Hub Cluster             │
│                                         │
│  ┌──────────────┐   ┌───────────────┐  │
│  │   Policies   │   │  Placements   │  │
│  └──────┬───────┘   └───────┬───────┘  │
│         │                   │          │
│         └───────┬───────────┘          │
└─────────────────┼──────────────────────┘
                  │
         ┌────────┴─────────┐
         │                  │
    ┌────▼─────┐      ┌────▼─────┐
    │ Cluster1 │      │ Cluster2 │
    │  (Prod)  │      │  (Dev)   │
    └──────────┘      └──────────┘
```

### Secret Flow Patterns

#### Pattern A: Direct Distribution
```
Hub Policy → Managed Cluster → Secret Created
```

#### Pattern B: External Store
```
Hub Policy → Install ESO → Managed Cluster
                ↓
         External Store (Vault) → ESO → Secret Created
```

## Security Best Practices

### 1. Encryption
```bash
# Enable etcd encryption on Hub and managed clusters
oc patch apiservers.config.openshift.io cluster \
  --type=merge \
  -p '{"spec":{"encryption":{"type":"aescbc"}}}'
```

### 2. RBAC Minimization
```yaml
# Only grant necessary permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: secret-reader
  namespace: app-namespace
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: app-namespace
roleRef:
  kind: Role
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

### 3. Secret Scanning
- Never commit secrets to Git
- Use `.gitignore` for sensitive files
- Scan commits with tools like `git-secrets`
- Use pre-commit hooks

### 4. Audit Logging
```bash
# Enable audit logging for secret access
oc get configmap -n openshift-kube-apiserver audit-policies -o yaml
```

## Troubleshooting

### Policy Not Compliant

```bash
# Check policy status
oc get policy <policy-name> -n <namespace> -o yaml

# View policy violations
oc describe policy <policy-name> -n <namespace>

# Check placement
oc get placementrule <placement-name> -n <namespace> -o yaml
```

### Secret Not Created on Managed Cluster

```bash
# Check ManifestWork (actual resource applied to cluster)
oc get manifestwork -n <managed-cluster-namespace>

# View ManifestWork details
oc get manifestwork -n <cluster-name> -o yaml

# Check cluster status
oc get managedcluster <cluster-name> -o yaml
```

### ManagedServiceAccount Issues

```bash
# Check MSA status
oc get managedserviceaccount -n <cluster-namespace>

# View token secret
oc get secret -n <cluster-namespace> | grep managed-sa

# Test token
TOKEN=$(oc get secret <secret-name> -n <cluster-namespace> -o jsonpath='{.data.token}' | base64 -d)
oc --token=$TOKEN get nodes
```

## Performance Considerations

- **Policy Evaluation**: Runs every 10 seconds by default
- **Large Scale**: Use `remediationAction: inform` first, then enforce
- **Secret Size**: Keep secrets small; use ConfigMaps for large configs
- **Placement**: Use efficient label selectors to minimize policy scope

## Testing

Each example includes validation steps. General testing approach:

```bash
# 1. Apply policy
oc apply -f <example>.yaml

# 2. Wait for compliance (may take up to 30 seconds)
oc get policy -w

# 3. Verify on managed cluster
oc --context=<managed-cluster> get secret -n <namespace>

# 4. Test application access
oc --context=<managed-cluster> create job test-secret \
  --image=busybox \
  --dry-run=client -o yaml -- sh -c 'echo $SECRET_VALUE'
```

## Additional Resources

- [RHACM Policy Collection (GitHub)](https://github.com/stolostron/policy-collection)
- [RHACM Governance Documentation](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.11/html/governance/index)
- [External Secrets Operator](https://external-secrets.io/)
- [Kubernetes Secrets Management Guide](https://kubernetes.io/docs/concepts/configuration/secret/)

## Detailed Guides

- **[NAMESPACE-SELECTOR-GUIDE.md](./NAMESPACE-SELECTOR-GUIDE.md)** - Complete guide to namespaceSelector usage
- **[MIGRATION-FROM-PLACEMENTRULE.md](./MIGRATION-FROM-PLACEMENTRULE.md)** - Migrate from PlacementRule to Placement
- **[../RHACM-2.15-BEST-PRACTICES.md](../RHACM-2.15-BEST-PRACTICES.md)** - RHACM 2.15+ best practices

## Related Examples

- [Ansible Examples](../../ansible-examples/) - Automate RHACM policy creation
- [Argo CD Examples](../../argo-examples/) - GitOps with RHACM


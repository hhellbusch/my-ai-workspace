# copySecretData vs fromSecret in RHACM

Complete comparison and usage guide for the two methods of referencing Hub secrets in RHACM policies.

## Overview

RHACM provides two ways to use secrets from the Hub cluster in policies:

1. **`copySecretData`** - ConfigurationPolicy field that copies entire secrets
2. **`fromSecret`** - Template function that extracts individual keys

Both can reference secrets from **different namespaces** on the Hub cluster.

## copySecretData

### Syntax

```yaml
apiVersion: policy.open-cluster-management.io/v1
kind: ConfigurationPolicy
metadata:
  name: my-config
spec:
  remediationAction: enforce
  severity: high
  namespaceSelector:
    include:
    - target-namespace
  copySecretData:
  - sourceNamespace: hub-namespace      # Namespace on Hub cluster
    sourceName: secret-name             # Secret name on Hub
    targetNamespace: target-namespace   # Namespace on managed cluster
    targetName: secret-name             # Secret name on managed cluster
```

### Key Features

- ✅ Copies **entire secret** with all keys
- ✅ Preserves secret **type** (Opaque, TLS, dockerconfigjson, etc.)
- ✅ Preserves secret **labels** and **annotations**
- ✅ Can reference **any namespace** on Hub
- ✅ Simpler syntax for complete secrets
- ✅ No need to know individual key names
- ❌ Cannot modify or transform secret data
- ❌ Cannot combine keys from multiple secrets
- ❌ Cannot add additional keys

### When to Use copySecretData

- Copying complete registry credentials
- Copying TLS certificates (with tls.crt and tls.key)
- Copying entire secret structures unchanged
- When you don't need to modify the secret
- When you don't know all key names in advance

### Example: Copy Complete Secret from Different Namespace

```yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: copy-registry-secret
  namespace: rhacm-policies
spec:
  remediationAction: enforce
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: copy-registry-creds
      spec:
        remediationAction: enforce
        severity: high
        namespaceSelector:
          include:
          - production-apps
        copySecretData:
        # Copy from registry-secrets namespace on Hub
        # to production-apps namespace on managed cluster
        - sourceNamespace: registry-secrets
          sourceName: quay-pull-secret
          targetNamespace: production-apps
          targetName: quay-pull-secret
```

**On Hub cluster:**
```bash
# Secret in registry-secrets namespace
oc get secret quay-pull-secret -n registry-secrets
```

**Result on managed cluster:**
```bash
# Exact copy in production-apps namespace
oc get secret quay-pull-secret -n production-apps
# All keys, type, labels, annotations preserved
```

## fromSecret Template Function

### Syntax

```yaml
stringData:
  key-name: '{{hub fromSecret "namespace" "secret-name" "key" hub}}'
```

### Key Features

- ✅ Extracts **individual keys** from secrets
- ✅ Can reference **any namespace** on Hub
- ✅ Can **combine** keys from multiple secrets
- ✅ Can **transform** and **compose** values
- ✅ Can add **static values** alongside secret values
- ✅ Can create **connection strings** from components
- ❌ More verbose for complete secrets
- ❌ Must know key names in advance
- ❌ Only works in `stringData` field

### When to Use fromSecret

- Need specific keys from a secret
- Combining keys from multiple secrets
- Creating connection strings or URLs
- Adding static configuration alongside secrets
- Transforming secret data
- When you need fine-grained control

### Example: Extract Keys from Different Namespace

```yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: extract-secret-keys
  namespace: rhacm-policies
spec:
  remediationAction: enforce
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: create-composed-secret
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
              name: app-config
              namespace: production-apps
            type: Opaque
            stringData:
              # Extract from vault-secrets namespace
              DB_USERNAME: '{{hub fromSecret "vault-secrets" "database-creds" "username" hub}}'
              DB_PASSWORD: '{{hub fromSecret "vault-secrets" "database-creds" "password" hub}}'
              DB_HOST: '{{hub fromSecret "vault-secrets" "database-creds" "host" hub}}'
              
              # Extract from different namespace
              API_KEY: '{{hub fromSecret "api-secrets" "external-api" "key" hub}}'
              
              # Compose connection string
              DATABASE_URL: 'postgresql://{{hub fromSecret "vault-secrets" "database-creds" "username" hub}}:{{hub fromSecret "vault-secrets" "database-creds" "password" hub}}@{{hub fromSecret "vault-secrets" "database-creds" "host" hub}}:5432/mydb'
              
              # Add static values
              ENVIRONMENT: "production"
              LOG_LEVEL: "info"
```

## Side-by-Side Comparison

### Scenario 1: Copy Entire Registry Secret

**Using copySecretData (Recommended):**
```yaml
copySecretData:
- sourceNamespace: registry-secrets
  sourceName: quay-credentials
  targetNamespace: production-apps
  targetName: quay-credentials
```

**Using fromSecret:**
```yaml
object-templates:
- complianceType: musthave
  objectDefinition:
    apiVersion: v1
    kind: Secret
    metadata:
      name: quay-credentials
      namespace: production-apps
    type: kubernetes.io/dockerconfigjson
    data:
      .dockerconfigjson: '{{hub fromSecret "registry-secrets" "quay-credentials" ".dockerconfigjson" hub}}'
```

**Winner:** `copySecretData` - simpler and preserves secret type

### Scenario 2: Create Database Connection String

**Using copySecretData:**
```yaml
# Not possible - can't modify or compose values
```

**Using fromSecret (Required):**
```yaml
object-templates:
- complianceType: musthave
  objectDefinition:
    apiVersion: v1
    kind: Secret
    metadata:
      name: db-config
      namespace: production-apps
    type: Opaque
    stringData:
      DATABASE_URL: 'postgresql://{{hub fromSecret "vault-secrets" "db" "user" hub}}:{{hub fromSecret "vault-secrets" "db" "pass" hub}}@{{hub fromSecret "vault-secrets" "db" "host" hub}}:5432/mydb'
```

**Winner:** `fromSecret` - only option for composition

### Scenario 3: Combine Multiple Secrets

**Using copySecretData:**
```yaml
# Can copy multiple secrets, but creates separate secrets on managed cluster
copySecretData:
- sourceNamespace: vault-secrets
  sourceName: database-creds
  targetNamespace: production-apps
  targetName: database-creds
- sourceNamespace: api-secrets
  sourceName: external-api
  targetNamespace: production-apps
  targetName: api-creds
```

**Using fromSecret:**
```yaml
# Can combine into single secret
object-templates:
- complianceType: musthave
  objectDefinition:
    apiVersion: v1
    kind: Secret
    metadata:
      name: combined-config
      namespace: production-apps
    type: Opaque
    stringData:
      # From database secret
      DB_USER: '{{hub fromSecret "vault-secrets" "database-creds" "username" hub}}'
      DB_PASS: '{{hub fromSecret "vault-secrets" "database-creds" "password" hub}}'
      # From API secret
      API_KEY: '{{hub fromSecret "api-secrets" "external-api" "key" hub}}'
```

**Winner:** `fromSecret` - can combine into single secret

## Referencing Different Namespaces

### Both Methods Support Cross-Namespace References

**copySecretData from different namespace:**
```yaml
copySecretData:
- sourceNamespace: team-alpha-secrets  # Different namespace on Hub
  sourceName: app-credentials
  targetNamespace: production-apps
  targetName: app-credentials
```

**fromSecret from different namespace:**
```yaml
stringData:
  password: '{{hub fromSecret "team-alpha-secrets" "app-credentials" "password" hub}}'
```

### Multiple Source Namespaces

**copySecretData:**
```yaml
copySecretData:
- sourceNamespace: vault-secrets
  sourceName: database-creds
  targetNamespace: production-apps
  targetName: db-creds
- sourceNamespace: api-secrets
  sourceName: external-api
  targetNamespace: production-apps
  targetName: api-keys
- sourceNamespace: cert-manager
  sourceName: tls-cert
  targetNamespace: production-apps
  targetName: tls-cert
```

**fromSecret:**
```yaml
stringData:
  db-password: '{{hub fromSecret "vault-secrets" "database-creds" "password" hub}}'
  api-key: '{{hub fromSecret "api-secrets" "external-api" "key" hub}}'
  tls-cert: '{{hub fromSecret "cert-manager" "tls-cert" "tls.crt" hub}}'
```

## RBAC Requirements

Both methods require RHACM to have read access to the source namespace on Hub:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: rhacm-secret-reader
  namespace: vault-secrets  # Source namespace
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: rhacm-secret-reader-binding
  namespace: vault-secrets
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: rhacm-secret-reader
subjects:
- kind: ServiceAccount
  name: governance-policy-propagator
  namespace: open-cluster-management
```

## Best Practices

### 1. Use copySecretData for Complete Secrets

```yaml
# Good: Simple and preserves structure
copySecretData:
- sourceNamespace: registry-secrets
  sourceName: quay-credentials
  targetNamespace: production-apps
  targetName: quay-credentials
```

### 2. Use fromSecret for Composition

```yaml
# Good: Compose connection strings
stringData:
  DATABASE_URL: 'postgresql://{{hub fromSecret "vault" "db" "user" hub}}:{{hub fromSecret "vault" "db" "pass" hub}}@{{hub fromSecret "vault" "db" "host" hub}}:5432/mydb'
```

### 3. Combine Both Methods When Needed

```yaml
spec:
  # Copy complete registry secret
  copySecretData:
  - sourceNamespace: registry-secrets
    sourceName: quay-credentials
    targetNamespace: production-apps
    targetName: registry-creds
  
  # Create custom secret with fromSecret
  object-templates:
  - complianceType: musthave
    objectDefinition:
      apiVersion: v1
      kind: Secret
      metadata:
        name: app-config
        namespace: production-apps
      stringData:
        db-url: '{{hub fromSecret "vault-secrets" "db" "url" hub}}'
```

### 4. Organize Hub Secrets by Purpose

```bash
# Create dedicated namespaces on Hub for different secret types
oc create namespace vault-secrets
oc create namespace registry-secrets
oc create namespace api-secrets
oc create namespace certificate-manager
oc create namespace team-alpha-secrets
```

### 5. Document Source Namespaces

```yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: copy-team-secrets
  annotations:
    description: "Copies secrets from team-alpha-secrets namespace on Hub"
    source-namespaces: "team-alpha-secrets, registry-secrets"
```

## Troubleshooting

### copySecretData Issues

**Problem: Secret not copied**

```bash
# Check source secret exists on Hub
oc get secret <secret-name> -n <source-namespace>

# Check RBAC
oc auth can-i get secrets --as=system:serviceaccount:open-cluster-management:governance-policy-propagator -n <source-namespace>

# Check policy status
oc describe policy <policy-name> -n rhacm-policies
```

**Problem: Wrong namespace**

```yaml
# Verify sourceNamespace and targetNamespace are correct
copySecretData:
- sourceNamespace: vault-secrets  # Hub namespace
  sourceName: my-secret
  targetNamespace: production-apps  # Managed cluster namespace
  targetName: my-secret
```

### fromSecret Issues

**Problem: Template error**

```bash
# Check policy for errors
oc get policy <policy-name> -n rhacm-policies -o yaml | grep -A 10 status

# Common issues:
# - Missing quotes: '{{hub fromSecret ... hub}}'
# - Wrong namespace name
# - Wrong secret name
# - Wrong key name
```

**Problem: Key not found**

```bash
# Verify key exists in source secret
oc get secret <secret-name> -n <namespace> -o yaml

# Check key names
oc get secret <secret-name> -n <namespace> -o jsonpath='{.data}' | jq 'keys'
```

## Summary

| Feature | copySecretData | fromSecret |
|---------|---------------|-----------|
| **Copy entire secret** | ✅ Yes | ❌ Manual |
| **Extract specific keys** | ❌ No | ✅ Yes |
| **Different namespace** | ✅ Yes | ✅ Yes |
| **Preserve secret type** | ✅ Yes | ❌ No |
| **Compose values** | ❌ No | ✅ Yes |
| **Combine multiple secrets** | ⚠️ Multiple copies | ✅ Single secret |
| **Syntax complexity** | Simple | Moderate |
| **Best for** | Complete secrets | Custom composition |

## Examples

See [copysecretdata-examples.yaml](./copysecretdata-examples.yaml) for 10 complete working examples.

## References

- [RHACM copySecretData Documentation](https://github.com/stolostron/config-policy-controller)
- [RHACM Template Functions](https://github.com/stolostron/go-template-utils)
- [Hub Secret Reference Guide](./README.md#hub-secret-references)


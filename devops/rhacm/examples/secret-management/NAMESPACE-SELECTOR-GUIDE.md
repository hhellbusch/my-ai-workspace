# RHACM namespaceSelector Guide

Complete guide to using `namespaceSelector` in RHACM ConfigurationPolicy objects.

## What is namespaceSelector?

The `namespaceSelector` field in a ConfigurationPolicy determines **which namespace(s) on the managed cluster** will receive the policy's object definitions (secrets, configmaps, etc.).

**Key Points:**
- Evaluated **on each managed cluster** (not on the Hub)
- Matches **existing namespaces** on the managed cluster
- Creates the object (Secret, ConfigMap, etc.) in **each matching namespace**
- If no namespaces match, the policy shows as NonCompliant

## Syntax

```yaml
apiVersion: policy.open-cluster-management.io/v1
kind: ConfigurationPolicy
metadata:
  name: my-config
spec:
  remediationAction: enforce
  severity: high
  namespaceSelector:
    # Selection criteria here
  object-templates:
  - complianceType: musthave
    objectDefinition:
      # Your resource definition
```

## Selection Methods

### Method 1: Include Specific Namespaces

Most common and recommended for secrets.

```yaml
namespaceSelector:
  include:
  - production-apps
  - staging-apps
```

**Use when:**
- You know the exact namespace name(s)
- Targeting specific application namespaces
- Following least privilege principle

**Example:**
```yaml
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
      namespace: production-apps  # Must match include list
    type: Opaque
    stringData:
      password: "secret123"
```

### Method 2: Wildcard (All Namespaces)

Matches all namespaces on the managed cluster.

```yaml
namespaceSelector:
  include:
  - "*"
```

**⚠️ Warning:** Creates the object in **every** namespace, including system namespaces!

**Use when:**
- Distributing registry pull secrets cluster-wide
- CA certificates needed everywhere
- Global configuration

**Better approach with exclusions:**
```yaml
namespaceSelector:
  include:
  - "*"
  exclude:
  - kube-*           # Kubernetes system namespaces
  - openshift-*      # OpenShift system namespaces
  - open-cluster-*   # RHACM namespaces
  - default          # Usually exclude default
```

### Method 3: Label-Based Selection

Select namespaces by labels.

```yaml
namespaceSelector:
  matchLabels:
    environment: production
    team: platform
```

**Use when:**
- Namespaces are consistently labeled
- Need dynamic namespace selection
- Multi-tenant environments

**Example:**
```yaml
# On managed cluster, label namespaces:
# oc label namespace app1 environment=production team=platform
# oc label namespace app2 environment=production team=platform

namespaceSelector:
  matchLabels:
    environment: production
    team: platform
# This will create the secret in both app1 and app2
```

### Method 4: Expression-Based Selection

Use expressions for complex logic.

```yaml
namespaceSelector:
  matchExpressions:
  - key: environment
    operator: In
    values:
    - production
    - staging
  - key: managed-by
    operator: Exists
```

**Operators:**
- `In` - Value must be in the list
- `NotIn` - Value must not be in the list
- `Exists` - Key must exist (any value)
- `DoesNotExist` - Key must not exist

**Use when:**
- Complex namespace selection logic
- Multiple conditions needed
- Excluding certain namespaces

### Method 5: Exclude Specific Namespaces

Exclude takes precedence over include.

```yaml
namespaceSelector:
  include:
  - "*"
  exclude:
  - kube-system
  - kube-public
  - openshift-monitoring
```

**Use when:**
- Need broad distribution with specific exclusions
- Avoiding system namespaces

## Common Patterns

### Pattern 1: Single Application Secret

**Scenario:** Deploy database credentials to one specific namespace.

```yaml
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
      username: "app_user"
      password: '{{hub fromSecret "rhacm-secrets" "db-creds" "password" hub}}'
```

### Pattern 2: Multi-Environment Deployment

**Scenario:** Different secrets per environment using labels.

```yaml
# Production Policy
---
apiVersion: policy.open-cluster-management.io/v1
kind: ConfigurationPolicy
metadata:
  name: prod-secrets
spec:
  namespaceSelector:
    matchLabels:
      environment: production
  object-templates:
  - complianceType: musthave
    objectDefinition:
      apiVersion: v1
      kind: Secret
      metadata:
        name: app-credentials
        namespace: "{{ (lookup \"v1\" \"Namespace\" \"\" \"\").metadata.name }}"
      stringData:
        password: '{{hub fromSecret "rhacm-secrets" "prod-db" "password" hub}}'

# Staging Policy
---
apiVersion: policy.open-cluster-management.io/v1
kind: ConfigurationPolicy
metadata:
  name: staging-secrets
spec:
  namespaceSelector:
    matchLabels:
      environment: staging
  object-templates:
  - complianceType: musthave
    objectDefinition:
      apiVersion: v1
      kind: Secret
      metadata:
        name: app-credentials
        namespace: "{{ (lookup \"v1\" \"Namespace\" \"\" \"\").metadata.name }}"
      stringData:
        password: '{{hub fromSecret "rhacm-secrets" "staging-db" "password" hub}}'
```

### Pattern 3: Registry Pull Secrets (Cluster-Wide)

**Scenario:** Distribute registry credentials to all application namespaces.

```yaml
namespaceSelector:
  include:
  - "*"
  exclude:
  # Exclude Kubernetes system namespaces
  - kube-*
  # Exclude OpenShift system namespaces
  - openshift-*
  # Exclude RHACM namespaces
  - open-cluster-*
  # Exclude monitoring
  - monitoring
  - prometheus
  # Exclude default
  - default

object-templates:
- complianceType: musthave
  objectDefinition:
    apiVersion: v1
    kind: Secret
    metadata:
      name: registry-credentials
      namespace: "{{ (lookup \"v1\" \"Namespace\" \"\" \"\").metadata.name }}"
    type: kubernetes.io/dockerconfigjson
    data:
      .dockerconfigjson: '{{hub fromSecret "rhacm-secrets" "quay-creds" ".dockerconfigjson" hub}}'
```

### Pattern 4: Create Namespace Then Secret

**Scenario:** Ensure namespace exists before creating secret.

```yaml
policy-templates:
# Step 1: Create namespace
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
            name: production-apps
            labels:
              environment: production
              managed-by: rhacm

# Step 2: Create secret in that namespace
- objectDefinition:
    apiVersion: policy.open-cluster-management.io/v1
    kind: ConfigurationPolicy
    metadata:
      name: create-app-secret
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
            name: app-credentials
            namespace: production-apps
          type: Opaque
          stringData:
            password: "secret123"
```

### Pattern 5: Team-Based Multi-Tenancy

**Scenario:** Each team has multiple namespaces, all need the same secret.

```yaml
# Label team namespaces on managed cluster:
# oc label namespace team-alpha-prod team=alpha
# oc label namespace team-alpha-dev team=alpha
# oc label namespace team-beta-prod team=beta

namespaceSelector:
  matchLabels:
    team: alpha  # Only team alpha namespaces

object-templates:
- complianceType: musthave
  objectDefinition:
    apiVersion: v1
    kind: Secret
    metadata:
      name: team-shared-credentials
      namespace: "{{ (lookup \"v1\" \"Namespace\" \"\" \"\").metadata.name }}"
    type: Opaque
    stringData:
      api-key: '{{hub fromSecret "rhacm-secrets" "team-alpha-api" "key" hub}}'
```

### Pattern 6: Dynamic Namespace with Lookup

**Scenario:** Reference the actual namespace in the secret itself.

```yaml
namespaceSelector:
  matchLabels:
    app: myapp

object-templates:
- complianceType: musthave
  objectDefinition:
    apiVersion: v1
    kind: Secret
    metadata:
      name: app-config
      # Use lookup to get the namespace name dynamically
      namespace: "{{ (lookup \"v1\" \"Namespace\" \"\" \"\").metadata.name }}"
      labels:
        # Can also reference namespace in labels
        original-namespace: "{{ (lookup \"v1\" \"Namespace\" \"\" \"\").metadata.name }}"
    type: Opaque
    stringData:
      # Can use namespace name in secret data
      namespace: "{{ (lookup \"v1\" \"Namespace\" \"\" \"\").metadata.name }}"
      password: "secret123"
```

## Best Practices

### 1. Be Specific

```yaml
# Good: Specific and intentional
namespaceSelector:
  include:
  - production-apps
  - staging-apps

# Bad: Too broad, unclear intent
namespaceSelector:
  include:
  - "*"
```

### 2. Use Labels for Dynamic Selection

```yaml
# Good: Scales with new namespaces
namespaceSelector:
  matchLabels:
    needs-registry-creds: "true"

# Requires: Label namespaces appropriately
# oc label namespace app1 needs-registry-creds=true
```

### 3. Always Exclude System Namespaces with Wildcards

```yaml
# Good: Explicit exclusions
namespaceSelector:
  include:
  - "*"
  exclude:
  - kube-*
  - openshift-*
  - open-cluster-*

# Bad: Could affect system namespaces
namespaceSelector:
  include:
  - "*"
```

### 4. Create Namespace in Policy if Uncertain

```yaml
# Good: Ensures namespace exists
policy-templates:
- objectDefinition:  # First, create namespace
    kind: ConfigurationPolicy
    metadata:
      name: ensure-namespace
    spec:
      object-templates:
      - complianceType: musthave
        objectDefinition:
          kind: Namespace
          metadata:
            name: production-apps
- objectDefinition:  # Then, create secret
    kind: ConfigurationPolicy
    metadata:
      name: create-secret
    spec:
      namespaceSelector:
        include:
        - production-apps
```

### 5. Document Your Selection Logic

```yaml
namespaceSelector:
  # Select all production application namespaces
  # Excludes system namespaces for security
  matchLabels:
    environment: production
    type: application
  matchExpressions:
  - key: managed-by
    operator: In
    values:
    - platform-team
    - devops-team
```

### 6. Use Consistent Namespace Labeling

Establish a labeling standard:

```bash
# Standard labels
oc label namespace myapp environment=production
oc label namespace myapp team=platform
oc label namespace myapp app=myapp
oc label namespace myapp managed-by=rhacm

# Then use in policies
namespaceSelector:
  matchLabels:
    environment: production
    managed-by: rhacm
```

## Troubleshooting

### Problem: Policy Shows NonCompliant - "Namespace not found"

**Cause:** No namespaces match the selector on the managed cluster.

**Solution:**
```bash
# Check namespaces on managed cluster
oc --context=<managed-cluster> get namespaces

# If using labels, check namespace labels
oc --context=<managed-cluster> get namespace <name> --show-labels

# Create the namespace or adjust the selector
```

### Problem: Secret Created in Too Many Namespaces

**Cause:** Wildcard selector without proper exclusions.

**Solution:**
```yaml
# Add explicit exclusions
namespaceSelector:
  include:
  - "*"
  exclude:
  - kube-*
  - openshift-*
  - default
  # Add more as needed
```

### Problem: Secret Not Created in Expected Namespace

**Cause:** Namespace doesn't match the selector criteria.

**Solution:**
```bash
# Check if namespace exists
oc --context=<managed-cluster> get namespace <name>

# Check if namespace has required labels
oc --context=<managed-cluster> get namespace <name> --show-labels

# Add missing labels
oc --context=<managed-cluster> label namespace <name> environment=production
```

### Problem: Namespace in object-template Doesn't Match Selector

**Cause:** Hardcoded namespace in `object-templates` that doesn't match `namespaceSelector`.

**Solution:**
```yaml
# Use dynamic lookup
object-templates:
- complianceType: musthave
  objectDefinition:
    apiVersion: v1
    kind: Secret
    metadata:
      name: my-secret
      # Use this instead of hardcoded namespace
      namespace: "{{ (lookup \"v1\" \"Namespace\" \"\" \"\").metadata.name }}"
```

## Testing Your namespaceSelector

### Step 1: Test on Dev Cluster First

```bash
# Create test namespace with labels
oc create namespace test-namespace
oc label namespace test-namespace environment=dev app=test

# Apply policy with inform mode first
spec:
  remediationAction: inform  # Just report, don't create

# Check what would be selected
oc get policy <policy-name> -o yaml
```

### Step 2: Verify Namespace Selection

```bash
# List namespaces that match your selector
# For label-based:
oc get namespace -l environment=production

# For name-based:
oc get namespace | grep -E "production-apps|staging-apps"
```

### Step 3: Check Policy Status

```bash
# View policy compliance
oc get policy <policy-name> -n rhacm-policies

# Describe for details
oc describe policy <policy-name> -n rhacm-policies

# Check on managed cluster
oc --context=<cluster> get secret -A | grep <secret-name>
```

## Examples by Use Case

### Use Case 1: Single Application

```yaml
# Application runs in one namespace
namespaceSelector:
  include:
  - my-app-production
```

### Use Case 2: Microservices

```yaml
# Multiple services, each in own namespace
namespaceSelector:
  include:
  - frontend-prod
  - backend-prod
  - api-prod
  - worker-prod
```

### Use Case 3: Multi-Tenant Platform

```yaml
# Tenant namespaces labeled by tenant ID
namespaceSelector:
  matchLabels:
    tenant-id: "customer-123"
```

### Use Case 4: Development vs Production

```yaml
# Different policies for different environments
# Development policy:
namespaceSelector:
  matchExpressions:
  - key: environment
    operator: In
    values:
    - development
    - testing

# Production policy:
namespaceSelector:
  matchLabels:
    environment: production
```

### Use Case 5: Registry Secrets Everywhere

```yaml
# All namespaces except system ones
namespaceSelector:
  include:
  - "*"
  exclude:
  - kube-system
  - kube-public
  - kube-node-lease
  - openshift-*
  - open-cluster-management*
  - default
  - local-path-storage
```

## Quick Reference

| Scenario | namespaceSelector |
|----------|-------------------|
| Single known namespace | `include: [namespace-name]` |
| Multiple known namespaces | `include: [ns1, ns2, ns3]` |
| All application namespaces | `matchLabels: {type: application}` |
| Production only | `matchLabels: {environment: production}` |
| All except system | `include: ["*"], exclude: [kube-*, openshift-*]` |
| Dynamic by team | `matchLabels: {team: platform}` |
| Complex conditions | `matchExpressions: [...]` |

## Additional Resources

- [RHACM ConfigurationPolicy Spec](https://github.com/stolostron/config-policy-controller)
- [Kubernetes Namespace Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- [RHACM Policy Collection](https://github.com/stolostron/policy-collection)

## Summary

**Key Takeaways:**

1. ✅ `namespaceSelector` determines **where on the managed cluster** objects are created
2. ✅ Be specific - use exact namespace names when possible
3. ✅ Use labels for dynamic, scalable selection
4. ✅ Always exclude system namespaces when using wildcards
5. ✅ Create namespaces in the policy if they don't exist
6. ✅ Test with `remediationAction: inform` first
7. ✅ Document your selection logic clearly
8. ✅ Use consistent namespace labeling standards


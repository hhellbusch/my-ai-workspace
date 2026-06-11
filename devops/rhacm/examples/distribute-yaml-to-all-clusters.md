# Distribute Resources Across Managed Clusters with RHACM

> **Audience:** Platform engineers, SREs, or anyone managing multiple OCP clusters through RHACM  
> **Purpose:** Practical guide to pushing a resource definition to all managed clusters using RHACM's policy framework

---

## The Problem

You have a YAML file — a ConfigMap, Secret, NetworkPolicy, CustomResource — and you want it applied to every cluster under RHACM's management. Three paths exist, from quick-and-dirty to production-grade.

---

## Option 1: Direct `oc` Loop (One-Off Only)

For a single deployment with no ongoing drift control:

```bash
for cluster in $(oc get managedclusters -o jsonpath='{.items[?(@.metadata.name!="local-cluster")].metadata.name}'); do
  oc --context=${cluster} -n <namespace> apply -f your-resource.yaml
done
```

**Why this is a dead end:** If someone edits a resource directly on a managed cluster, nothing corrects it. You're managing by memory, not by state. Use this for the initial bootstrap; switch to Option 2 for everything after.

---

## Option 2: RHACM Policy + Placement (Recommended)

This is the RHACM-native approach. Three resources work together:

| Resource | Role |
|---|---|
| **Placement** | Defines *which* clusters get the resource |
| **PlacementBinding** | Wires the Policy to the Placement |
| **Policy** | Wraps your YAML as a ConfigurationPolicy |

RHACM continuously reconciles. If a resource is deleted or modified on any managed cluster, it gets put back.

### Step 1: Placement — Select Clusters

```yaml
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Placement
metadata:
  name: all-managed-clusters
  namespace: rhacm-policies
spec:
  predicates:
  - requiredClusterSelector:
      matchExpressions:
      - key: name
        operator: NotIn
        values:
        - local-cluster
  tolerations:
  - key: cluster.open-cluster-management.io/unreachable
    operator: Exists
  - key: cluster.open-cluster-management.io/unavailable
    operator: Exists
```

This selects every managed cluster except the local hub cluster. The `tolerations` prevent policies from vanishing during transient network issues — add both `unreachable` and `unavailable` for resilience.

If you want to scope to a subset, use labels instead:

```yaml
spec:
  predicates:
  - requiredClusterSelector:
      labelSelector:
        matchLabels:
          environment: production
```

See `placement-by-labels.yaml` for filtering patterns (AND logic, NOT-in exclusions, multi-value OR, label existence checks, MergedPredicate).

### Step 2: PlacementBinding — Wire Policy to Placement

```yaml
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  name: binding-all-clusters
  namespace: rhacm-policies
placementRef:
  name: all-managed-clusters
  kind: Placement
  apiGroup: cluster.open-cluster-management.io
subjects:
- name: my-resource-policy
  kind: Policy
  apiGroup: policy.open-cluster-management.io
```

This connects the policy to the placement. The `placementRef` must reference a Placement (not a PlacementRule — those are deprecated as of RHACM 2.15+).

### Step 3: Policy — Wrap Your YAML

```yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: my-resource-policy
  namespace: rhacm-policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: my-resource-config
      spec:
        remediationAction: enforce
        severity: high
        namespaceSelector:
          include:
          - <your-namespace>
        object-templates:
        - complianceType: musthave
          objectDefinition:
            # Paste your YAML here, verbatim
            apiVersion: v1
            kind: ConfigMap
            metadata:
              name: my-config
              namespace: <your-namespace>
            data:
              key: value
```

The critical fields:
- **`remediationAction: enforce`** — this is what drives drift correction. `inform` would report but not fix.
- **`complianceType: musthave`** — the resource must exist with these exact properties.
- **`namespaceSelector.include`** — which namespace(s) on managed clusters to target.

---

### Apply and Verify

```bash
# Apply all three to the hub
oc apply -f placement-all-clusters.yaml
oc apply -f binding-all-clusters.yaml
oc apply -f policy-my-resource.yaml

# Verify which clusters are targeted
oc get placementdecision -n rhacm-policies
oc get placementdecision -l cluster.open-cluster-management.io/placement=all-managed-clusters -o yaml

# Check policy status
oc get policies -n rhacm-policies -o wide
```

---

## Option 3: GitOps with ArgoCD — For Existing GitOps Pipelines

If you're using ArgoCD, you can register RHACM-managed clusters as ArgoCD targets and deploy applications via ApplicationSet driven by cluster labels. The repo is your source of truth; ArgoCD handles deployment and drift correction.

### Registering RHACM Clusters with ArgoCD

ArgoCD can discover clusters through RHACM using either:

**ManagedClusterSet binding** (RHACM → ArgoCD integration):

```yaml
# In the openshift-gitops namespace
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSetBinding
metadata:
  name: default
spec:
  clusterSet: default
---
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Placement
metadata:
  name: all-openshift-clusters
  namespace: openshift-gitops
spec:
  clusterSets:
  - default
  predicates:
  - requiredClusterSelector:
      labelSelector:
        matchExpressions:
        - key: vendor
          operator: In
          values:
          - OpenShift
---
apiVersion: apps.open-cluster-management.io/v1beta1
kind: GitOpsCluster
metadata:
  name: argo-acm-clusters
  namespace: openshift-gitops
spec:
  argoServer:
    cluster: local-cluster
    argoNamespace: openshift-gitops
  placementRef:
    kind: Placement
    apiVersion: cluster.open-cluster-management.io/v1beta1
    name: all-openshift-clusters
```

This is a one-time setup on the hub — after applying it, ArgoCD automatically discovers managed clusters as deployment destinations.

### Deploying with ApplicationSet

Once clusters are registered, use ApplicationSet with the cluster selector:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: global-config
  namespace: openshift-gitops
spec:
  generators:
  - list:
      elements:
      - cluster: local-cluster
        namespace: kube-system
      - cluster: cluster-a
        namespace: default
      - cluster: cluster-b
        namespace: default
  template:
    metadata:
      name: '{{cluster}}-config'
    spec:
      project: default
      source:
        repoURL: https://github.com/org/gitops-repo.git
        targetRevision: main
        path: configs/{{cluster}}
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{namespace}}'
```

For label-based cluster selection instead of a hardcoded list, combine with the ManagedClusterSet pattern above and use the `cluster` generator from the `argocd-rbac` integration.

See `gitops-cluster-integration/` for the full ManagedClusterSet + ArgoCD integration examples.

---

## Targeting Subsets with Labels

For production environments, you rarely want "everything everywhere." Label your clusters consistently:

```bash
# Label clusters
oc label managedcluster cluster-1 environment=production region=us-east-1
oc label managedcluster cluster-2 environment=production region=us-west-2
oc label managedcluster cluster-3 environment=staging region=us-east-1
```

Then create a Placement that filters by those labels:

```yaml
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Placement
metadata:
  name: production-clusters
  namespace: rhacm-policies
spec:
  predicates:
  - requiredClusterSelector:
      labelSelector:
        matchLabels:
          environment: production
  tolerations:
  - key: cluster.open-cluster-management.io/unreachable
    operator: Exists
```

Common label patterns:
- `environment: production | staging | development`
- `region: us-east-1 | us-west-2 | eu-central-1`
- `cloud: aws | azure | gcp | on-prem`
- `compliance: pci-dss | hipaa | sox`

---

## Hub Secret References (Don't Embed Secrets in YAML)

For secrets, store them on the hub and reference them in policies:

```bash
# Create secret on hub
oc create secret generic db-credentials \
  -n rhacm-secrets \
  --from-literal=password=secret123
```

Then in your policy template:

```yaml
object-templates:
- complianceType: musthave
  objectDefinition:
    apiVersion: v1
    kind: Secret
    metadata:
      name: db-credentials
      namespace: <your-namespace>
    type: Opaque
    stringData:
      password: '{{hub fromSecret "rhacm-secrets" "db-credentials" "password" hub}}'
```

**Benefits:** Single source of truth, centralized rotation, no secrets in Git. For production workloads, consider External Secrets Operator instead — it pushes secrets to Vault/AWS SM and creates ExternalSecrets on managed clusters, meaning Kubernetes never stores the secret at rest.

See the full secret management examples at `secret-management/`.

---

## Common Pitfalls

**PlacementBinding references PlacementRule.** PlacementRule is deprecated as of RHACM 2.6, removed in 2.15+. Use `kind: Placement` with `apiGroup: cluster.open-cluster-management.io`.

**Missing ManagedClusterSetBinding.** When using a ManagedClusterSet, you must bind it to a namespace before the Placement can use it. See `placement-binding.yaml` for the pattern.

**No tolerations.** Without tolerations, policies disappear when a cluster temporarily goes unreachable. Always add at minimum `cluster.open-cluster-management.io/unreachable`.

**`remediationAction: inform` instead of `enforce`.** `inform` reports drift but doesn't correct it. Use `enforce` if you want automatic remediation.

---

*This document was created with AI assistance (Cursor) and has not been fully reviewed by the author. See [AI-DISCLOSURE.md](AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

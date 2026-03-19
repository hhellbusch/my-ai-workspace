# ArgoCD RBAC via RHACM Policy

This pattern uses a RHACM `Policy` to declaratively grant OpenShift GitOps (ArgoCD) cluster-admin permissions on managed clusters. This avoids manually applying ClusterRoleBindings and ensures they are continuously reconciled by RHACM.

## Why RHACM for RBAC?

- **Declarative drift prevention**: RHACM continuously enforces the policy. If someone removes the ClusterRoleBinding, it is automatically re-created.
- **Multi-cluster scale**: A single policy propagates to all matching clusters via PlacementRule. No per-cluster manual steps.
- **Audit trail**: All policy changes flow through Git, providing a clear history of who granted what and when.

## Prerequisites

- RHACM MultiClusterHub running on the hub cluster
- OpenShift GitOps operator installed (creates the `openshift-gitops` namespace and service accounts)

## What the Policy Does

Creates two `ClusterRoleBinding` resources on each targeted cluster:

| Binding Name | Service Account | Role |
|---|---|---|
| `argocd-application-controller-cluster-admin` | `openshift-gitops-argocd-application-controller` | `cluster-admin` |
| `argocd-server-cluster-admin` | `openshift-gitops-argocd-server` | `cluster-admin` |

## Targeting

The included `PlacementRule` targets **only the local hub cluster** (`local-cluster: "true"`).

To target all managed clusters, modify the `PlacementRule`:

```yaml
spec:
  clusterConditions:
  - status: "True"
    type: ManagedClusterConditionAvailable
  clusterSelector:
    matchExpressions: []  # empty = all clusters
```

To target a specific set of clusters by label:

```yaml
spec:
  clusterSelector:
    matchLabels:
      environment: production
```

## Apply

Once ACM's MultiClusterHub is in `Running` state:

```bash
oc apply -f policy-argocd-cluster-admin.yaml -n open-cluster-management
```

Verify the policy is compliant:

```bash
oc get policy policy-argocd-cluster-admin -n open-cluster-management
```

The `COMPLIANT` column should show `Compliant` once the bindings are applied on all targeted clusters.

## Verify on Target Cluster

```bash
oc get clusterrolebinding argocd-application-controller-cluster-admin
oc get clusterrolebinding argocd-server-cluster-admin
```

## Notes

- `remediationAction: enforce` means RHACM will create/fix the bindings automatically.
- Changing to `inform` makes the policy read-only (reports compliance without taking action).
- This is intentionally scoped to OpenShift GitOps service accounts. If you use a different ArgoCD installation namespace, update the `namespace` field in the `subjects` entries.

# RHACM → ArgoCD Cluster Integration

This pattern registers RHACM-managed clusters with an OpenShift GitOps (ArgoCD) instance using the ClusterSet-based integration. Clusters added to the ClusterSet are automatically discovered and made available as ArgoCD destinations — no manual secret creation required.

## Resources

| File | Kind | Purpose |
|---|---|---|
| `managedclustersetbinding.yaml` | `ManagedClusterSetBinding` | Grants `openshift-gitops` namespace access to the `default` ClusterSet |
| `placement.yaml` | `Placement` | Selects all OpenShift clusters from that ClusterSet |
| `gitopscluster.yaml` | `GitOpsCluster` | Registers selected clusters with ArgoCD |

See also: [`../argocd-rbac/`](../argocd-rbac/) for the RHACM Policy that grants ArgoCD cluster-admin on each registered cluster.

## How It Works

```
ManagedClusterSet (default)
        │
        │  contains
        ▼
ManagedCluster (local-cluster, cluster-a, cluster-b, ...)
        │
        │  selected by
        ▼
Placement (all-openshift-clusters)   ◄── ManagedClusterSetBinding
        │                                 (allows openshift-gitops ns
        │  feeds into                      to use "default" set)
        ▼
GitOpsCluster (argo-acm-clusters)
        │
        │  creates cluster secret in
        ▼
openshift-gitops namespace
  └── <cluster-name>-cluster-secret  (Opaque)
        │
        │  registered as destination in
        ▼
ArgoCD — cluster available for ApplicationSet / Application targeting
```

## Prerequisites

- RHACM `MultiClusterHub` in `Running` state
- OpenShift GitOps operator installed (`openshift-gitops` namespace exists)
- `managed-serviceaccount` addon enabled on target clusters (enabled by default with ACM 2.9+)
- Target clusters added to the `default` ManagedClusterSet

## Apply

```bash
oc apply -f managedclustersetbinding.yaml
oc apply -f placement.yaml
oc apply -f gitopscluster.yaml
```

Or all at once:

```bash
oc apply -f .
```

## Verify

Check `GitOpsCluster` registered successfully:

```bash
oc get gitopscluster argo-acm-clusters -n openshift-gitops
# STATUS should be: successful
```

Check cluster secrets were created in the ArgoCD namespace:

```bash
oc get secret -n openshift-gitops -l argocd.argoproj.io/secret-type=cluster
```

You should see one secret per registered cluster (e.g. `local-cluster-cluster-secret`).

## Adding More Clusters

1. Import the new cluster into RHACM
2. Label it with `cluster.open-cluster-management.io/clusterset: default` (or move it to the `default` set via the RHACM console)
3. The `Placement` and `GitOpsCluster` will automatically pick it up — no changes to these manifests needed

## Narrowing Cluster Scope

To target only a subset of clusters, update the `Placement` predicates. Examples:

**By environment label:**
```yaml
predicates:
- requiredClusterSelector:
    labelSelector:
      matchLabels:
        environment: production
```

**By cluster name:**
```yaml
predicates:
- requiredClusterSelector:
    claimSelector:
      matchExpressions:
      - key: id.openshift.io
        operator: In
        values:
        - cluster-a
        - cluster-b
```

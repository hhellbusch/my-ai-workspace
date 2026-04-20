# Preventing ArgoCD from Owning RHACM-Generated Child Policies

When ArgoCD deploys a `policy.open-cluster-management.io/v1` Policy (parent), the RHACM policy controller creates child policies (e.g. propagated policies on managed clusters). If those children inherit the **labels** ArgoCD uses for resource tracking (e.g. `app.kubernetes.io/instance` or `argocd.argoproj.io/instance`), ArgoCD will treat them as part of the Application: they show as **OutOfSync** and would be **pruned** if prune is enabled, because they are not in the desired (Git) state.

This guide describes how to prevent ArgoCD from considering these controller-generated resources as owned by the Application.

---

## Option 1: Use annotation-based resource tracking (recommended)

ArgoCD can track resources by **annotation** instead of (or in addition to) **label**. When tracking is annotation-based, only resources that have the correct `argocd.argoproj.io/tracking-id` annotation are considered part of the app. RHACM typically propagates **labels** from the parent Policy to generated policies but does **not** set ArgoCD’s tracking **annotation** on those children. So ArgoCD will no longer treat the generated policies as owned by the app.

**Steps:**

1. Edit the `argocd-cm` ConfigMap in the `argocd` namespace:

   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: argocd-cm
     namespace: argocd
     labels:
       app.kubernetes.io/name: argocd-cm
       app.kubernetes.io/part-of: argocd
   data:
     # Use annotation for ownership; label is not used for tracking
     application.resourceTrackingMethod: annotation
     # Optional: use "annotation+label" if other tools need the instance label
     # application.resourceTrackingMethod: annotation+label
   ```

2. Sync your applications again (or wait for the next refresh) so ArgoCD re-marks resources with the tracking **annotation**. After that, only resources with the correct annotation are considered; generated policies without it are no longer tracked or pruned.

**Notes:**

- With `annotation`, ArgoCD uses only `argocd.argoproj.io/tracking-id` for ownership.
- With `annotation+label`, ArgoCD still uses the annotation for ownership and pruning; the label is kept for compatibility but is not used for tracking. This is often the best choice if you rely on the instance label elsewhere.
- Changing the tracking method is cluster-wide. If you cannot change it globally, use Option 2 for the Policy kind/namespaces instead.

---

## Option 2: Global resource exclusions

You can exclude certain resources from ArgoCD’s tracking entirely via `resource.exclusions` in `argocd-cm`. Excluded resources are not considered part of any Application and are not pruned.

**Caveats:**

- Exclusions are **global** (all applications).
- Filtering is by **apiGroup**, **kind**, and optionally **cluster**. There is no label/annotation or name/namespace pattern in the exclusion rule itself in older versions; if your ArgoCD supports more fields, you can narrow by namespace/name.
- There is a [known limitation](https://github.com/argoproj/argo-cd/issues/22334): resources that ArgoCD discovers **via owner references** (e.g. children of a resource you deploy) may still be tracked even if they match an exclusion. In that case Option 1 is more reliable.

**Example:** exclude all `policy.open-cluster-management.io` Policy resources from tracking (use only if you do **not** want ArgoCD to manage any of these Policies as first-class resources):

```yaml
# argocd-cm
data:
  resource.exclusions: |
    - apiGroups:
        - policy.open-cluster-management.io
      kinds:
        - Policy
      clusters:
        - "*"
```

If your ArgoCD version supports it, you can restrict by namespace so only generated policies (e.g. in specific managed-cluster namespaces) are excluded; see the [Argo CD resource exclusions documentation](https://argo-cd.readthedocs.io/en/stable/operator-manual/argocd-cm.yaml) for the exact schema.

---

## Option 3: Disable prune for the policy Application

If you cannot change tracking or exclusions:

- Set **Prune=false** for the Application that deploys the parent Policy (e.g. in `syncPolicy` or sync options). ArgoCD will then **not** delete resources it considers “extra,” so generated policies will not be pruned.
- They will still appear as **OutOfSync** (or “extra”) in the UI, so this only avoids deletion; it does not stop ArgoCD from thinking it “owns” them.

---

## Summary

| Approach                         | Scope      | Stops tracking | Stops prune | Notes                                      |
|----------------------------------|------------|----------------|-------------|--------------------------------------------|
| Annotation-based tracking       | Cluster    | Yes            | Yes         | Best if you can change ArgoCD config       |
| resource.exclusions             | Global     | Yes*           | Yes*        | *May not apply to owner-ref–tracked resources |
| Prune=false on the Application  | Per app    | No             | Yes         | OutOfSync/extra still shown                |

**Recommendation:** Prefer **Option 1** (`application.resourceTrackingMethod: annotation` or `annotation+label`) so that only resources with the ArgoCD tracking annotation are considered owned; RHACM-generated child policies then no longer affect sync status or pruning.

---

*AI-assisted documentation. See project standards for disclosure.*

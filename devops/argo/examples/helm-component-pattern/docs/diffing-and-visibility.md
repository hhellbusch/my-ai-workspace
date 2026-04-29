# Diffing and visibility at fleet scale

Managing a fleet of clusters through GitOps creates two distinct visibility problems that require different tools:

1. **PR-level desired-state diffs** — "What will change in the cluster if this PR merges?"
2. **Fleet-wide live-to-desired diffs** — "Which clusters are currently out of sync with desired state?"

These are different questions answered by different tools. Neither replaces the other.

---

## Problem 1: PR-level desired-state diffs

### The gap

A PR that changes `groups/all/values.yaml` shows the values file change in the diff, but not the Application objects that will be created, modified, or removed as a result. The component Applications are live-rendered by `hub-clusters` — they do not appear in Git until ArgoCD renders them. The reviewer sees "channel changed from `stable` to `stable-4.16`" but not "this will touch 47 Applications across 3 hubs."

### What hub/rendered/ enables

`hub/rendered/hub-applications.yaml` is a committed, static file containing the hub-level Application objects. This provides a natural entry point for diff tooling:

```
1. Read hub/rendered/hub-applications.yaml
   → finds hub-clusters-prod-a, hub-clusters-prod-b, hub-clusters-dev

2. For each hub Application, run helm template charts/hub-clusters ...
   → renders the component Application objects (site-dc1-cert-manager, etc.)
   → does this for both the PR branch and the base branch

3. Diff the two rendered sets
   → posts exactly which component Applications changed, were added, or removed
```

The partial-render design (hub Applications committed; component Applications live) serves two purposes simultaneously: it solves the bootstrapping problem and provides a stable CI entry point.

### argocd-diff-preview

[argocd-diff-preview](https://github.com/dag-andersen/argocd-diff-preview) by dag-andersen automates this workflow. It spins up a temporary Argo CD instance, renders both branches, and posts a **desired-state-to-desired-state diff** as a PR comment.

Key property: this is a diff between what-Git-says-now and what-Git-will-say-after-merge — not a diff between the cluster's live state and the PR. Unrelated cluster drift does not appear in the diff. This is intentional: the PR reviewer sees only what the PR changes.

**Running on OpenShift without cluster-admin:** deploy argocd-diff-preview into a dedicated namespace (e.g. `argocd-diff`) using a namespace-scoped Argo CD instance (the OpenShift GitOps operator supports this). CI uses only namespace-scoped credentials — no production ArgoCD access required.

**Integration with this pattern:**

```yaml
# .github/workflows/pr-diff.yml (sketch — not yet included in this repo)
- name: argocd-diff-preview
  uses: dag-andersen/argocd-diff-preview@main
  with:
    argocd-server-url: https://argocd-diff.apps.hub.example.com
    argocd-token: ${{ secrets.ARGOCD_DIFF_TOKEN }}
    base-branch: main
    target-branch: ${{ github.head_ref }}
    # Entry point — the committed hub Applications
    app-file: hub/rendered/hub-applications.yaml
```

Reference videos:
- [argocd-diff-preview demo (short)](https://www.youtube.com/watch?v=3aeP__qPSms)
- [argocd-diff-preview at fleet scale](https://www.youtube.com/watch?v=fcajag5di68)

See the library entry: [`library/argocd-diff-preview.md`](../../../../../library/argocd-diff-preview.md)

### What is NOT covered by PR-level diffs

PR-level desired-state diffs show you what the PR changes. They do not show you:
- The current live state of clusters (whether clusters are already out of sync before the PR)
- Which clusters will be affected by the Application changes (you see the Application objects, not the resource-level effects inside each Application)
- Whether the rendered values are semantically correct (argocd-diff-preview validates the YAML structure; it cannot catch logical errors in values)

---

## Problem 2: Fleet-wide live-to-desired diffs

### The gap

After a PR merges and ArgoCD begins reconciling, you need to know: across all clusters, across all hubs, which Applications are out of sync, degraded, or unknown? This is a different question from PR diffing — it is the operational health question.

With multiple ArgoCD instances (one per hub), there is no single pane of glass by default. An operator must log into each hub's ArgoCD UI or run `argocd app list` against each hub to get a fleet picture.

### Tools and approaches

**ArgoCD CLI across hubs (manual baseline):**
```bash
# Run against each hub context
for hub in dev prod-a prod-b; do
  echo "=== $hub ==="
  argocd app list --server argocd.$hub.example.com \
    --auth-token $TOKEN \
    --output wide \
    | grep -v Synced
done
```
Workable for small fleets; does not scale operationally.

**RHACM + ACM Observability (recommended for large fleets):**

RHACM provides a hub-level fleet view. When ArgoCD is deployed via RHACM's GitOps integration:
- Every managed cluster's ArgoCD Application status is visible in the ACM console
- Non-compliant or degraded Applications surface in the governance dashboard alongside policy violations
- ACM Observability can aggregate ArgoCD sync metrics across all clusters into a single Prometheus endpoint for fleet-wide alerting

This is one of the primary reasons RHACM is complementary (not required) to this pattern. If you have RHACM, plug in ACM Observability for fleet-wide visibility. If you don't, the multi-hub CLI approach is the fallback.

**ArgoCD ApplicationSet with pull model (advanced):**

For environments where spoke clusters cannot be reached from the hub (fully disconnected sites), ArgoCD's [pull model via ApplicationSet](https://argo-cd.readthedocs.io/en/stable/operator-manual/applicationset/Generators-Pull-Request/) can deliver Applications to clusters that phone home to the hub. Each cluster's ArgoCD instance reports status back. This is an advanced topology not covered in the current implementation but worth understanding for fully disconnected environments.

**Prometheus + AlertManager fleet alerting:**

Each hub's ArgoCD exposes Prometheus metrics. A fleet-level Prometheus (e.g. ACM Observability's Thanos endpoint, or a dedicated metrics aggregator) can federate these and alert on:
- `argocd_app_info{sync_status!="Synced"}` — any Application out of sync
- `argocd_app_info{health_status="Degraded"}` — any Application degraded
- `argocd_app_k8s_app_info{...}` — resource-level health per Application

A `PrometheusRule` across the aggregated endpoint gives you a fleet-wide alert when any cluster drifts from desired state.

---

## Putting it together: the two-layer visibility model

| Question | Tool | Scope |
|---|---|---|
| "What will this PR change?" | argocd-diff-preview | Desired-state to desired-state diff per PR |
| "What is currently out of sync?" | RHACM ACM Observability / ArgoCD Prometheus metrics | Live fleet health, all hubs |
| "What is wrong with this specific cluster?" | `argocd app list`, ArgoCD UI on that hub | Per-hub operational view |
| "Why is this Application degraded?" | `argocd app logs`, `oc describe` on managed cluster | Per-Application / per-resource debugging |

The PR diff and the fleet health view are complementary — neither replaces the other. A well-instrumented fleet has both: argocd-diff-preview running on every PR, and Prometheus alerts firing when any cluster drifts after merge.

---

*AI-assisted content. See [AI-DISCLOSURE.md](../../../../../AI-DISCLOSURE.md) for review status details.*

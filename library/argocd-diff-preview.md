# argocd-diff-preview

**Type:** Open-source CLI tool / CI integration
**Author:** Dag Andersen (dag-andersen)
**Repository:** [github.com/dag-andersen/argocd-diff-preview](https://github.com/dag-andersen/argocd-diff-preview)
**Language:** Go

---

## What it does

`argocd-diff-preview` produces a **desired-state-to-desired-state diff** for Argo CD Applications on a pull request. Instead of comparing what is currently running in the cluster against what the PR proposes (current-state → desired-state), it compares what Argo CD would render from the base branch against what it would render from the PR branch (desired-state → desired-state).

This distinction matters. A current-state diff is noisy — it includes unrelated cluster drift, pending reconciliations, and state from previous deployments. A desired-state diff is clean — it shows only what the PR actually changes in the manifests Argo CD will apply.

---

## How it works

1. Spins up a temporary, lightweight Argo CD instance (no cluster required — runs in-process or via a local Kind cluster).
2. Renders all Argo CD Application manifests from the **base branch** (typically `main`).
3. Renders all Argo CD Application manifests from the **PR branch**.
4. Diffs the two rendered outputs.
5. Posts the diff as a pull request comment via the GitHub API.

The rendered output includes the full Kubernetes manifests that Argo CD would apply — after Helm templating, Kustomize rendering, or raw YAML expansion. The diff is therefore a true representation of "what changes in the cluster if this PR merges."

---

## Running on OpenShift in an isolated namespace

The standard deployment assumes cluster-admin or wide cluster access. Running on OpenShift without cluster-admin requires an isolated namespace approach:

- Deploy argocd-diff-preview into a dedicated namespace (e.g. `argocd-diff`).
- Scope the Argo CD instance used for rendering to that namespace — it does not need to manage any real clusters; it only renders manifests.
- Grant the service account only the permissions needed to create and read Application objects in that namespace.
- Use a namespaced `ArgoCD` CR (OpenShift GitOps operator supports namespace-scoped instances).
- The GitHub Actions workflow calls the tool against this isolated instance rather than the production Argo CD.

This avoids giving CI pipelines production Argo CD access while still getting accurate desired-state diffs.

---

## Key benefits for the component-<name> pattern

When using the `mustMergeOverwrite` + `component-<name>` + `global-root` pattern, a PR might change:
- A group values file (`groups/virt-enabled/values.yaml`) — affecting every cluster in that group
- `clusters.yaml` — affecting cluster metadata injected into every Application
- A cluster values file — affecting only one cluster's component overrides

Without `argocd-diff-preview`, the only way to verify what will change is to run `helm template` locally or read the Helm source carefully. With it, the PR comment shows the exact Kubernetes manifest diff for every affected Application, across every cluster on every hub — making large fleet changes reviewable with confidence.

---

## Integration with this repo's pattern

See the GitHub Actions example in `devops/argo/examples/github-workflows/` for a starting-point workflow. Key integration points:

- Point the tool at `hub/<env>-global-root.yaml` to render per-hub Application sets.
- Run one diff job per hub to show the full fleet impact of a PR.
- The isolated namespace deployment on OpenShift means CI does not need production cluster credentials.

---

## References

- [Repository](https://github.com/dag-andersen/argocd-diff-preview)
- Demo videos referenced during adoption:
  - [https://www.youtube.com/watch?v=3aeP__qPSms](https://www.youtube.com/watch?v=3aeP__qPSms)
  - [https://www.youtube.com/watch?v=fcajag5di68](https://www.youtube.com/watch?v=fcajag5di68)

---

*AI-assisted content. See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for review status details.*

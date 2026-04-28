# Argo CD hands-on labs

Self-contained lab tracks for GitOps on OpenShift or Kubernetes. Each folder has charts, values, and an instructor guide.

| Lab | Time (typical) | Summary |
|-----|----------------|---------|
| [lab-gitops](lab-gitops/lab/INSTRUCTOR-GUIDE.md) | ~1 hour | App-of-apps cascade (components → groups → cluster); participants extend a shared GitOps repo. |
| [lab-argocd-sync](lab-argocd-sync/lab/INSTRUCTOR-GUIDE.md) | 1–2 hours | Sync policy, `syncOptions`, `ignoreDifferences`, retries via the same values cascade — no direct Application CRD edits. |

Start with **lab-gitops** if the audience is new to Argo CD; use **lab-argocd-sync** after that or for teams who already deploy with Argo CD and need sync-behavior depth.

*AI-assisted content. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for review status details.*

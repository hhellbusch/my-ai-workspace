# ArgoCD Sync Settings Lab — Overview

> **CLI note:** All commands in this lab use `oc`. `oc` is the OpenShift CLI and is a fully compatible drop-in replacement for `kubectl` — every `oc` command here works identically with `kubectl` if that is what you have available.

This lab is delivered in three independent one-hour sessions. You can attend any session that covers the topics you need — Session 1 is the only prerequisite for Sessions 2 and 3.

| Session | File | Theme | Exercises |
|---------|------|-------|-----------|
| 1 | [LAB-SESSION-1.md](LAB-SESSION-1.md) | Sync Modes | 1 – 4 |
| 2 | [LAB-SESSION-2.md](LAB-SESSION-2.md) | Application-Level Controls | 5, 9, 10 |
| 3 | [LAB-SESSION-3.md](LAB-SESSION-3.md) | Resource-Level Control | 6, 7, 8 |

---

## What You Will Learn Across All Sessions

- The difference between manual and automated sync
- What `prune` and `selfHeal` do and when each is appropriate
- The available `syncOptions` flags and their trade-offs
- How to tell ArgoCD to ignore specific field differences
- How to retry failed syncs automatically
- How to protect individual resources from pruning using annotations
- How to control the creation order of resources using sync waves
- How to run pre- and post-sync tasks using sync hooks

---

## How the Framework Works

The lab uses the same three-tier GitOps cascade you may have seen in the GitOps intro lab:

```
components/lab/<name>/values.yaml    ← your component defaults (lowest specificity)
        ↓  merged by the orchestrator
groups/lab-group/values.yaml         ← group-level overrides
        ↓  merged by the orchestrator
cluster/lab-cluster/values.yaml      ← cluster-level overrides (highest specificity)
        ↓
ArgoCD deploys the result
```

**The key addition in this lab:** the cluster values file also holds an `argo:` block containing `syncPolicy` and `ignoreDifferences` settings. The orchestrator extracts this block and applies it to the ArgoCD Application CRD — you never edit the Application CRD directly. Sync settings live in Git, versioned alongside your application values.

```
cluster/lab-cluster/values.yaml
  └── lab-cluster-components:
        └── <name>:
              ├── replicaCount: 1        ← passed to Helm chart
              ├── greeting: "Hello!"     ← passed to Helm chart
              └── argo:                  ← extracted by orchestrator, applied to Application CRD
                    ├── syncPolicy: ...
                    └── ignoreDifferences: ...
```

Each exercise follows the same loop:

1. **Observe** — look at the current state in the ArgoCD UI
2. **Change** — edit one or more files in the cascade (or a component template)
3. **Commit and push** — `git add . && git commit -m "exercise N" && git push`
4. **Observe the result** — in the ArgoCD UI and with `oc`

---

## Prerequisites

- Git installed and configured (`git config --global user.name` and `user.email` set)
- Access to push to the shared lab repo (URL provided by instructor)
- `oc` CLI access to the lab cluster
- ArgoCD UI URL (provided by instructor)

---

## Setup — Register Your Component

**Complete this before your first session.** Your component stays registered for all three sessions — you do not repeat this setup.

Replace `<name>` throughout with your first name or a unique identifier (lowercase, no spaces).

### Step 0.1 — Clone and verify

```bash
git clone <repo-url>
cd <repo-name>
```

Open the ArgoCD UI. Find the `example` Application and confirm it is **Synced** and **Healthy**. This is your working reference.

### Step 0.2 — Copy the example component

```bash
cp -r labs/lab-argocd-sync/components/lab/example \
      labs/lab-argocd-sync/components/lab/<name>
```

Open `labs/lab-argocd-sync/components/lab/<name>/values.yaml` and update these two fields:

```yaml
appName: <name>

greeting: "Hello from <name>!"
```

`appName` is used as both the name and the namespace for every resource this chart creates.

### Step 0.3 — Register your component

Open `labs/lab-argocd-sync/bootstrap/helm-values/applications.yaml` and add your component:

```yaml
availableApplications:
  example:
    path: labs/lab-argocd-sync/components/lab/example
  <name>:                                               # add these two lines
    path: labs/lab-argocd-sync/components/lab/<name>
```

### Step 0.4 — Enable in the group

Open `labs/lab-argocd-sync/groups/lab-group/values.yaml` and add your component:

```yaml
lab-group-components:
  example: {}
  <name>: {}      # add this line
```

### Step 0.5 — Add a cluster-level entry

Open `labs/lab-argocd-sync/cluster/lab-cluster/values.yaml` and add your entry:

```yaml
lab-cluster-components:
  example:
    replicaCount: 1
    greeting: "Cluster says: hello from example!"
  <name>:
    replicaCount: 1
    greeting: "Cluster says: hello from <name>!"
```

No `argo:` block yet — your component starts in manual sync mode. Session 1 begins here.

### Step 0.6 — Commit and push

```bash
git add .
git commit -m "register <name> component"
git push
```

### Step 0.7 — Verify

Open the ArgoCD UI. Within a few minutes the `sync-lab-orchestrator` Application syncs and creates your Application `<name>`. It should show **OutOfSync** (no syncPolicy configured). Do not sync it yet — Session 1 starts from this state.

---

## Cleanup

Run this after your final session.

```bash
# Remove your component from the three cascade files
# (edit applications.yaml, lab-group/values.yaml, lab-cluster/values.yaml)
# then remove your component folder
git rm -r labs/lab-argocd-sync/components/lab/<name>/
git add labs/lab-argocd-sync/bootstrap/helm-values/applications.yaml \
        labs/lab-argocd-sync/groups/lab-group/values.yaml \
        labs/lab-argocd-sync/cluster/lab-cluster/values.yaml
git commit -m "cleanup <name> component"
git push

# The orchestrator prunes your Application on its next sync.
# The finalizer removes the namespace automatically.
# If it lingers, delete manually:
oc delete namespace <name>
```

---

## Summary Reference Card

| Setting | Where | Effect |
|---------|-------|--------|
| `argo.syncPolicy.automated: {}` | cluster values | Enable automated sync |
| `argo.syncPolicy.automated.prune: true` | cluster values | Delete resources removed from Git |
| `argo.syncPolicy.automated.selfHeal: true` | cluster values | Revert manual cluster changes |
| `argo.syncPolicy.syncOptions: [CreateNamespace=true]` | cluster values | Auto-create destination namespace |
| `argo.syncPolicy.syncOptions: [ServerSideApply=true]` | cluster values | Use SSA for all resources |
| `argo.syncPolicy.syncOptions: [ApplyOutOfSyncOnly=true]` | cluster values | Skip already-synced resources |
| `argo.syncPolicy.syncOptions: [PruneLast=true]` | cluster values | Delete orphans after creating new resources |
| `argo.syncPolicy.syncOptions: [RespectIgnoreDifferences=true]` | cluster values | Suppress OutOfSync for ignored fields |
| `argo.syncPolicy.retry` | cluster values | Auto-retry failed syncs with backoff |
| `argo.ignoreDifferences` | cluster values | Exclude specific fields from drift detection |
| `argocd.argoproj.io/sync-options: Prune=false` | Component template annotation | Never prune this resource |
| `argocd.argoproj.io/sync-options: Replace=true` | Component template annotation | Delete and recreate instead of patch |
| `argocd.argoproj.io/sync-options: ServerSideApply=true` | Component template annotation | SSA for this resource only |
| `argocd.argoproj.io/sync-wave: "N"` | Component template annotation | Set sync order (lower = earlier) |
| `argocd.argoproj.io/hook: PreSync` | Component template annotation | Run before sync begins |
| `argocd.argoproj.io/hook: PostSync` | Component template annotation | Run after all resources are healthy |
| `argocd.argoproj.io/hook: SyncFail` | Component template annotation | Run only if sync failed |
| `argocd.argoproj.io/hook-delete-policy: HookSucceeded` | Component template annotation | Delete hook resource after success |
| `argocd.argoproj.io/hook-delete-policy: BeforeHookCreation` | Component template annotation | Delete previous instance before re-creating |

---

## Troubleshooting

**My Application does not appear in ArgoCD after pushing**
- Confirm all three cascade files were saved and committed: `git status` should show nothing
- Check `bootstrap/helm-values/applications.yaml` — indentation must be consistent YAML
- Look for a sync error on the `sync-lab-orchestrator` Application in the ArgoCD UI

**Application is OutOfSync but not self-healing**
- Confirm `selfHeal: true` is nested under `automated:` inside the `argo:` block
- Click **Refresh** in the ArgoCD UI to force an immediate drift check

**Application shows OutOfSync immediately after syncing**
- ArgoCD may be detecting a field modified by Kubernetes (like `defaultMode`)
- Add `argo.ignoreDifferences` and `RespectIgnoreDifferences=true` to your cluster values (Session 2, Exercise 9)

**Hook Job shows "BackoffLimitExceeded"**
- The container exited non-zero — check `oc logs job/<hook-name> -n <name>`
- ArgoCD blocks the sync (for PreSync hooks) until the Job succeeds

**selfHeal is set but not reverting changes**
- The orchestrator must complete its own sync before the child Application's policy updates
- Check that your Application's `syncPolicy` in the ArgoCD UI shows `selfHeal: true`

**ignoreDifferences is not suppressing OutOfSync**
- Confirm the JSON Pointer path exactly matches the live resource:
  ```bash
  oc get deployment <name> -n <name> -o json \
    | python3 -c "import json,sys; d=json.load(sys.stdin); \
                  print(d['spec']['template']['spec']['volumes'][0]['configMap'])"
  ```
- Verify `RespectIgnoreDifferences=true` is also in `syncOptions`

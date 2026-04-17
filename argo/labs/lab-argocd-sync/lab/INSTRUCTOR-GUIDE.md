# Instructor Guide — ArgoCD Sync Settings Lab

## Overview

This lab teaches ArgoCD sync configuration through ten progressive hands-on exercises. Participants use the same three-tier GitOps cascade from the GitOps intro lab (components → group → cluster), but the cluster values file now also controls `syncPolicy`, `syncOptions`, `ignoreDifferences`, and `retry` — exposing a new dimension of the cascade without requiring participants to touch any ArgoCD CRD directly.

The session runs approximately 2 hours for all ten exercises. A focused 1-hour session covering Exercises 1–6 is the recommended starting point for audiences new to ArgoCD.

---

## How It Differs from the GitOps Intro Lab

| Feature | GitOps intro lab | This lab |
|---------|-----------------|----------|
| Framework | Components / groups / cluster cascade | Same |
| Participants edit | `values.yaml`, cascade files | `values.yaml`, cascade files, **and Helm templates** |
| ArgoCD Application CRD | Never touched by participants | Never touched by participants |
| Sync settings | Fixed (set by orchestrator) | **Controlled via cluster values** |
| Template annotations | Not covered | Exercises 6–8 |

The meta-lesson: sync settings are just another set of values in your GitOps cascade — not a one-time UI configuration.

---

## Pre-Lab Setup Checklist

Complete all steps below before participants arrive.

### 1. Cluster and ArgoCD

- [ ] Kubernetes or OpenShift cluster is running and reachable
- [ ] ArgoCD **2.6 or later** is installed — the multiple-sources feature used by `root-app.yaml` requires 2.6+
  - Verify: `oc get deployment argocd-server -n argocd -o jsonpath='{.spec.template.spec.containers[0].image}'`
- [ ] All ArgoCD pods are Running: `oc get pods -n argocd`
- [ ] ArgoCD UI is accessible from participant workstations
- [ ] Participants can execute Jobs (busybox image) in their namespaces — required for Exercises 6b and 8
- [ ] The ArgoCD service account has permission to create Namespaces — required for `CreateNamespace=true` in Exercise 5a

### 2. Repository

- [ ] Lab repo is available and contains `argo/labs/lab-argocd-sync/`
- [ ] All participants have push access (or have forked the repo)
- [ ] Repo URL and credentials are ready to share
- [ ] `main` is the tracked branch (or update `targetRevision` in `argocd/root-app.yaml` to match)

### 3. Bootstrap the root app

Edit `argo/labs/lab-argocd-sync/argocd/root-app.yaml` and replace both `<YOUR-ORG>/<YOUR-REPO>` placeholders with the actual repo:

```bash
# Verify the file is updated
grep "YOUR-ORG" argo/labs/lab-argocd-sync/argocd/root-app.yaml
# Should return nothing if placeholders are replaced
```

Commit and push the updated root-app.yaml, then apply it:

```bash
oc apply -f argo/labs/lab-argocd-sync/argocd/root-app.yaml -n argocd
```

This is the **only `oc apply`** required. Everything else is managed by ArgoCD.

### 4. Verify the orchestrator and reference component

After applying, open the ArgoCD UI and confirm:

- [ ] `sync-lab-orchestrator` Application is **Synced / Healthy**
- [ ] `example` Application is present and **OutOfSync** (no syncPolicy is set — manual sync required)

Manually sync the `example` Application and confirm it goes **Synced / Healthy** before the lab starts.

```bash
# Verify the example resources deployed correctly
oc get pods -n example
oc get route example -n example
```

- [ ] Reference `example` Application is **Synced / Healthy**

### 5. Distribute to participants

Share before **Session 1** (participants keep these for all sessions):

- Git repo URL and credentials (or fork instructions)
- ArgoCD UI URL
- ArgoCD credentials
- Link to `lab/LAB-OVERVIEW.md` — the index and reference document
- Link to the session guide for today: `LAB-SESSION-1.md`, `LAB-SESSION-2.md`, or `LAB-SESSION-3.md`

---

## Session Agendas

The lab is split into three independent one-hour sessions. Session 1 is the prerequisite for Sessions 2 and 3 (Sessions 2 and 3 are independent of each other).

### Session 1 — Sync Modes (~60 min)
*Exercises 1–4 · File: `LAB-SESSION-1.md`*

| Time | Activity |
|------|----------|
| 0:00 | Welcome — what are sync modes and why do they matter? |
| 0:05 | Concept overview — cascade diagram, how sync settings flow through `argo:` block |
| 0:10 | Live instructor demo — register `demo`, push, observe OutOfSync → Synced → selfHeal |
| 0:20 | Participants complete Setup (LAB-OVERVIEW.md Step 0) |
| 0:35 | Exercise 1 — Manual Sync |
| 0:43 | Exercise 2 — Automated Sync |
| 0:51 | Exercise 3 — Prune |
| 0:57 | Exercise 4 — Self-Heal |
| 1:00 | Debrief — the `argo:` block at end of session, what's next |

### Session 2 — Application-Level Controls (~60 min)
*Exercises 5, 9, 10 · File: `LAB-SESSION-2.md`*

| Time | Activity |
|------|----------|
| 0:00 | Recap — where we left off, the `argo:` block, session theme |
| 0:05 | Exercise 5 — SyncOptions (walk through all 5 flags) |
| 0:25 | Exercise 9 — ignoreDifferences (pairs with 5e RespectIgnoreDifferences) |
| 0:40 | Exercise 10 — Retry Policy |
| 0:50 | Stretch goal — change greeting live |
| 0:55 | Debrief — what's in Session 3 |

### Session 3 — Resource-Level Control (~60 min)
*Exercises 6, 7, 8 · File: `LAB-SESSION-3.md`*

| Time | Activity |
|------|----------|
| 0:00 | Recap — Application-level vs resource-level control |
| 0:05 | Exercise 6 — Per-Resource Annotations (Prune=false, Replace=true) |
| 0:20 | Exercise 7 — Sync Waves |
| 0:35 | Exercise 8 — Sync Hooks |
| 0:55 | Debrief — end-state review, cleanup walkthrough |

---

## Live Demo Script

Walk through this before participants start their hands-on work. Narrate every decision.

```bash
# Step 1 — copy the example component
cp -r argo/labs/lab-argocd-sync/components/lab/example \
      argo/labs/lab-argocd-sync/components/lab/demo

# Step 2 — update values.yaml
# Edit components/lab/demo/values.yaml:
#   appName: demo
#   greeting: "Hello from the instructor demo!"

# Step 3 — register in the component registry
# Edit bootstrap/helm-values/applications.yaml:
#   demo:
#     path: argo/labs/lab-argocd-sync/components/lab/demo

# Step 4 — enable in the group
# Edit groups/lab-group/values.yaml:
#   lab-group-components:
#     demo: {}

# Step 5 — add a cluster entry with NO argo: block (manual sync for Exercise 1)
# Edit cluster/lab-cluster/values.yaml:
#   lab-cluster-components:
#     demo:
#       replicaCount: 1
#       greeting: "Cluster says: hello from demo!"

# Step 6 — commit and push
git add .
git commit -m "add demo component"
git push
```

After pushing, switch to the ArgoCD UI and show:
1. `sync-lab-orchestrator` refreshes and creates the `demo` Application
2. `demo` appears as **OutOfSync** (no syncPolicy)
3. Click **Sync** to demonstrate manual sync

Then narrate: **"To enable automated sync, we don't edit any ArgoCD CRD — we add an `argo:` block to our cluster values file."**

Add automated sync to `cluster/lab-cluster/values.yaml`:

```yaml
demo:
  replicaCount: 1
  greeting: "Cluster says: hello from demo!"
  argo:
    syncPolicy:
      automated:
        prune: true
        selfHeal: true
```

Push, and show the orchestrator updating the `demo` Application's `syncPolicy` in real time.

---

## Concept Overview (5-minute talk track)

Use this for the introduction whiteboard segment.

```
Git (source of truth)
        ↓  ArgoCD polls every ~3 minutes (or via webhook)
sync-lab-orchestrator detects cascade file changes
        ↓  re-renders orchestrator chart → updates child Application CRDs
Child Application CRDs reflect the merged syncPolicy from cluster values
        ↓  each child Application reconciles its own workload
Cluster converges to Git state
```

Key points to emphasize:
- Sync settings live in the same cascade files as app values — no separate "ArgoCD config" to manage
- Changing `prune: true` in a values file is the same workflow as changing `replicaCount`
- The orchestrator is the only ArgoCD Application the instructor manages; participants never `oc apply` anything

---

## Exercise-by-Exercise Notes

### Setup (Step 0)

Participants need to edit **four files** before their Application appears. This is the same pattern as the GitOps intro lab:

1. `components/lab/<name>/values.yaml` — appName and greeting
2. `bootstrap/helm-values/applications.yaml` — component registry entry
3. `groups/lab-group/values.yaml` — enable in group
4. `cluster/lab-cluster/values.yaml` — cluster entry (no `argo:` block initially)

If a participant's Application doesn't appear after pushing, the most common cause is a missing or misspelled entry in one of these four files.

### Exercise 1 — Manual Sync

Draw the contrast: ArgoCD shows OutOfSync (it sees the drift), but it will not act. This is deliberate — useful for change-controlled environments where a human must approve every deployment.

Show the **App Diff** view before syncing so participants understand what ArgoCD is about to do.

### Exercise 2 — Automated Sync

The "aha moment" for most participants. After adding `syncPolicy.automated: {}` to cluster values and pushing, they see the orchestrator update their Application and then watch the Application auto-sync — no UI button click.

Explicitly call out: the participant edited a values file, not an ArgoCD Application CRD. The cascade framework propagated the change.

### Exercise 3 — Prune

The most important conceptual exercise. Spend extra time here.

Two states to contrast:
1. Without prune: deleted template → orphaned resource on cluster → "ghost resources" ArgoCD no longer manages
2. With prune: deleted template → resource removed from cluster → Git is 100% authoritative

Real-world risk to discuss: enabling prune on an Application that manages resources also created by other processes (e.g., a CI pipeline creating Jobs). Those would be pruned on the next sync. This is why Exercise 6a (per-resource `Prune=false`) exists.

### Exercise 4 — Self-Heal

The live `oc scale` → wait → automatic revert cycle is the most dramatic demo in the lab. Run it with the ArgoCD UI visible and watch the timeline update.

Mention: selfHeal fires on the ArgoCD refresh interval (~3 minutes default). In production, use webhooks for faster response.

### Exercise 5 — SyncOptions

Prioritized order for time-constrained sessions:

1. `CreateNamespace=true` — almost everyone needs this
2. `ServerSideApply=true` — important for CRDs
3. `PruneLast=true` — production safety improvement
4. `ApplyOutOfSyncOnly=true` — optimization for large apps
5. `RespectIgnoreDifferences=true` — pair with Exercise 9

### Session 2 — Exercise 5 (SyncOptions)

Prioritized order if time is tight: CreateNamespace → PruneLast → RespectIgnoreDifferences → ServerSideApply → ApplyOutOfSyncOnly. The first three are most universally applicable.

### Session 2 — Exercise 9 (ignoreDifferences)

Taught immediately after Exercise 5 because `RespectIgnoreDifferences=true` (introduced in 5e) only makes sense alongside `ignoreDifferences`. Teaching them back-to-back removes the confusion of "I set this flag but nothing changed."

Important clarification: `ignoreDifferences` does NOT prevent ArgoCD from applying changes to those fields when Git changes them. It only prevents ArgoCD from treating changes made by external systems as drift.

### Session 2 — Exercise 10 (Retry)

Focus on the exponential backoff math:
- Attempt 1: immediate
- Attempt 2: 5s later
- Attempt 3: 10s later
- Attempt 4: 20s later
- Attempt 5: 40s later → SyncFailed

Retry is especially relevant for environments with admission webhook validators or ordering-sensitive CRDs.

### Session 3 — Exercise 6 (Per-Resource Annotations)

Exercise 6a (Prune=false) surprises most participants: "You can have `prune: true` at the Application level but protect specific resources." This is the right answer to "but what about PVCs and Secrets I don't want deleted?"

Exercise 6b (Replace=true): the "Job is immutable" error is one of the most common production surprises for GitOps newcomers. This exercise de-mystifies it.

### Session 3 — Exercise 7 (Sync Waves)

The key point: waves are **health gates**, not just ordering hints. ArgoCD does not proceed to wave N+1 until all resources in wave N are **Healthy**. A misconfigured readinessProbe in wave 0 blocks wave 1 indefinitely.

Suggested real-world example: deploying a CRD (wave -1) before any Custom Resources that use it (wave 0+). Without waves, the Application fails with "no matches for kind X" on first deploy.

### Session 3 — Exercise 8 (Sync Hooks)

Run `oc logs job/pre-sync-check -n <participant-name> --follow` during a live sync to show the hook output in real time.

Mention SyncFail hooks even though they are not in the exercises: this is where you'd add Slack alerts, PagerDuty calls, or rollback jobs.

---

## Common Participant Issues

### Application does not appear after pushing all four files

1. Check `git log --oneline` — confirm the push succeeded
2. Verify `bootstrap/helm-values/applications.yaml` indentation (YAML spaces, not tabs)
3. In the ArgoCD UI, force a refresh on `sync-lab-orchestrator`
4. Look for a sync error on `sync-lab-orchestrator` — it will show YAML parse errors

### selfHeal set in cluster values but Application still not reverting changes

The orchestrator Application must complete its own sync before the child Application's policy updates. After pushing to cluster values:
1. The orchestrator syncs and updates the `<name>` Application CRD (takes ~1-3 minutes)
2. Only then does the child Application's self-heal policy take effect

Ask the participant to check their Application in the UI and confirm `selfHeal: true` is shown in the App Details view.

### Hook Job pending or ImagePullBackOff

The `busybox:stable` image pull failed (air-gapped environment or registry restrictions). Ask participants to use an image available on their cluster:

```bash
# Find a working image that can run a shell
oc get is -n openshift | grep -E "busybox|alpine|ubi"
```

Update the Job template to use that image.

### ignoreDifferences JSON Pointer path does not suppress OutOfSync

JSON Pointer paths are 0-indexed and exact. Help the participant find the correct path:

```bash
oc get deployment <name> -n <name> -o json \
  | python3 -c "
import json, sys
d = json.load(sys.stdin)
vols = d['spec']['template']['spec']['volumes']
for i, v in enumerate(vols):
    print(f'Volume {i}:', json.dumps(v, indent=2))
"
```

Also confirm `RespectIgnoreDifferences=true` is in `syncOptions`.

### Two participants used the same `<name>`

The second push will conflict — both entries try to deploy to the same namespace. One of them needs to rename their component folder, update the appName in values.yaml, and update all three cascade files. Remind everyone to choose a unique identifier before starting.

---

## Debrief Talking Points

- **Why not enable everything?** Each feature has a trade-off. `selfHeal: true` means no manual emergency patching. `prune: true` means a bad Git push can delete production resources. Enable incrementally as you understand your workload.

- **Production starting template:**
  ```yaml
  argo:
    syncPolicy:
      automated:
        prune: true
        selfHeal: true
      syncOptions:
        - CreateNamespace=true
        - PruneLast=true
        - RespectIgnoreDifferences=true
      retry:
        limit: 5
        backoff:
          duration: 5s
          factor: 2
          maxDuration: 3m
  ```
  Add `ignoreDifferences` entries as needed for HPAs and admission webhooks.

- **Hooks vs sync waves:** Waves are for ordering persistent workload resources. Hooks are for one-time tasks that run during a sync (validation, notification, smoke test). A database migration Job is a hook. A ConfigMap that a Deployment depends on is a wave.

- **The GitOps contract:** With `automated + prune + selfHeal` all enabled, Git is 100% authoritative. No one should `oc edit` a managed resource — not even in an emergency. The right response to an incident is to push a Git commit.

---

## Cleanup After the Lab

```bash
# Delete all participant Applications (cascade-delete removes cluster resources)
oc get applications -n argocd -l managed-by=sync-lab-orchestrator \
  -o name | xargs oc delete -n argocd

# Remove the orchestrator root app
oc delete application sync-lab-orchestrator -n argocd

# Clean up any lingering namespaces
oc get namespaces --no-headers \
  | awk '{print $1}' \
  | grep -v -E '^(kube|openshift|argocd|default)' \
  | xargs oc delete namespace

# Revert participant commits in git
git log --oneline | head -20  # find the commit before the lab started
git revert HEAD~<N>..HEAD     # revert N commits
git push
```

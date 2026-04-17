# Session 3 — Resource-Level Control

> **CLI note:** All commands use `oc`. Every `oc` command works identically with `kubectl`.

**Theme:** How do individual resources behave during a sync?

**Exercises:** 6 (Per-Resource Annotations) · 7 (Sync Waves) · 8 (Sync Hooks)

**Time:** ~60 minutes

---

## Before You Start

- Complete [Session 1](LAB-SESSION-1.md) first.
- Your Application `<name>` should be **Synced / Healthy** with at minimum `automated + prune + selfHeal` active.
- This session focuses on editing your **component's Helm templates** (`components/lab/<name>/templates/`) rather than the cluster values file.

---

## Exercise 6 — Per-Resource Sync Annotations

Individual Kubernetes resources can carry `argocd.argoproj.io/sync-options` annotations that override the Application-level sync behavior for just that resource. These annotations go in the Helm templates of your component.

### 6a — Prune=false (protect a resource from deletion)

Some resources should never be deleted by ArgoCD even when `prune: true` is set at the Application level — PersistentVolumeClaims containing data, manually-populated Secrets, or resources managed by a separate process.

Add a new template to your component. Create `argo/labs/lab-argocd-sync/components/lab/<name>/templates/protected-configmap.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Values.appName }}-protected
  namespace: {{ .Values.appName }}
  annotations:
    argocd.argoproj.io/sync-options: Prune=false
  labels:
    app: {{ .Values.appName }}
data:
  note: "This ConfigMap is protected from ArgoCD pruning."
```

Commit and push. ArgoCD creates the ConfigMap. Now delete the template file:

```bash
rm argo/labs/lab-argocd-sync/components/lab/<name>/templates/protected-configmap.yaml
git add .
git commit -m "exercise 6a - delete protected configmap template"
git push
```

After sync:

```bash
oc get configmap <name>-protected -n <name>
```

The ConfigMap survives. The `Prune=false` annotation on the resource overrides the Application-level `prune: true` setting.

> **Key takeaway:** `Prune=false` is an explicit contract: "this resource has a lifecycle independent of the Application." This is the right answer to "but I don't want ArgoCD to delete my PVC."

### 6b — Replace=true (force resource recreation)

Certain resource types cannot be updated with a patch — notably Jobs (immutable spec) and some CRDs. The `Replace=true` annotation tells ArgoCD to delete and recreate the resource on every sync rather than attempting a patch.

Create `argo/labs/lab-argocd-sync/components/lab/<name>/templates/init-job.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Values.appName }}-init
  namespace: {{ .Values.appName }}
  annotations:
    argocd.argoproj.io/sync-options: Replace=true
  labels:
    app: {{ .Values.appName }}
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: init
          image: busybox:stable
          command: ["sh", "-c", "echo Initialization complete"]
```

Commit and push. On each subsequent sync, ArgoCD deletes and recreates this Job rather than attempting a patch.

> **Caution:** `Replace=true` causes disruption on every sync. Use it only for resource types that genuinely require it.

### 6c — ServerSideApply=true (per-resource)

You can enable server-side apply for a single resource without switching the entire Application to SSA mode:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-options: ServerSideApply=true
```

This is useful when one CRD or large resource needs SSA while the rest of the Application uses client-side apply.

---

## Exercise 7 — Sync Waves

**Concept:** Sync waves control the order in which ArgoCD processes resources during a sync. Resources with a lower wave number are applied first. Resources in the same wave are applied in parallel. ArgoCD waits for all resources in wave N to become **healthy** before advancing to wave N+1 — waves are health gates, not just ordering hints.

The default wave is `0`. Negative numbers are valid.

### Add wave annotations to your component templates

Edit `templates/namespace.yaml` — wave `-1` (must exist before everything else):

```yaml
metadata:
  name: {{ .Values.appName }}
  annotations:
    argocd.argoproj.io/sync-wave: "-1"
  labels:
    app: {{ .Values.appName }}
```

Edit `templates/configmap.yaml` — wave `0` (explicitly mark the default):

```yaml
metadata:
  name: {{ .Values.appName }}-html
  namespace: {{ .Values.appName }}
  annotations:
    argocd.argoproj.io/sync-wave: "0"
```

Edit `templates/deployment.yaml` and `templates/service.yaml` — wave `1` (after ConfigMap is present):

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"
```

Commit and push:

```bash
git add .
git commit -m "exercise 7 - add sync waves"
git push
```

In the ArgoCD UI, force a re-sync (**Sync** → **Synchronize**). Watch the progress in the **App Details** view — ArgoCD processes wave -1, then wave 0, then wave 1, pausing between waves to verify health.

> **Key takeaway:** Use sync waves to enforce ordering guarantees — Namespaces and CRDs before everything else, then ConfigMaps and Secrets, then Deployments. A misconfigured readiness probe in wave 0 will block wave 1 indefinitely, so waves expose health issues clearly.

---

## Exercise 8 — Sync Hooks

**Concept:** Sync hooks are Kubernetes resources annotated with `argocd.argoproj.io/hook`. ArgoCD runs them at specific points in the sync lifecycle rather than managing them as persistent workload resources.

| Hook Phase | When it runs |
|------------|--------------|
| `PreSync` | Before any resources are applied. Sync is blocked until this succeeds. |
| `Sync` | During sync, alongside normal resources (same as wave 0). |
| `PostSync` | After all resources are Synced and Healthy. |
| `SyncFail` | Only if the sync failed. Use for alerting or rollback. |
| `Skip` | Never applied — useful for documentation resources in the directory. |

Hook resources are not included in the Application's persistent resource tree. They are created, run, and cleaned up according to their delete policy.

### Hook delete policies

| Policy | Behavior |
|--------|----------|
| `HookSucceeded` | Delete the hook resource after it succeeds. |
| `HookFailed` | Delete the hook resource after it fails. |
| `BeforeHookCreation` | Delete any existing instance before creating a new one. Handles repeated syncs cleanly. |

### Add a PreSync hook

Create `argo/labs/lab-argocd-sync/components/lab/<name>/templates/pre-sync-check.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pre-sync-check
  namespace: {{ .Values.appName }}
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/hook-delete-policy: BeforeHookCreation
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: check
          image: busybox:stable
          command:
            - sh
            - -c
            - |
              echo "=== Pre-sync check ==="
              echo "Verifying prerequisites..."
              sleep 2
              echo "All checks passed."
```

### Add a PostSync hook

Create `argo/labs/lab-argocd-sync/components/lab/<name>/templates/post-sync-notify.yaml`:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: post-sync-notify
  namespace: {{ .Values.appName }}
  annotations:
    argocd.argoproj.io/hook: PostSync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: notify
          image: busybox:stable
          command:
            - sh
            - -c
            - |
              echo "=== Post-sync notification ==="
              echo "Sync completed successfully."
```

Commit and push:

```bash
git add .
git commit -m "exercise 8 - add pre and post sync hooks"
git push
```

### Observe hook execution

In the ArgoCD UI, force a sync (**Sync** → **Synchronize**). Watch the timeline in **App Details**:

1. `pre-sync-check` Job is created and must complete successfully
2. Normal resources are applied in wave order (-1, 0, 1)
3. `post-sync-notify` Job runs and is deleted on success (due to `HookSucceeded`)
4. `pre-sync-check` is deleted before the next sync (due to `BeforeHookCreation`)

Watch the Job logs live:

```bash
oc logs job/pre-sync-check -n <name>
oc logs job/post-sync-notify -n <name>
```

### Hooks and waves together

Hooks interact with waves as follows:
- `PreSync` hooks always run before wave -1 (before any normal resource)
- `PostSync` hooks always run after the highest wave completes and all resources are healthy
- Hook wave annotations are supported for ordering multiple hooks of the same phase

> **Key takeaway:** PreSync hooks for pre-flight validation, PostSync hooks for notifications or smoke tests, SyncFail hooks for incident response automation. In a real environment, these Jobs would call external APIs — Slack webhooks, PagerDuty, smoke test runners, rollback scripts.

---

## End of Session 3

Your component now has:

**Cluster values** (`cluster/lab-cluster/values.yaml`):
```yaml
<name>:
  argo:
    syncPolicy:
      automated: {prune: true, selfHeal: true}
      syncOptions: [CreateNamespace=true, PruneLast=true, RespectIgnoreDifferences=true]
      retry: {limit: 5, backoff: {duration: 5s, factor: 2, maxDuration: 3m}}
    ignoreDifferences:
      - {group: apps, kind: Deployment, jsonPointers: [/spec/replicas]}
```

**Component templates** (`components/lab/<name>/templates/`):
- `namespace.yaml` — wave -1
- `configmap.yaml` — wave 0
- `deployment.yaml` + `service.yaml` — wave 1
- `pre-sync-check.yaml` — PreSync hook
- `post-sync-notify.yaml` — PostSync hook

When you're done, follow the **Cleanup** steps in [LAB-OVERVIEW.md](LAB-OVERVIEW.md).

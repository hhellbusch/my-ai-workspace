# Session 2 — Application-Level Controls

> **CLI note:** All commands use `oc`. Every `oc` command works identically with `kubectl`.

**Theme:** How does ArgoCD apply resources to the cluster?

**Exercises:** 5 (SyncOptions) · 9 (ignoreDifferences) · 10 (Retry)

> Exercise 9 (ignoreDifferences) is covered in this session rather than its original position because it pairs directly with the `RespectIgnoreDifferences=true` syncOption introduced in Exercise 5e.

**Time:** ~60 minutes

---

## Before You Start

- Complete [Session 1](LAB-SESSION-1.md) first, or ensure your cluster values entry already has:

```yaml
lab-cluster-components:
  <name>:
    replicaCount: 1
    greeting: "Cluster says: hello from <name>!"
    argo:
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

- Your Application `<name>` should be **Synced / Healthy** in the ArgoCD UI.

---

## Exercise 5 — SyncOptions

`syncOptions` is a list of feature flags that change **how** ArgoCD applies resources. They operate at the Application level and affect every resource the Application manages.

Add them to your cluster values under `argo.syncPolicy`:

```yaml
argo:
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### 5a — CreateNamespace

`CreateNamespace=true` tells ArgoCD to create the destination namespace automatically if it does not exist, even when there is no Namespace resource in Git.

Your component already includes a `namespace.yaml` template, so this flag is not required for initial deployment. However it acts as a safety net — if someone deletes the Namespace template from Git by mistake, ArgoCD recreates the namespace rather than failing the sync.

**To test it:** Delete `templates/namespace.yaml` from your component, push, and observe the namespace continues to exist and sync succeeds. Then restore the file.

### 5b — ServerSideApply

`ServerSideApply=true` switches ArgoCD from client-side `oc apply` to server-side apply for every resource. This is required for resources that are too large for the `kubectl.kubernetes.io/last-applied-configuration` annotation, and recommended for CRDs.

```yaml
syncOptions:
  - CreateNamespace=true
  - ServerSideApply=true
```

After pushing and syncing, confirm server-side apply is active:

```bash
oc get deployment <name> -n <name> \
  -o jsonpath='{.metadata.managedFields}' | python3 -m json.tool | grep manager
```

You should see `argocd-controller` listed as a field manager.

> **Note:** Once you switch to server-side apply, reverting to client-side apply on an existing resource can require manual cleanup of `managedFields` entries.

### 5c — ApplyOutOfSyncOnly

By default, every sync re-applies all resources regardless of whether they have drifted. `ApplyOutOfSyncOnly=true` skips resources that are already synchronized, reducing API server load on large Applications.

```yaml
syncOptions:
  - CreateNamespace=true
  - ApplyOutOfSyncOnly=true
```

> **Caution:** This option skips resources that appear in sync. Use it only on stable, mature Applications where you trust the sync status.

### 5d — PruneLast

`PruneLast=true` defers all deletions to the very end of the sync — after every new or updated resource is healthy. This is the safer default for live workloads: create the replacement first, verify health, then remove the old resource.

```yaml
syncOptions:
  - CreateNamespace=true
  - PruneLast=true
```

### 5e — RespectIgnoreDifferences

Without this flag, the Application shows **OutOfSync** even for fields you have configured in `ignoreDifferences`. `RespectIgnoreDifferences=true` suppresses the OutOfSync status for those ignored fields.

```yaml
syncOptions:
  - RespectIgnoreDifferences=true
```

Add this now — you will configure the matching `ignoreDifferences` entries in Exercise 9 immediately below.

---

## Exercise 9 — ignoreDifferences

**Concept:** Some Kubernetes controllers modify resource fields after ArgoCD applies them — a HorizontalPodAutoscaler changes `spec.replicas`, an admission webhook injects containers, Kubernetes itself sets `defaultMode` on ConfigMap volume mounts. Without configuration, ArgoCD sees these as drift and marks the Application OutOfSync every cycle.

`ignoreDifferences` tells ArgoCD which specific fields to exclude from drift detection. It lives in the `argo:` block alongside `syncPolicy`.

### Simulate the problem

Check the live Deployment for the `defaultMode` field Kubernetes automatically sets:

```bash
oc get deployment <name> -n <name> \
  -o jsonpath='{.spec.template.spec.volumes[0].configMap}' | python3 -m json.tool
```

You will see `"defaultMode": 420` even though your `deployment.yaml` template does not specify it. Depending on your ArgoCD version this may or may not appear as drift — but it illustrates the class of problem.

### Add ignoreDifferences for the defaultMode field

Edit `cluster/lab-cluster/values.yaml`, building on what you set in Exercise 5:

```yaml
lab-cluster-components:
  <name>:
    replicaCount: 1
    greeting: "Cluster says: hello from <name>!"
    argo:
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
          - PruneLast=true
          - RespectIgnoreDifferences=true
      ignoreDifferences:
        - group: apps
          kind: Deployment
          jsonPointers:
            - /spec/template/spec/volumes/0/configMap/defaultMode
```

Commit and push. After the next sync, ArgoCD no longer reports `defaultMode` as drift.

### Ignore replicas (for HPA compatibility)

If a HorizontalPodAutoscaler manages your Deployment, ArgoCD and the HPA will fight over `spec.replicas`. Add it to `argo.ignoreDifferences`:

```yaml
argo:
  ignoreDifferences:
    - group: apps
      kind: Deployment
      jsonPointers:
        - /spec/replicas
        - /spec/template/spec/volumes/0/configMap/defaultMode
```

### Scope to a specific resource by name

```yaml
argo:
  ignoreDifferences:
    - group: apps
      kind: Deployment
      name: <name>
      namespace: <name>
      jsonPointers:
        - /spec/replicas
```

### Use JQ path expressions for complex matching

`jsonPointers` uses RFC 6901 syntax and matches exactly. `jqPathExpressions` uses `jq` syntax and supports wildcards:

```yaml
argo:
  ignoreDifferences:
    - group: apps
      kind: Deployment
      jqPathExpressions:
        - .spec.template.spec.containers[].image
```

This ignores the `image` field for every container — useful when a separate pipeline updates image tags directly on the cluster.

> **Key takeaway:** `ignoreDifferences` is not about ignoring problems — it acknowledges that some fields are legitimately managed outside of Git (by HPAs, admission webhooks, or Kubernetes itself). Always pair it with `RespectIgnoreDifferences=true` in `syncOptions`.

---

## Exercise 10 — Retry Policy

**Concept:** Sync can fail for transient reasons — a webhook timeout, a network blip, a CRD not yet established. The `retry` policy tells ArgoCD to automatically retry a failed sync before giving up.

### Add retry configuration

Edit `cluster/lab-cluster/values.yaml`:

```yaml
lab-cluster-components:
  <name>:
    replicaCount: 1
    greeting: "Cluster says: hello from <name>!"
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
            duration: 5s    # initial wait before first retry
            factor: 2       # multiply wait by this factor each retry
            maxDuration: 3m # cap the wait at this duration
      ignoreDifferences:
        - group: apps
          kind: Deployment
          jsonPointers:
            - /spec/replicas
```

Commit and push.

With this configuration, if a sync fails ArgoCD waits 5 seconds and retries. If it fails again: 10 seconds, 20 seconds, 40 seconds, 80 seconds (capped at 3 minutes). After 5 retries it gives up and the Application enters **SyncFailed** state.

### Observe retry behavior

To trigger a retry, temporarily break a template (e.g., reference a non-existent namespace), push, watch the retry attempts in the ArgoCD **Sync Status** panel, then fix and push the correction.

> **Key takeaway:** Retry with exponential backoff is especially valuable in environments with webhook validators, admission controllers, or ordering-sensitive CRDs.

---

## Stretch Goal — Change Your Greeting

Edit the `greeting` in `cluster/lab-cluster/values.yaml`, commit, and push:

```yaml
<name>:
  replicaCount: 2
  greeting: "Updated live by GitOps!"
  argo:
    ...
```

Refresh your browser after ArgoCD syncs — no restart, no `oc`, just a Git push.

---

## End of Session 2

Your `cluster/lab-cluster/values.yaml` entry for `<name>` should now look similar to:

```yaml
lab-cluster-components:
  <name>:
    replicaCount: 1
    greeting: "Cluster says: hello from <name>!"
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
      ignoreDifferences:
        - group: apps
          kind: Deployment
          jsonPointers:
            - /spec/replicas
```

**Coming up in Session 3:** Per-resource control — protecting individual resources from pruning, sync waves to enforce ordering, and lifecycle hooks.

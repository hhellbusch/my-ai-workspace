# Session 1 — Sync Modes

> **CLI note:** All commands use `oc`. Every `oc` command works identically with `kubectl`.

**Theme:** Does ArgoCD act? When? What happens to drift?

**Exercises:** 1 (Manual Sync) · 2 (Automated Sync) · 3 (Prune) · 4 (Self-Heal)

**Time:** ~60 minutes

---

## Before You Start

- Complete the **Setup** in [LAB-OVERVIEW.md](LAB-OVERVIEW.md) if you have not already.
- Your Application `<name>` should be visible in the ArgoCD UI showing **OutOfSync** with no syncPolicy configured.
- Do not sync it yet — Exercise 1 starts from this state.

---

## Exercise 1 — Manual Sync

**Concept:** By default, ArgoCD detects drift between Git and the cluster but takes no action. You must trigger a sync manually.

### Observe the OutOfSync state

Your Application is OutOfSync because the Namespace, ConfigMap, Deployment, Service, and Route exist in Git but not yet on the cluster. In the ArgoCD UI, click on your Application. In the **App Diff** view you can see every resource that would be created.

### Trigger a manual sync

Click **Sync** → **Synchronize** (leave all defaults).

Watch the resources appear. After a moment the Application transitions to **Synced / Healthy**.

### Visit your app

```bash
oc get route <name> -n <name> -o jsonpath='{.spec.host}{"\n"}'
```

Open that URL in your browser — you should see the `greeting` text from your cluster-level values.

### Introduce manual drift

```bash
oc scale deployment <name> -n <name> --replicas=3
```

Wait 1–2 minutes, then click **Refresh** in the ArgoCD UI. The Application becomes **OutOfSync** — ArgoCD detected the change. But the Deployment is still running 3 replicas. ArgoCD has not touched it.

> **Key takeaway:** Manual sync mode — ArgoCD detects drift but never corrects it automatically. You decide when to sync.

### Restore desired state

Click **Sync** → **Synchronize** to bring replicas back to 1.

---

## Exercise 2 — Automated Sync

**Concept:** `automated` sync turns ArgoCD into a continuous reconciliation loop. Changes committed to Git are applied to the cluster without manual intervention.

### Enable automated sync

Open `labs/lab-argocd-sync/cluster/lab-cluster/values.yaml` and add an `argo:` block to your component entry:

```yaml
lab-cluster-components:
  <name>:
    replicaCount: 1
    greeting: "Cluster says: hello from <name>!"
    argo:
      syncPolicy:
        automated: {}
```

Commit and push:

```bash
git add .
git commit -m "exercise 2 - enable automated sync"
git push
```

The orchestrator detects the change and updates your Application's `syncPolicy`. Within a minute ArgoCD enters its first automated sync cycle.

### Test it

Edit `labs/lab-argocd-sync/components/lab/<name>/templates/configmap.yaml`. Change the `<h1>` line:

```html
<h1>Auto-synced by ArgoCD!</h1>
```

Commit and push. Watch the ArgoCD UI — the Application goes **OutOfSync** briefly, then automatically syncs to **Synced / Healthy** without you clicking anything. Refresh your browser to confirm.

> **Key takeaway:** `automated: {}` is the standard production setting. Commits in Git become cluster reality within 3 minutes (ArgoCD's default polling interval) or sooner if you use webhooks.

---

## Exercise 3 — Prune

**Concept:** When a resource is removed from Git, what should happen to the live resource? Without `prune`, nothing — the resource stays on the cluster indefinitely as an orphan. With `prune: true`, ArgoCD deletes it.

### Observe the default (no prune)

Your component chart includes `templates/extra-configmap.yaml`. Confirm it was deployed:

```bash
oc get configmap <name>-extra -n <name>
```

Now delete the template file from your component:

```bash
rm labs/lab-argocd-sync/components/lab/<name>/templates/extra-configmap.yaml
git add .
git commit -m "exercise 3 - remove extra-configmap, no prune yet"
git push
```

Wait for the automated sync to complete. Check whether the ConfigMap still exists:

```bash
oc get configmap <name>-extra -n <name>
```

It is still there. ArgoCD synced successfully but left the orphaned resource untouched. In the ArgoCD UI the Application shows **Synced** — but the resource lives on the cluster, unmanaged.

### Enable prune

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
```

Commit and push. After the next sync:

```bash
oc get configmap <name>-extra -n <name>
# Error from server (NotFound): configmaps "<name>-extra" not found
```

The ConfigMap is gone. ArgoCD pruned the orphaned resource.

> **Key takeaway:** Always enable `prune: true` in production unless a resource must survive independently of Git — Session 3 covers the per-resource annotation that handles that exception.

---

## Exercise 4 — Self-Heal

**Concept:** `selfHeal: true` makes the cluster truly immutable. Any manual change made directly to the cluster is automatically reverted to match Git.

### Observe the gap (automated + prune, no selfHeal)

With your current config, manually scale the Deployment:

```bash
oc scale deployment <name> -n <name> --replicas=5
```

Wait 2–3 minutes and check:

```bash
oc get deployment <name> -n <name> -o jsonpath='{.spec.replicas}{"\n"}'
```

Still 5. The Application shows **OutOfSync** in ArgoCD, but it does not revert the change — `selfHeal` is not enabled.

### Enable selfHeal

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
```

Commit and push. After ArgoCD updates the Application, scale the Deployment manually again:

```bash
oc scale deployment <name> -n <name> --replicas=5
```

Within about 60 seconds ArgoCD detects the drift and reverts the Deployment back to 1 replica.

> **Key takeaway:** `selfHeal: true` is recommended for production. Git becomes the only valid way to change cluster state. Direct `oc` edits are treated as noise and overwritten.

---

## End of Session 1

Your `cluster/lab-cluster/values.yaml` entry for `<name>` should now look like this:

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

Your Application in the ArgoCD UI should be **Synced / Healthy** with automated sync, prune, and selfHeal all active.

**Coming up in Session 2:** How ArgoCD applies resources — syncOptions flags, drift suppression with ignoreDifferences, and retry on failure.

# GitOps Lab — Adding a Component with ArgoCD

## What You Will Do

You will add a new application component to a live Kubernetes cluster **without ever running `oc apply`**. Instead, you will commit files to a Git repository and ArgoCD will detect the change and deploy it automatically.

By the end of this lab you will have:
- A running nginx Deployment, Service, and OpenShift Route on the cluster
- A public URL serving your own custom greeting message
- Hands-on experience with the components / groups / cluster cascade pattern
- Seen ArgoCD reconcile a live configuration change in real time

---

## How the System Works

The GitOps repo is organized into three tiers that work like CSS specificity — lower tiers provide defaults, higher tiers override them.

```
components/lab/<name>/values.yaml    ← base defaults (lowest specificity)
        ↓  merged by orchestrator
groups/lab-group/values.yaml         ← group overrides
        ↓  merged by orchestrator
cluster/lab-cluster/values.yaml      ← cluster overrides (highest specificity)
        ↓
ArgoCD deploys the result
```

There is also a central **component registry** at `bootstrap/helm-values/applications.yaml` that tells the orchestrator where each component's Helm chart lives.

---

## Prerequisites

- Git installed and configured (`git config --global user.name` and `user.email` set)
- Access to push to the shared lab repo (URL provided by instructor)
- ArgoCD UI URL (provided by instructor)

---

## Step 0 — Clone and Verify

```bash
git clone <repo-url>
cd <repo-name>
```

Open the ArgoCD UI in your browser. Find the `example` application and confirm it is **Synced** and **Healthy**. This is your working reference.

---

## Step 1 — Copy the Example Component

Replace `<name>` with your first name or a unique identifier (lowercase, no spaces).

```bash
cp -r components/lab/example components/lab/<name>
```

Open `components/lab/<name>/values.yaml` and update these fields:

```yaml
appName: <name>

greeting: "Hello from <name>!"   # this is what the browser will show
```

These are your component's base defaults. `appName` is used as both the name and the namespace for every resource the chart creates. The `greeting` can be any string — it will be served as an HTML page via the OpenShift Route once ArgoCD deploys your component.

---

## Step 2 — Register Your Component

Open `bootstrap/helm-values/applications.yaml` and add your component under `availableApplications`:

```yaml
availableApplications:
  example:
    path: components/lab/example
  <name>:                          # add these two lines
    path: components/lab/<name>
```

This tells the orchestrator where to find your component's Helm chart.

---

## Step 3 — Enable Your Component in the Group

Open `groups/lab-group/values.yaml` and add your component name under `lab-group-components`:

```yaml
lab-group-components:
  example: {}     # pre-wired reference — do not remove
  <name>: {}      # add this line
```

An empty `{}` means "enable this component using its default values." You can replace `{}` with specific overrides if you want the group to set a different default for all clusters in this group.

---

## Step 4 — Add a Cluster-Level Override

Open `cluster/lab-cluster/values.yaml` and add an override for your component under `lab-cluster-components`:

```yaml
lab-cluster-components:
  example:
    replicaCount: 1
  <name>:                                    # add these lines
    replicaCount: 2
    greeting: "Cluster says: hello <name>!"
```

This demonstrates the cascade in action: your `greeting` is set in `components/lab/<name>/values.yaml`, but the cluster override here wins. The browser will show the cluster-level string, not the component default.

---

## Step 5 — Commit and Push

```bash
git add .
git commit -m "add <name> component"
git push
```

---

## Step 6 — Watch It Deploy

Open the ArgoCD UI. Within about 3 minutes you should see:

1. The `lab-group` Application refreshes
2. A new Application named `<name>` appears
3. It transitions from `OutOfSync` → `Syncing` → `Synced / Healthy`

If auto-sync is enabled, this happens automatically. If not, click **Sync** on the new Application.

---

## Step 7 — Visit Your App

Once the Application is **Healthy**, find your Route URL:

```bash
oc get route <name> -n <name> -o jsonpath='{.spec.host}{"\n"}'
```

Open that URL in your browser. You should see the `greeting` text from your cluster-level override.

---

## Stretch Goal — Change Your Message

Edit the `greeting` for your component in `cluster/lab-cluster/values.yaml`, commit, and push:

```yaml
lab-cluster-components:
  <name>:
    replicaCount: 2
    greeting: "Updated live by GitOps!"
```

Refresh your browser after ArgoCD syncs — no restart, no `oc`, just a Git push.

---

## Troubleshooting

**My Application does not appear in ArgoCD after pushing**
- Confirm all 4 files were saved and committed: `git status` should show nothing
- Check `bootstrap/helm-values/applications.yaml` — the indentation must be consistent YAML
- Check the ArgoCD UI for the parent `lab-group` app — look for a sync error

**Application is `OutOfSync` but not self-healing**
- Auto-sync may not be enabled; click **Sync** manually in the ArgoCD UI

**Application syncs but Pods are `CrashLoopBackOff`**
- Check that `appName` in your `values.yaml` does not contain spaces or uppercase letters
- Confirm the `image.tag` you set exists on Docker Hub

**Route exists but the browser shows the default nginx page**
- ArgoCD may have synced before the ConfigMap was fully rendered; force a re-sync on your Application in the ArgoCD UI

**Route URL returns a 503**
- Check that the Pods are Running: `oc get pods -n <name>`
- Check that the Service selector matches the Pod label: `oc describe svc <name> -n <name>`

**Two participants used the same `<name>`**
- One of you needs to pick a different name, update all 4 files, and push again

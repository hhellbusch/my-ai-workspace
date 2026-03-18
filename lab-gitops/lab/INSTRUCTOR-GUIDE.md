# Instructor Guide — GitOps App-of-Apps Lab

## Overview

This lab teaches the GitOps components / groups / cluster cascade pattern using ArgoCD. Participants add a leaf component to a shared cluster by editing 4 files and pushing to a shared Git branch. The session runs approximately 1 hour.

---

## Pre-Lab Setup Checklist

Complete all steps below before participants arrive.

### 1. Cluster and ArgoCD

- [ ] Shared Kubernetes cluster is running and accessible
- [ ] ArgoCD is installed (`oc get pods -n argocd` — all pods Running)
- [ ] ArgoCD UI is reachable at a URL participants can access from their machines
- [ ] Participants will need read access to the ArgoCD UI (create a read-only account if needed, or share admin credentials for a lab environment)

### 2. Repository

- [ ] The lab repo exists and contains the files from this template
- [ ] All participants have been granted push access to the shared repo
- [ ] Confirm the repo URL and credentials are ready to share
- [ ] The `main` branch is the tracked branch (or update ArgoCD Application `targetRevision` to match)

### 3. Bootstrap the Root App

This is the **only `oc` command you run manually** — everything else is managed by ArgoCD after this.

```bash
oc apply -f argocd/root-app.yaml -n argocd
```

After applying, open the ArgoCD UI and confirm the root app syncs within a few minutes. You should see it create child Applications down through the group and component layers.

### 4. Verify the Reference Component

In the ArgoCD UI, confirm the `example` Application is **Synced** and **Healthy** before the lab starts. This is the working reference participants will copy.

If it is not healthy, check:
```bash
# Confirm the namespace exists (or that createNamespace is enabled in the Application)
oc get namespace example

# Check the Deployment
oc get deployment example -n example
oc describe deployment example -n example
```

### 5. Namespaces

Each participant component deploys into its own namespace (the component name by default). You have two options:

**Option A — Pre-create namespaces** (more controlled):
```bash
# Create one per expected participant
for name in alice bob charlie; do
  oc create namespace $name
done
```

**Option B — Enable `createNamespace`** (easier, less control):
Ensure the ArgoCD Application template in your orchestrator chart includes:
```yaml
syncPolicy:
  syncOptions:
    - CreateNamespace=true
```

### 6. Distribute to Participants

Share the following before starting:

- Git repo URL
- Git credentials (or SSH key instructions)
- ArgoCD UI URL
- ArgoCD read access credentials (if separate from admin)
- Link to `lab/LAB-GUIDE.md`

---

## Suggested Agenda (~1 hour)

| Time | Activity |
|------|----------|
| 0:00 | Welcome and intro — what is GitOps? |
| 0:05 | Concept walkthrough — components / groups / cluster cascade |
| 0:10 | Tour the ArgoCD UI live — show root → group → example component |
| 0:15 | Live demo — instructor adds the `demo` component through all 4 files |
| 0:25 | Participants begin hands-on lab |
| 1:00 | Debrief — what happened, what scales, what's next |

---

## Live Demo Script (Part 2 — 10 minutes)

Walk through this exactly as participants will, narrating each step.

```bash
# Step 1 — copy the example
cp -r components/lab/example components/lab/demo

# Step 2 — change appName and greeting in values.yaml
# Edit components/lab/demo/values.yaml:
#   appName: demo
#   greeting: "Hello from the instructor demo!"

# Step 3 — register in the central registry
# Edit bootstrap/helm-values/applications.yaml:
#   demo:
#     path: components/lab/demo

# Step 4 — enable in the group
# Edit groups/lab-group/values.yaml, under lab-group-components:
#   lab-group-components:
#     demo: {}

# Step 5 — add a cluster override (replicaCount AND greeting)
# Edit cluster/lab-cluster/values.yaml, under lab-cluster-components:
#   lab-cluster-components:
#     demo:
#       replicaCount: 2
#       greeting: "Cluster override wins!"

# Step 6 — commit and push
git add .
git commit -m "add demo component"
git push
```

After pushing, switch to the ArgoCD UI and show:
1. The `lab-group` Application refreshing
2. The `demo` Application appearing
3. The sync completing to Healthy

Then run in a terminal and open the URL in the browser:
```bash
oc get route demo -n demo -o jsonpath='{.spec.host}'
```

Point out: **`oc apply` was never run.** The greeting shows the cluster-level string, not the component default — demonstrating the cascade immediately.

For extra impact, change the cluster `greeting` value again, push, and refresh the browser live.

---

## Common Participant Issues

### Participant's Application does not appear

1. Check `git log --oneline` — confirm the commit was pushed
2. Check `bootstrap/helm-values/applications.yaml` for YAML indentation errors
3. In ArgoCD UI, force a refresh on the parent group Application
4. Check ArgoCD logs: `oc logs -n argocd -l app.kubernetes.io/name=argocd-application-controller`

### YAML parse error on sync

Most common cause: tabs instead of spaces, or incorrect indentation in one of the 4 files. Ask the participant to run:
```bash
python3 -c "import yaml; yaml.safe_load(open('bootstrap/helm-values/applications.yaml'))"
```
Repeat for the other edited files.

### Two participants used the same component name

The second push will overwrite the first participant's entry. One of them needs to rename their component folder and update all 4 file entries, then push again.

### Namespace not found / Pod stuck Pending

```bash
oc get events -n <participant-name> --sort-by='.lastTimestamp'
```
If the namespace does not exist, either create it manually or confirm `CreateNamespace=true` is set in the orchestrator.

### Pods are ImagePullBackOff

The participant likely set a non-existent image tag. Ask them to fix `image.tag` in their `components/lab/<name>/values.yaml`, commit, and push.

---

## Debrief Talking Points (Part 4 — 5 minutes)

- **What just happened?** Git commit → ArgoCD detected drift → orchestrator re-ran `mustMergeOverwrite` cascade → generated new Application CR → deployed Helm chart
- **Why no `oc apply`?** The cluster continuously reconciles to match Git. Manual `oc` changes would be overwritten on the next sync — Git is the only source of truth.
- **How does this scale?**
  - Add a new group for a different environment (staging, production)
  - Any cluster assigned to both groups gets both sets of components
  - Cluster-level overrides let one cluster behave differently without forking the entire repo
- **What ArgoCD detects as drift:** If someone `oc edit`s a Deployment replica count or edits the ConfigMap directly, ArgoCD will revert it on the next sync cycle (if self-heal is enabled)
- **Where to go next:** ApplicationSets (generate Applications dynamically from a template), multi-cluster patterns, secret management with Sealed Secrets or External Secrets Operator

---

## Cleanup After the Lab

```bash
# Remove all participant namespaces
oc get namespaces | grep -v kube | grep -v argocd | grep -v default | awk '{print $1}' | xargs oc delete namespace

# Or selectively
oc delete namespace alice bob charlie demo
```

To reset the repo to a clean state, revert all participant commits:
```bash
git revert HEAD~<number-of-participant-commits>..HEAD
git push
```

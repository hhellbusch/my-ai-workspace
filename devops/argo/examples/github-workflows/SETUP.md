# Quick Setup Guide for ArgoCD Diff Preview

Follow these steps to enable ArgoCD diff previews on your pull requests.

## Option 1: Basic Setup (Recommended - No Cluster Access Required)

This option generates diffs by comparing Helm templates without connecting to your cluster.

### Step 1: Verify Files

Ensure these files exist (they should already be in your repo):
```
.github/workflows/argocd-diff-preview.yml  ✅ Created
charts/argocd-apps/values.yaml             ✅ Already exists
charts/argocd-apps/values-*.yaml           ✅ Already exists
```

### Step 2: Commit and Push

```bash
git add .github/workflows/argocd-diff-preview.yml
git commit -m "Add ArgoCD diff preview workflow"
git push
```

### Step 3: Test It

1. Create a test branch:
   ```bash
   git checkout -b test-argocd-diff
   ```

2. Make a small change to any app:
   ```bash
   # Example: Update an image tag
   echo "# test change" >> apps/example-app/deployment.yaml
   ```

3. Test locally (optional):
   ```bash
   .github/workflows/test-diff-locally.sh production
   ```

4. Commit and push:
   ```bash
   git add apps/example-app/deployment.yaml
   git commit -m "Test: Update deployment"
   git push -u origin test-argocd-diff
   ```

5. Create a PR on GitHub

6. Wait ~30 seconds for the workflow to run

7. Check for a comment on your PR showing the diff! 🎉

### Step 4: Review and Merge

- If the diff looks good, merge the setup PR
- Future PRs will automatically get diff previews

**That's it! You're done.** 🚀

---

## Option 2: Advanced Setup (With Live Cluster Diff)

This option connects to your ArgoCD instance to show diffs against live cluster state.

### Prerequisites
- Access to your ArgoCD server
- Ability to create service accounts or generate auth tokens

### Step 1: Generate ArgoCD Auth Token

**Option A: Service Account (Recommended for production)**

```bash
# Create service account
kubectl create serviceaccount argocd-github-diff -n argocd

# Create role for read-only access
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: argocd-github-diff
  namespace: argocd
rules:
- apiGroups: ["argoproj.io"]
  resources: ["applications"]
  verbs: ["get", "list"]
EOF

# Create role binding
kubectl create rolebinding argocd-github-diff \
  --role=argocd-github-diff \
  --serviceaccount=argocd:argocd-github-diff \
  -n argocd

# Get the token (for Kubernetes < 1.24)
kubectl get secret -n argocd \
  $(kubectl get sa argocd-github-diff -n argocd -o jsonpath='{.secrets[0].name}') \
  -o jsonpath='{.data.token}' | base64 -d

# For Kubernetes >= 1.24, create token manually
kubectl create token argocd-github-diff -n argocd --duration=87600h
```

**Option B: ArgoCD Account (Simpler, less secure)**

```bash
# Login to ArgoCD
argocd login <your-argocd-server>

# Create account
argocd account generate-token --account github-actions
```

### Step 2: Add GitHub Secrets

1. Go to your repository on GitHub
2. Navigate to: **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add these secrets:

   **Secret 1:**
   - Name: `ARGOCD_SERVER`
   - Value: `argocd.yourdomain.com` (without `https://`)

   **Secret 2:**
   - Name: `ARGOCD_AUTH_TOKEN`
   - Value: (paste the token from Step 1)

### Step 3: Add GitHub Variable

1. In the same settings page, click the **Variables** tab
2. Click **New repository variable**
3. Add:
   - Name: `ARGOCD_SERVER`
   - Value: `argocd.yourdomain.com` (same as secret)

### Step 4: Enable the Workflow

The workflow file is already created: `.github/workflows/argocd-live-diff.yml`

```bash
git add .github/workflows/argocd-live-diff.yml
git commit -m "Add ArgoCD live diff workflow"
git push
```

### Step 5: Test It

1. Create a test PR (same as Option 1)
2. You should now see TWO comments:
   - One from `argocd-diff-preview` (template diff)
   - One from `argocd-live-diff` (live cluster diff)

---

## Troubleshooting

### Workflow doesn't run

**Check:**
1. Workflow file is committed to the base branch (main/master)
2. PR modifies files in the trigger paths (apps/, infrastructure/, charts/)

**Fix:**
```bash
# Ensure workflow is on main branch
git checkout main
git pull
ls -la .github/workflows/argocd-diff-preview.yml
```

### No diff shown but changes exist

**Check:**
1. Verify Helm values files exist for your environment
2. Test template generation locally:
   ```bash
   helm template argocd-apps ./charts/argocd-apps \
     --values ./charts/argocd-apps/values.yaml \
     --values ./charts/argocd-apps/values-production.yaml \
     --debug
   ```

### "Permission denied" posting comment

**Check:**
1. Repository settings: **Settings** → **Actions** → **General**
2. Ensure "Workflow permissions" is set to "Read and write permissions"
3. Or enable: "Allow GitHub Actions to create and approve pull requests"

### Live diff workflow: "Could not connect to ArgoCD"

**Check:**
1. Secrets are set correctly (no typos)
2. ArgoCD server is accessible from internet (GitHub Actions runners)
3. Token hasn't expired
4. Test connection manually:
   ```bash
   argocd login <your-server> --auth-token <your-token> --grpc-web
   argocd app list
   ```

---

## Configuration Options

### Change which branches trigger the workflow

Edit `.github/workflows/argocd-diff-preview.yml`:

```yaml
on:
  pull_request:
    branches:
      - main
      - develop      # Add more branches
      - release/*    # Supports patterns
```

### Change which files trigger the workflow

```yaml
on:
  pull_request:
    paths:
      - 'apps/**'
      - 'infrastructure/**'
      - 'charts/**'
      - 'mycompany-apps/**'  # Add custom paths
```

### Add environment-specific conditions

```yaml
jobs:
  production-diff:
    if: contains(github.event.pull_request.labels.*.name, 'production')
    # Only run for PRs labeled with "production"
```

---

## Next Steps

After setup is complete:

1. **Update your PR process**
   - Add "Review ArgoCD diff" to your PR template
   - Require approval from platform team for infrastructure changes

2. **Set up CODEOWNERS** (optional)
   ```
   # .github/CODEOWNERS
   /apps/**              @your-team/developers
   /infrastructure/**    @your-team/platform
   /charts/**            @your-team/platform
   ```

3. **Add validation checks**
   - Lint YAML files
   - Run Kubernetes dry-run validation
   - Check for security issues with tools like kubesec

4. **Monitor and iterate**
   - Watch for false positives
   - Adjust environment detection logic as needed
   - Update token expiration reminders

---

## Examples of What You'll See

### Example 1: Image Tag Update

**Your change:**
```yaml
# apps/frontend/deployment.yaml
-   image: frontend:v1.0.0
+   image: frontend:v1.0.1
```

**Diff preview:**
```diff
--- a/production.yaml
+++ b/production.yaml
@@ -89,7 +89,7 @@
     spec:
       containers:
       - name: frontend
-        image: frontend:v1.0.0
+        image: frontend:v1.0.1
```

### Example 2: Adding a New Service

**Your change:**
- Create `apps/new-api/`
- Update `values-production.yaml`

**Diff preview:**
```diff
+apiVersion: argoproj.io/v1alpha1
+kind: Application
+metadata:
+  name: new-api
+  namespace: argocd
+spec:
+  project: default
+  source:
+    repoURL: https://github.com/your-org/your-repo.git
+    targetRevision: HEAD
+    path: apps/new-api
```

### Example 3: No Changes

**Diff preview:**
```
✅ No ArgoCD manifest changes detected

This PR does not introduce any changes to ArgoCD manifests.
```

---

## Security Best Practices

1. **Use read-only tokens** for GitHub Actions
2. **Rotate tokens regularly** (set calendar reminder)
3. **Limit service account permissions** to minimum required
4. **Don't commit secrets** to Git (use GitHub Secrets only)
5. **Review token access** periodically in ArgoCD UI
6. **Enable branch protection** on main/master branch
7. **Require PR reviews** for production changes

---

## Getting Help

If you encounter issues:

1. **Check workflow logs:**
   - Go to PR → "Checks" tab → Click failed workflow
   - Expand steps to see detailed logs

2. **Test locally:**
   ```bash
   .github/workflows/test-diff-locally.sh production
   ```

3. **Verify configuration:**
   ```bash
   # Check Helm chart
   helm lint ./charts/argocd-apps
   
   # Check workflow syntax
   yamllint .github/workflows/argocd-diff-preview.yml
   ```

4. **Review README:**
   - [Full documentation](.github/workflows/README.md)

---

**Happy GitOps-ing! 🚀**


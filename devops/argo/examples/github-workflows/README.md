# ArgoCD GitHub Actions Workflows

This directory contains GitHub Actions workflows for ArgoCD multi-cluster deployments and diff previews.

## Available Workflows

### `deploy-argocd-apps.yml` (Primary Deployment Workflow)

**What it does:**
- Deploys ArgoCD applications to multiple OpenShift clusters
- Automatically runs in dry-run mode for pull requests
- Provides comprehensive validation and diff analysis
- Supports manual dry-run mode via workflow_dispatch
- Includes health checks and error handling

**Features:**
- ✅ Multi-cluster deployment from single workflow
- ✅ Automatic PR validation (dry-run only)
- ✅ Server-side validation (`oc apply --dry-run=server`)
- ✅ Optional ArgoCD CLI diff analysis
- ✅ Helm template generation and validation
- ✅ Health check monitoring (warning mode)
- ✅ Operation timeouts (60s login, 120s apply)
- ✅ Automatic error cleanup
- ✅ Artifact upload (preview manifests)

**Triggers:**
- **Push to main** - Actual deployment
- **Pull request to main** - Automatic dry-run validation
- **Workflow dispatch** - Manual trigger with optional dry-run

**Setup:** See [multi-cluster-deployment.md](../docs/deployment/multi-cluster-deployment.md) for complete setup guide.

---

## Dynamic Matrix and Change Detection Workflows

### 📚 Complete Documentation

**[→ START HERE: Dynamic Matrix Index](./DYNAMIC-MATRIX-INDEX.md)** - Complete guide to all resources

### `deploy-changed-apps-matrix.yml` (Optimized Deployment)

**What it does:**
- Detects which apps have changed using git diff
- Deploys only changed apps (optimized)
- Falls back to deploying all apps if core infrastructure changed
- Dry-run validation on PRs, actual deployment on push to main

**Key Features:**
- ✅ Detects changed directories automatically
- ✅ Dynamic matrix generation based on changes
- ✅ Smart deployment strategy (changed vs all)
- ✅ PR preview comments
- ✅ Validation before deployment
- ✅ Deployment summary with job status

**Documentation:**
- 📘 [`DYNAMIC-MATRIX-GUIDE.md`](./DYNAMIC-MATRIX-GUIDE.md) - Complete guide to dynamic matrices
- 📘 [`CHANGED-DIRECTORIES-GUIDE.md`](./CHANGED-DIRECTORIES-GUIDE.md) - Methods for detecting changed directories
- 📗 [`QUICK-REFERENCE.md`](./QUICK-REFERENCE.md) - Syntax cheat sheet
- 📙 [`METHOD-COMPARISON.md`](./METHOD-COMPARISON.md) - Choose the right approach

**Examples:**
- `simple-dynamic-matrix.yml` - ⭐ Minimal dynamic matrix example
- `dynamic-matrix-example.yml` - ⭐⭐⭐ Comprehensive patterns
- `detect-changed-directories.yml` - ⭐⭐⭐ All detection methods

---

## Additional Example Workflows

### 1. `argocd-diff-preview.yml` (Recommended - No cluster access needed)

**What it does:**
- Generates Helm templates for both PR branch and base branch
- Creates a unified diff showing exactly what will change
- Posts results as a PR comment
- Uploads full manifests and diffs as artifacts

**Advantages:**
- ✅ No cluster access required
- ✅ No ArgoCD credentials needed
- ✅ Fast execution
- ✅ Works for all environments (dev, staging, production)
- ✅ Safe - read-only operation

**Setup:** No configuration needed! Just merge the workflow file.

---

### 2. `argocd-live-diff.yml` (Advanced - Requires cluster access)

**What it does:**
- Connects to your live ArgoCD instance
- Uses `argocd app diff` to show actual differences from live state
- Shows what will change when auto-sync triggers

**Advantages:**
- ✅ Shows real-time diff against live cluster
- ✅ Accounts for current cluster state
- ✅ Uses ArgoCD's native diff logic

**Setup required:**

1. **Add GitHub Secrets** (Settings → Secrets and variables → Actions):
   - `ARGOCD_SERVER`: Your ArgoCD server URL (e.g., `argocd.example.com`)
   - `ARGOCD_AUTH_TOKEN`: ArgoCD auth token (see below for how to generate)

2. **Add GitHub Variable** (Settings → Secrets and variables → Actions → Variables tab):
   - `ARGOCD_SERVER`: Same as above (used for conditional workflow execution)

3. **Generate ArgoCD Auth Token:**
   ```bash
   # Option 1: Create a read-only service account (recommended)
   kubectl create serviceaccount argocd-github-diff -n argocd
   
   # Create role for read-only diff operations
   kubectl apply -f - <<EOF
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   metadata:
     name: argocd-github-diff
     namespace: argocd
   rules:
   - apiGroups:
     - argoproj.io
     resources:
     - applications
     verbs:
     - get
     - list
   EOF
   
   # Bind role to service account
   kubectl create rolebinding argocd-github-diff \
     --role=argocd-github-diff \
     --serviceaccount=argocd:argocd-github-diff \
     -n argocd
   
   # Get the token
   kubectl get secret -n argocd \
     $(kubectl get sa argocd-github-diff -n argocd -o jsonpath='{.secrets[0].name}') \
     -o jsonpath='{.data.token}' | base64 -d
   
   # Option 2: Use existing ArgoCD account (simpler but less secure)
   argocd account generate-token --account github-actions
   ```

---

## How to Use

### For Pull Requests

1. **Create a PR** that modifies:
   - `apps/**` - Application manifests
   - `infrastructure/**` - Infrastructure configs
   - `charts/**` - Helm chart templates or values
   - `values-*.yaml` - Environment-specific values

2. **Wait for workflow to complete** (~30-60 seconds)

3. **Review the diff**:
   - Check the PR comment for inline diff
   - Download artifacts for full manifests
   - Verify changes match expectations

4. **Merge when ready** - ArgoCD will auto-sync the changes

### Example PR Comment

The workflow will post a comment like this:

```markdown
## 🔍 ArgoCD Diff Preview

**Pull Request:** #123
**Branch:** `feature/update-app` → `main`

### Environment: **production**

<details>
<summary>View diff (45 lines)</summary>

```diff
--- a/production.yaml
+++ b/production.yaml
@@ -23,7 +23,7 @@
     spec:
       containers:
       - name: app
-        image: myapp:v1.2.3
+        image: myapp:v1.2.4
         ports:
         - containerPort: 8080
```

</details>

### Environment: **staging**

✅ No changes detected

---

_💡 Tip: Download the artifacts below for full manifest files and diffs_

🤖 _Automated by ArgoCD Diff Preview workflow_
```

---

## Workflow Triggers

Both workflows trigger on PRs to `main`, `master`, or `develop` branches when these paths change:
- `apps/**`
- `infrastructure/**`
- `charts/**`
- `values*.yaml`
- `.github/workflows/argocd-*.yml`

To customize triggers, edit the `on.pull_request.paths` section.

---

## Artifacts

Each workflow run produces artifacts containing:

### argocd-diff-preview.yml artifacts:
- `manifests-pr/*.yaml` - Manifests from PR branch
- `manifests-base/*.yaml` - Manifests from base branch
- `diffs/*.diff` - Unified diff files per environment
- `diff-summary.md` - Markdown summary

### argocd-live-diff.yml artifacts:
- `live-diffs/*.diff` - Live diffs per application
- `live-diff-summary.md` - Markdown summary

**Retention:** 30 days (configurable in workflow)

---

## Customization

### Change environments to check

Edit the environment detection in `argocd-diff-preview.yml`:

```yaml
ENVIRONMENTS="development staging production custom-env"
```

### Filter specific apps

Add filtering logic:

```bash
# Only check apps starting with "prod-"
if [[ $app == prod-* ]]; then
  AFFECTED_APPS="${AFFECTED_APPS} ${app}"
fi
```

### Adjust diff truncation

Change the line limit in the diff generation step:

```yaml
if [ $DIFF_SIZE -gt 500 ]; then  # Change 500 to your preferred limit
```

### Add approval gates

Require specific reviewers for PRs with changes:

```yaml
- name: Require approval if changes detected
  if: steps.diff-report.outputs.has_changes == 'true'
  run: |
    echo "::warning::Changes detected - requires approval from platform team"
```

---

## Troubleshooting

### Workflow doesn't trigger

**Check:**
- PR targets correct branch (`main`, `master`, or `develop`)
- Changed files match path filters
- Workflow file is on the target branch

### "No environments detected"

**Cause:** Changed files don't match detection logic

**Fix:** Either:
- Ensure you're changing files in `apps/`, `infrastructure/`, or `charts/`
- Update environment detection logic in the workflow

### Diff is empty but changes exist

**Possible causes:**
1. Changes are in files not processed by Helm template
2. Changes result in identical manifest output
3. Helm template generation failed (check logs)

**Debug:**
```bash
# Test locally
helm template argocd-apps ./charts/argocd-apps \
  --values ./charts/argocd-apps/values.yaml \
  --values ./charts/argocd-apps/values-production.yaml \
  --debug
```

### Live diff workflow fails to connect

**Check:**
1. `ARGOCD_SERVER` secret is correct (no `https://` prefix)
2. `ARGOCD_AUTH_TOKEN` is valid and not expired
3. Network connectivity from GitHub Actions to ArgoCD server
4. Service account has necessary permissions

**Test connection:**
```bash
argocd login $ARGOCD_SERVER --auth-token $TOKEN --grpc-web
argocd app list
```

### Comment not posted to PR

**Check:**
- Workflow has `pull-requests: write` permission
- Repository settings allow GitHub Actions to comment
- No branch protection rules blocking bot comments

---

## Best Practices

1. **Review diffs carefully** before merging, especially for production
2. **Use artifacts** for detailed analysis of large diffs
3. **Test in lower environments** first (dev → staging → production)
4. **Set up CODEOWNERS** to require platform team approval for infrastructure changes
5. **Monitor ArgoCD** after merge to ensure auto-sync completes successfully
6. **Keep workflows updated** - check for newer ArgoCD CLI versions periodically

---

## Integration with CI/CD

### Combine with other checks

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Lint YAML
        run: yamllint apps/ infrastructure/
  
  argocd-diff:
    needs: lint  # Run diff only after linting passes
    uses: ./.github/workflows/argocd-diff-preview.yml
```

### Block merge on failed validation

```yaml
- name: Validate manifests
  run: |
    for manifest in /tmp/manifests-pr/*.yaml; do
      kubectl apply --dry-run=client -f $manifest
    done
```

---

## Security Considerations

### argocd-diff-preview.yml
- ✅ No secrets required
- ✅ No cluster access
- ✅ Read-only Git operations
- ✅ Safe for public repositories

### argocd-live-diff.yml
- ⚠️ Requires ArgoCD credentials
- ⚠️ Access to cluster state
- ⚠️ Use service account with minimal permissions
- ⚠️ Rotate tokens regularly
- ⚠️ Consider IP restrictions on ArgoCD API

---

## Examples

### Example 1: Updating an application image tag

**PR changes:**
```yaml
# apps/my-app/deployment.yaml
- image: myapp:v1.0.0
+ image: myapp:v1.0.1
```

**Diff preview shows:**
```diff
--- a/production.yaml
+++ b/production.yaml
@@ -45,7 +45,7 @@
         spec:
           containers:
           - name: my-app
-            image: myapp:v1.0.0
+            image: myapp:v1.0.1
```

### Example 2: Adding a new application

**PR changes:**
- New directory: `apps/new-service/`
- Updated: `charts/argocd-apps/values-production.yaml`

**Diff preview shows:**
- Entirely new `Application` resource
- New namespace creation
- All manifests for the new service

### Example 3: Changing Helm values

**PR changes:**
```yaml
# charts/argocd-apps/values-production.yaml
applications:
  - name: example-app
-   targetRevision: v1.2.3
+   targetRevision: v1.2.4
```

**Diff preview shows:**
- Updated `targetRevision` in ArgoCD Application spec
- Indicates ArgoCD will sync to new version

---

## Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Helm Documentation](https://helm.sh/docs/)
- [App of Apps Pattern](../APP-OF-APPS-PATTERN.md)

---

## Support

For issues or questions:
1. Check workflow logs in GitHub Actions tab
2. Review this README and troubleshooting section
3. Test Helm template generation locally
4. Verify ArgoCD application configuration

---

**Last Updated:** November 2024


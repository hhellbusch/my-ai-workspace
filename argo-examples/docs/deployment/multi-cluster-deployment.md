# Multi-Cluster ArgoCD Deployment

This setup allows you to deploy ArgoCD applications to multiple OpenShift clusters using a single GitHub Action workflow.

## Overview

The workflow reads cluster configurations from `hubs.yaml` and deploys the same set of ArgoCD applications to each cluster sequentially.

### OpenShift ACM Integration

If you're using **OpenShift Advanced Cluster Management (ACM)** with GitOps, the hub cluster is automatically registered as `local-cluster`. For better cluster identification, you can rename it to use the actual cluster name.

**See:** [Renaming local-cluster in OpenShift ACM](acm-rename-local-cluster.md) for the complete guide and script.

Quick example after renaming:
```yaml
hubs:
  production-hub:  # Actual cluster name instead of local-cluster
    name: production-hub
    server: https://kubernetes.default.svc
    argocd_namespace: openshift-gitops
    token_secret: OPENSHIFT_TOKEN_HUB
```

## Configuration

### 1. Define Clusters in `hubs.yaml`

```yaml
hubs:
  dev-cluster:
    name: dev-cluster
    server: https://api.dev.example.com:6443
    argocd_namespace: argocd
    token_secret: OPENSHIFT_TOKEN_DEV
    dry_run: false  # Optional: set to true for preview-only mode
    argocd_server: argocd.dev.example.com  # Optional: for ArgoCD CLI diffs
    argocd_token_secret: ARGOCD_TOKEN_DEV  # Optional: ArgoCD auth token
    
  staging-cluster:
    name: staging-cluster
    server: https://api.staging.example.com:6443
    argocd_namespace: argocd
    token_secret: OPENSHIFT_TOKEN_STAGING
    dry_run: false
    argocd_server: argocd.staging.example.com
    argocd_token_secret: ARGOCD_TOKEN_STAGING
    
  prod-cluster:
    name: prod-cluster
    server: https://api.prod.example.com:6443
    argocd_namespace: argocd
    token_secret: OPENSHIFT_TOKEN_PROD
    dry_run: false  # Set to true to make prod preview-only
    argocd_server: argocd.prod.example.com
    argocd_token_secret: ARGOCD_TOKEN_PROD
```

**Structure:**
The `hubs.yaml` uses a dictionary/map structure where each key is a unique hub identifier. The `name` field within each hub should match the key for consistency.

**Required Fields:**
- `name`: Friendly name for the cluster (used in logs) - should match the hub key
- `server`: OpenShift API server URL
- `argocd_namespace`: Namespace where ArgoCD is installed
- `token_secret`: Name of the GitHub secret containing the service account token

**Optional Fields:**
- `dry_run`: If `true`, only preview changes without applying (default: `false`)
- `argocd_server`: ArgoCD server URL for CLI diff analysis (e.g., `argocd.example.com`)
- `argocd_token_secret`: GitHub secret name containing ArgoCD auth token

### 2. Set Up GitHub Secrets

For each cluster, create a GitHub secret with the service account token:

1. Go to your repository → Settings → Secrets and variables → Actions
2. Add secrets matching the `token_secret` values in `hubs.yaml`:
   - `OPENSHIFT_TOKEN_DEV`
   - `OPENSHIFT_TOKEN_STAGING`
   - `OPENSHIFT_TOKEN_PROD`

### 3. Update the Workflow

If you add a new cluster, update the workflow file to include the new token secret:

```yaml
- name: Deploy to all clusters
  env:
    OPENSHIFT_TOKEN_DEV: ${{ secrets.OPENSHIFT_TOKEN_DEV }}
    OPENSHIFT_TOKEN_STAGING: ${{ secrets.OPENSHIFT_TOKEN_STAGING }}
    OPENSHIFT_TOKEN_PROD: ${{ secrets.OPENSHIFT_TOKEN_PROD }}
    OPENSHIFT_TOKEN_NEW_CLUSTER: ${{ secrets.OPENSHIFT_TOKEN_NEW_CLUSTER }}  # Add new token
```

### 4. (Optional) Configure ArgoCD CLI Diff

For enhanced diff analysis during pull requests, optionally configure ArgoCD CLI access:

1. Generate an ArgoCD auth token:
```bash
# Option 1: Generate token for existing account
argocd account generate-token --account github-actions

# Option 2: Create read-only service account (recommended)
argocd proj role create default github-diff --description "Read-only for GitHub diffs"
argocd proj role add-policy default github-diff --action get --permission allow --object '*/Application/*'
argocd account generate-token --account proj:default:github-diff
```

2. Add ArgoCD tokens to GitHub Secrets:
   - `ARGOCD_TOKEN_DEV`
   - `ARGOCD_TOKEN_STAGING`
   - `ARGOCD_TOKEN_PROD`

3. Update the workflow to include ArgoCD tokens:
```yaml
env:
  # OpenShift tokens
  OPENSHIFT_TOKEN_DEV: ${{ secrets.OPENSHIFT_TOKEN_DEV }}
  # ArgoCD tokens (optional)
  ARGOCD_TOKEN_DEV: ${{ secrets.ARGOCD_TOKEN_DEV }}
```

## Dry-Run and Pull Request Features

### Automatic Dry-Run on Pull Requests

The workflow automatically runs in **dry-run mode** for all pull requests to the main branch:

- **No changes applied** - Only validation and preview
- **Server-side validation** - Tests against actual clusters
- **ArgoCD diff analysis** - Shows ArgoCD's perspective (if configured)
- **Preview artifacts** - Download generated manifests for review

**Example workflow:**
```
1. Developer creates PR with changes to apps/
2. Workflow automatically triggers in dry-run mode
3. Validates against all clusters (dev, staging, prod)
4. Shows diffs and preview manifests
5. Team reviews changes before merging
6. After merge, actual deployment runs
```

### Manual Dry-Run Mode

Trigger dry-run manually via GitHub Actions:

1. Go to Actions → Deploy ArgoCD Applications
2. Click "Run workflow"
3. Check "Run in dry-run mode" option
4. Click "Run workflow"

### Per-Cluster Dry-Run

Make specific clusters always run in preview mode:

```yaml
hubs:
  prod-cluster:
    name: prod-cluster
    server: https://api.prod.example.com:6443
    argocd_namespace: argocd
    token_secret: OPENSHIFT_TOKEN_PROD
    dry_run: true  # Always preview, never auto-apply
```

Useful for:
- Production environments requiring manual approval
- Compliance requirements
- Extra safety for critical clusters

### Hybrid Mode

Dry-run is triggered by ANY of:
1. Pull request event (automatic)
2. Workflow dispatch input (manual)
3. Cluster configuration (permanent)

The reason for dry-run is clearly shown in workflow logs.

## How It Works

### Workflow Process

```
1. Checkout code
2. Install tools (oc, helm, argocd CLI, yq)
3. Discover directories in apps/ and infrastructure/
4. Determine mode (dry-run or apply based on PR/workflow input/cluster config)
5. Read hubs.yaml to get cluster list
6. For each cluster:
   ├── Parse cluster configuration
   ├── Enable error tracking and cleanup handlers
   ├── Authenticate with service account token (60s timeout)
   ├── If DRY-RUN mode:
   │   ├── Generate Helm templates
   │   ├── Run server-side validation (oc apply --dry-run=server)
   │   ├── (Optional) Authenticate to ArgoCD
   │   ├── (Optional) Run argocd app diff for each application
   │   ├── Save preview artifacts
   │   └── Skip to next cluster
   ├── If APPLY mode:
   │   ├── Apply ArgoCD applications via Helm template (120s timeout)
   │   ├── Verify applications created
   │   ├── Health check: Wait for applications to sync (5 min max, warning only)
   │   └── Report success
   └── Clear error handlers
7. Upload artifacts (dry-run previews, if any)
8. Report overall success
```

### Deployment Order

Clusters are deployed **sequentially** in the order they appear in `hubs.yaml`. If any cluster fails, the workflow stops.

### Example Output

```
================================================
Deploying to cluster: dev-cluster
Server: https://api.dev.example.com:6443
ArgoCD Namespace: argocd
================================================
Authenticating to dev-cluster...
Login successful.
Verifying connection...
system:serviceaccount:argocd:argocd-deployer
Applying ArgoCD applications...
application.argoproj.io/frontend created
application.argoproj.io/backend created
✅ Successfully deployed to dev-cluster

================================================
Deploying to cluster: staging-cluster
...
```

## Advanced Configuration

### Per-Cluster Helm Values

You can customize Helm values per cluster by adding a `values_file` field:

```yaml
clusters:
  - name: dev-cluster
    server: https://api.dev.example.com:6443
    argocd_namespace: argocd
    token_secret: OPENSHIFT_TOKEN_DEV
    values_file: values-dev.yaml  # Optional
    
  - name: prod-cluster
    server: https://api.prod.example.com:6443
    argocd_namespace: argocd
    token_secret: OPENSHIFT_TOKEN_PROD
    values_file: values-prod.yaml  # Optional
```

Then update the workflow to use the values file:

```bash
VALUES_FILE=$(yq eval ".clusters[$i].values_file // \"\"" hubs.yaml)

if [ -n "$VALUES_FILE" ]; then
  helm template argocd-apps ./charts/argocd-apps \
    --namespace ${ARGOCD_NAMESPACE} \
    --values ./charts/argocd-apps/${VALUES_FILE} \
    --set-json "applications=$APP_DIRECTORIES" \
    --set-json "infrastructure=$INFRA_DIRECTORIES" \
    | oc apply -f -
else
  helm template argocd-apps ./charts/argocd-apps \
    --namespace ${ARGOCD_NAMESPACE} \
    --set-json "applications=$APP_DIRECTORIES" \
    --set-json "infrastructure=$INFRA_DIRECTORIES" \
    | oc apply -f -
fi
```

### Deploy to Specific Clusters Only

You can add a condition to skip certain clusters:

```yaml
clusters:
  - name: dev-cluster
    server: https://api.dev.example.com:6443
    argocd_namespace: argocd
    token_secret: OPENSHIFT_TOKEN_DEV
    enabled: true
    
  - name: prod-cluster
    server: https://api.prod.example.com:6443
    argocd_namespace: argocd
    token_secret: OPENSHIFT_TOKEN_PROD
    enabled: false  # Skip this cluster
```

Update the loop:

```bash
ENABLED=$(yq eval ".clusters[$i].enabled // true" hubs.yaml)

if [ "$ENABLED" != "true" ]; then
  echo "⏭️  Skipping $CLUSTER_NAME (enabled: false)"
  continue
fi
```

### Parallel Deployment

To deploy to clusters in parallel instead of sequentially, use a matrix strategy:

```yaml
jobs:
  prepare:
    runs-on: ubuntu-latest
    outputs:
      clusters: ${{ steps.set-matrix.outputs.clusters }}
    steps:
      - uses: actions/checkout@v4
      - name: Set matrix
        id: set-matrix
        run: |
          CLUSTERS=$(yq eval '.clusters | [.[] | .name] | @json' hubs.yaml)
          echo "clusters=$CLUSTERS" >> $GITHUB_OUTPUT
  
  deploy:
    needs: prepare
    runs-on: ubuntu-latest
    strategy:
      matrix:
        cluster: ${{ fromJson(needs.prepare.outputs.clusters) }}
    steps:
      # Deploy to each cluster in parallel
```

## Troubleshooting

### Error: "Token secret X is not set"

- Ensure the GitHub secret exists and matches the `token_secret` name in `hubs.yaml`
- Verify the secret is added to the workflow's `env` section

### Error: "unable to connect to server"

- Verify the `server` URL in `hubs.yaml` is correct
- Check that the service account token has network access to the cluster

### Deployment succeeds but applications not in ArgoCD

- Verify `argocd_namespace` matches where ArgoCD is installed
- Check service account permissions on the cluster
- Review ArgoCD controller logs

## Security Best Practices

1. **Use service accounts** with minimum required permissions
2. **Rotate tokens regularly** and update GitHub secrets
3. **Use different tokens** for each cluster (don't reuse)
4. **Enable branch protection** on main to require approvals
5. **Consider using** `--dry-run` for production clusters

## Testing

Test locally before pushing:

```bash
# Export tokens
export OPENSHIFT_TOKEN_DEV="your-token"
export OPENSHIFT_TOKEN_STAGING="your-token"
export OPENSHIFT_TOKEN_PROD="your-token"

# Test the loop logic
CLUSTER_COUNT=$(yq eval '.clusters | length' hubs.yaml)

for i in $(seq 0 $(($CLUSTER_COUNT - 1))); do
  CLUSTER_NAME=$(yq eval ".clusters[$i].name" hubs.yaml)
  CLUSTER_SERVER=$(yq eval ".clusters[$i].server" hubs.yaml)
  echo "Would deploy to: $CLUSTER_NAME at $CLUSTER_SERVER"
done
```

## Example: Complete Setup

### File Structure

```
your-repo/
├── .github/
│   └── workflows/
│       └── deploy-argocd-apps.yml
├── apps/
│   ├── frontend/
│   └── backend/
├── infrastructure/
│   └── monitoring/
├── charts/
│   └── argocd-apps/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-dev.yaml
│       ├── values-prod.yaml
│       └── templates/
│           └── app-of-apps.yaml
└── hubs.yaml
```

### Push to Deploy

```bash
git add hubs.yaml
git commit -m "Update cluster configuration"
git push origin main
```

The workflow will automatically deploy to all clusters! 🚀


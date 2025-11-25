# Multi-Cluster ArgoCD Deployment

This setup allows you to deploy ArgoCD applications to multiple OpenShift clusters using a single GitHub Action workflow.

## Overview

The workflow reads cluster configurations from `hubs.yaml` and deploys the same set of ArgoCD applications to each cluster sequentially.

## Configuration

### 1. Define Clusters in `hubs.yaml`

```yaml
clusters:
  - name: dev-cluster
    server: https://api.dev.example.com:6443
    argocd_namespace: argocd
    token_secret: OPENSHIFT_TOKEN_DEV
    
  - name: staging-cluster
    server: https://api.staging.example.com:6443
    argocd_namespace: argocd
    token_secret: OPENSHIFT_TOKEN_STAGING
    
  - name: prod-cluster
    server: https://api.prod.example.com:6443
    argocd_namespace: argocd
    token_secret: OPENSHIFT_TOKEN_PROD
```

**Fields:**
- `name`: Friendly name for the cluster (used in logs)
- `server`: OpenShift API server URL
- `argocd_namespace`: Namespace where ArgoCD is installed
- `token_secret`: Name of the GitHub secret containing the service account token

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

## How It Works

### Workflow Process

```
1. Checkout code
2. Install tools (oc, helm, yq)
3. Discover directories in apps/ and infrastructure/
4. Read hubs.yaml to get cluster list
5. For each cluster:
   ├── Parse cluster configuration
   ├── Authenticate with service account token
   ├── Verify connection
   ├── Apply ArgoCD applications via Helm template
   ├── Verify deployment
   └── Logout
6. Report success
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


# Quick Setup Guide - Multi-Cluster ArgoCD Deployment

## 📋 Prerequisites

- OpenShift clusters with ArgoCD installed
- Service account tokens for each cluster
- GitHub repository with this workflow

## 🚀 Quick Start

### Step 1: Configure Clusters

Edit `hubs.yaml` with your cluster information:

```yaml
hubs:
  dev-cluster:
    name: dev-cluster
    server: https://api.dev.example.com:6443      # ← Your cluster URL
    argocd_namespace: argocd
    token_secret: OPENSHIFT_TOKEN_DEV
```

### Step 2: Add GitHub Secrets

1. Go to: **Repository Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add each token:
   - Name: `OPENSHIFT_TOKEN_DEV`
   - Value: `sha256~xxxxxxxxxxxxx` (your service account token)

Repeat for each cluster (DEV, STAGING, PROD).

### Step 3: Update Workflow Secrets Reference

Edit `.github/workflows/deploy-argocd-apps.yml` line 67-71:

```yaml
- name: Deploy to all clusters
  env:
    OPENSHIFT_TOKEN_DEV: ${{ secrets.OPENSHIFT_TOKEN_DEV }}
    OPENSHIFT_TOKEN_STAGING: ${{ secrets.OPENSHIFT_TOKEN_STAGING }}
    OPENSHIFT_TOKEN_PROD: ${{ secrets.OPENSHIFT_TOKEN_PROD }}
    # Add any new cluster tokens here
```

### Step 4: Organize Your Applications

```
apps/
├── frontend/
│   └── deployment.yaml
├── backend/
│   └── deployment.yaml
└── api/
    └── deployment.yaml

infrastructure/
├── monitoring/
│   └── prometheus.yaml
└── logging/
    └── fluentd.yaml
```

### Step 5: Update Helm Values

Edit `charts/argocd-apps/values.yaml`:

```yaml
source:
  repoURL: https://github.com/YOUR-ORG/YOUR-REPO.git  # ← Update this!
```

### Step 6: Push and Deploy

```bash
git add .
git commit -m "Configure multi-cluster deployment"
git push origin main
```

The workflow will automatically deploy to all clusters! 🎉

## 📊 What Gets Deployed

For each cluster, the workflow will:

1. Scan `apps/` directory → finds `["frontend", "backend", "api"]`
2. Scan `infrastructure/` directory → finds `["monitoring", "logging"]`
3. Generate ArgoCD Applications for each:
   - `frontend` (from apps/frontend/)
   - `backend` (from apps/backend/)
   - `api` (from apps/api/)
   - `infra-monitoring` (from infrastructure/monitoring/)
   - `infra-logging` (from infrastructure/logging/)

## 🔧 Common Tasks

### Add a New Cluster

1. Add to `hubs.yaml`:
```yaml
hubs:
  test-cluster:
    name: test-cluster
    server: https://api.test.example.com:6443
    argocd_namespace: argocd
    token_secret: OPENSHIFT_TOKEN_TEST
```

2. Add GitHub secret: `OPENSHIFT_TOKEN_TEST`

3. Update workflow env:
```yaml
OPENSHIFT_TOKEN_TEST: ${{ secrets.OPENSHIFT_TOKEN_TEST }}
```

### Add a New Application

Just create a new directory:

```bash
mkdir apps/new-app
# Add your manifests
git add apps/new-app
git commit -m "Add new-app"
git push
```

It will be automatically discovered and deployed to all clusters!

### Deploy Only to Specific Clusters

Temporarily remove clusters from `hubs.yaml` or add a feature flag:

```yaml
- name: prod-cluster
  server: https://api.prod.example.com:6443
  argocd_namespace: argocd
  token_secret: OPENSHIFT_TOKEN_PROD
  enabled: false  # Skip this cluster
```

(Note: You'll need to update the workflow to check the `enabled` field)

## 🔍 Monitoring Deployments

### View Workflow Logs

1. Go to: **Actions** tab in GitHub
2. Click on the latest workflow run
3. Expand "Deploy to all clusters" to see details

### Verify in OpenShift

```bash
# Login to a cluster
oc login --token=xxx --server=https://api.cluster.example.com:6443

# Check ArgoCD applications
oc get applications -n argocd

# Check application status
oc describe application frontend -n argocd
```

### Check Application Sync Status

The ArgoCD UI will show all applications and their sync status.

## 🐛 Troubleshooting

### "Token secret X is not set"
→ Add the secret to GitHub and update the workflow env section

### "unable to connect to server"
→ Check the server URL in hubs.yaml

### Applications not showing in ArgoCD
→ Verify argocd_namespace is correct and service account has permissions

### Workflow triggered but no deployment
→ Check that changes are in the monitored paths (apps/, infrastructure/, charts/, hubs.yaml)

## 📚 Documentation

- `multi-cluster-deployment.md` - Detailed documentation
- `two-folder-example.md` - Example of scanning multiple folders
- `argocd-github-action-README.md` - Original single-cluster setup

## 🎯 Best Practices

1. **Test in dev first** - Order clusters in hubs.yaml with dev first
2. **Use branch protection** - Require PR approval for main branch
3. **Rotate tokens** - Update service account tokens regularly
4. **Monitor workflows** - Set up notifications for failed deployments
5. **Version control** - Tag releases for rollback capability

## 🔒 Security

- **Never commit tokens** to the repository
- **Use service accounts** with minimum required permissions
- **Enable audit logging** on OpenShift clusters
- **Review workflow logs** for sensitive information before sharing

---

Need help? Check the documentation files or review the workflow logs for specific error messages.


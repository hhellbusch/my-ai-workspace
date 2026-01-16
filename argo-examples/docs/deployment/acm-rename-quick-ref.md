# ACM local-cluster Rename - Quick Reference

> **Quick reference card for renaming local-cluster in OpenShift ACM**
> 
> For detailed documentation, see: [acm-rename-local-cluster.md](acm-rename-local-cluster.md)

## Three-Step Process

### 1️⃣ Disable Hub Self-Management

```bash
oc patch MultiClusterHub multiclusterhub \
  -n open-cluster-management \
  --type merge \
  -p '{"spec":{"disableHubSelfManagement":true}}'
```

**Wait for local-cluster removal:**
```bash
oc get managedcluster local-cluster -w
# Wait until it's deleted
```

---

### 2️⃣ Set New Cluster Name

```bash
# Get actual cluster name
CLUSTER_NAME=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}')

# Or use custom name
# CLUSTER_NAME="my-cluster"

# Patch with new name
oc patch MultiClusterHub multiclusterhub \
  -n open-cluster-management \
  --type merge \
  -p "{\"spec\":{\"localClusterName\":\"${CLUSTER_NAME}\"}}"
```

---

### 3️⃣ Re-enable Hub Self-Management

```bash
oc patch MultiClusterHub multiclusterhub \
  -n open-cluster-management \
  --type merge \
  -p '{"spec":{"disableHubSelfManagement":false}}'
```

**Wait for new cluster registration:**
```bash
oc get managedcluster -w
# Wait for your cluster name to appear
```

---

## One-Liner Script

```bash
# Use the automated script
bash scripts/rename-local-cluster.sh

# Or with custom name
bash scripts/rename-local-cluster.sh my-custom-cluster
```

---

## Verification Commands

```bash
# List managed clusters
oc get managedcluster

# Check cluster status
oc get managedcluster ${CLUSTER_NAME} -o yaml | grep -A 10 "status:"

# Verify ArgoCD integration
oc get secrets -n openshift-gitops -l argocd.argoproj.io/secret-type=cluster

# ArgoCD cluster list
argocd cluster list
```

---

## Update Your Configuration

After renaming, update `hubs.yaml`:

```yaml
hubs:
  my-actual-cluster:  # Changed from local-cluster
    name: my-actual-cluster
    server: https://kubernetes.default.svc
    argocd_namespace: openshift-gitops
    token_secret: OPENSHIFT_TOKEN_HUB
```

---

## Troubleshooting Quick Fixes

### Cluster Stuck in Terminating

```bash
oc patch managedcluster local-cluster -p '{"metadata":{"finalizers":[]}}' --type=merge
```

### Rollback to local-cluster

```bash
# Disable
oc patch MultiClusterHub multiclusterhub -n open-cluster-management \
  --type merge -p '{"spec":{"disableHubSelfManagement":true}}'

# Remove custom name
oc patch MultiClusterHub multiclusterhub -n open-cluster-management \
  --type json -p '[{"op": "remove", "path": "/spec/localClusterName"}]'

# Re-enable
oc patch MultiClusterHub multiclusterhub -n open-cluster-management \
  --type merge -p '{"spec":{"disableHubSelfManagement":false}}'
```

### Restart ArgoCD

```bash
oc rollout restart deployment/openshift-gitops-server -n openshift-gitops
oc rollout restart deployment/openshift-gitops-application-controller -n openshift-gitops
```

---

## Important Notes

- ⏱️ **Duration:** 2-5 minutes total
- 🔒 **Access Required:** cluster-admin
- 📋 **Minimum ACM Version:** 2.5+
- 🎯 **Recommended:** Test in dev environment first

---

## Official Documentation

Red Hat ACM: [Disable Hub Self-Management](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html/install/installing#disable-hub-self-management)

---

**Full Documentation:** [acm-rename-local-cluster.md](acm-rename-local-cluster.md)


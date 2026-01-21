#!/bin/bash

# Script to set up ManagedClusterSets and Placements
# Run this on the RHACM Hub cluster

set -euo pipefail

echo "================================================"
echo "Setting up ManagedClusterSets and Placements"
echo "================================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if we're on Hub cluster
if ! oc get multiclusterhub -n open-cluster-management &>/dev/null; then
    echo "❌ Not connected to RHACM Hub cluster"
    exit 1
fi

echo -e "${GREEN}✓ Connected to RHACM Hub${NC}"
echo ""

# List current managed clusters
echo "📋 Current Managed Clusters:"
echo "================================================"
oc get managedclusters -o custom-columns=NAME:.metadata.name,STATUS:.status.conditions[?\(@.type==\"ManagedClusterConditionAvailable\"\)].status,LABELS:.metadata.labels
echo ""

# Create ManagedClusterSets
echo "🔧 Creating ManagedClusterSets..."

# Production ManagedClusterSet
cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSet
metadata:
  name: production
spec:
  clusterSelector:
    selectorType: LabelSelector
    labelSelector:
      matchLabels:
        environment: production
EOF
echo -e "${GREEN}✓ ManagedClusterSet 'production' created${NC}"

# Staging ManagedClusterSet
cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSet
metadata:
  name: staging
spec:
  clusterSelector:
    selectorType: LabelSelector
    labelSelector:
      matchLabels:
        environment: staging
EOF
echo -e "${GREEN}✓ ManagedClusterSet 'staging' created${NC}"

# Global ManagedClusterSet (all clusters except local-cluster)
cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSet
metadata:
  name: global
spec:
  clusterSelector:
    selectorType: LabelSelector
    labelSelector:
      matchExpressions:
      - key: name
        operator: NotIn
        values:
        - local-cluster
EOF
echo -e "${GREEN}✓ ManagedClusterSet 'global' created${NC}"
echo ""

# Create ManagedClusterSetBindings
echo "🔗 Creating ManagedClusterSetBindings..."

# Ensure rhacm-policies namespace exists
oc create namespace rhacm-policies --dry-run=client -o yaml | oc apply -f -

# Bind production
cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSetBinding
metadata:
  name: production
  namespace: rhacm-policies
spec:
  clusterSet: production
EOF
echo -e "${GREEN}✓ ManagedClusterSetBinding 'production' created in rhacm-policies${NC}"

# Bind staging
cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSetBinding
metadata:
  name: staging
  namespace: rhacm-policies
spec:
  clusterSet: staging
EOF
echo -e "${GREEN}✓ ManagedClusterSetBinding 'staging' created in rhacm-policies${NC}"

# Bind global
cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1beta2
kind: ManagedClusterSetBinding
metadata:
  name: global
  namespace: rhacm-policies
spec:
  clusterSet: global
EOF
echo -e "${GREEN}✓ ManagedClusterSetBinding 'global' created in rhacm-policies${NC}"
echo ""

# Create Placements
echo "📍 Creating Placements..."

# Production Placement
cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Placement
metadata:
  name: production-placement
  namespace: rhacm-policies
spec:
  clusterSets:
  - production
  tolerations:
  - key: cluster.open-cluster-management.io/unreachable
    operator: Exists
EOF
echo -e "${GREEN}✓ Placement 'production-placement' created${NC}"

# Staging Placement
cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Placement
metadata:
  name: staging-placement
  namespace: rhacm-policies
spec:
  clusterSets:
  - staging
  tolerations:
  - key: cluster.open-cluster-management.io/unreachable
    operator: Exists
EOF
echo -e "${GREEN}✓ Placement 'staging-placement' created${NC}"

# All clusters Placement
cat <<EOF | oc apply -f -
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Placement
metadata:
  name: all-clusters-placement
  namespace: rhacm-policies
spec:
  clusterSets:
  - global
  tolerations:
  - key: cluster.open-cluster-management.io/unreachable
    operator: Exists
EOF
echo -e "${GREEN}✓ Placement 'all-clusters-placement' created${NC}"
echo ""

# Show results
echo "================================================"
echo "Summary"
echo "================================================"
echo ""

echo -e "${BLUE}ManagedClusterSets:${NC}"
oc get managedclusterset
echo ""

echo -e "${BLUE}ManagedClusterSetBindings in rhacm-policies:${NC}"
oc get managedclustersetbinding -n rhacm-policies
echo ""

echo -e "${BLUE}Placements in rhacm-policies:${NC}"
oc get placement -n rhacm-policies
echo ""

echo -e "${BLUE}PlacementDecisions (which clusters are selected):${NC}"
oc get placementdecision -n rhacm-policies
echo ""

# Show which clusters are in each set
echo "================================================"
echo "Cluster Assignments"
echo "================================================"
echo ""

for clusterset in production staging global; do
    echo -e "${BLUE}Clusters in '$clusterset' ManagedClusterSet:${NC}"
    oc get managedclusters -l environment=$clusterset -o name 2>/dev/null || echo "  (none with environment=$clusterset label)"
    echo ""
done

echo "================================================"
echo "Next Steps"
echo "================================================"
echo ""
echo "1. Label your clusters appropriately:"
echo "   oc label managedcluster <cluster-name> environment=production"
echo "   oc label managedcluster <cluster-name> environment=staging"
echo ""
echo "2. Apply policies with PlacementBindings that reference Placements:"
echo "   oc apply -f hub-secret-reference-policy.yaml"
echo "   oc apply -f managedclusterset-placement.yaml"
echo ""
echo "3. View placement decisions:"
echo "   oc get placementdecision -n rhacm-policies -o yaml"
echo ""
echo "4. Check which clusters a placement selected:"
echo "   oc get placementdecision -n rhacm-policies -l cluster.open-cluster-management.io/placement=production-placement -o yaml"
echo ""
echo "✅ Setup complete!"


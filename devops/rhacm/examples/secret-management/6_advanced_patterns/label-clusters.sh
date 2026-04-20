#!/bin/bash

# Script to label managed clusters for Placement filtering
# Run this on the RHACM Hub cluster

set -euo pipefail

echo "================================================"
echo "Label Managed Clusters for Placement Filtering"
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
oc get managedclusters -o custom-columns=\
NAME:.metadata.name,\
STATUS:.status.conditions[?\(@.type==\"ManagedClusterConditionAvailable\"\)].status,\
LABELS:.metadata.labels

echo ""
echo "================================================"
echo "Common Label Patterns"
echo "================================================"
echo ""
echo "1. Environment labels:"
echo "   - environment: production, staging, development"
echo ""
echo "2. Region labels:"
echo "   - region: us-east-1, us-west-2, eu-central-1"
echo ""
echo "3. Cloud provider labels:"
echo "   - cloud: aws, azure, gcp, on-prem"
echo ""
echo "4. Purpose labels:"
echo "   - purpose: application, database, monitoring"
echo ""
echo "5. Criticality labels:"
echo "   - criticality: high, medium, low"
echo ""
echo "6. Compliance labels:"
echo "   - compliance: pci-dss, hipaa, sox"
echo ""
echo "================================================"
echo ""

# Function to label a cluster
label_cluster() {
    local cluster=$1
    local label_key=$2
    local label_value=$3
    
    echo "  Labeling ${cluster}: ${label_key}=${label_value}"
    oc label managedcluster "${cluster}" "${label_key}=${label_value}" --overwrite
}

# Interactive mode or example mode
read -p "Would you like to use example labels? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🏷️  Applying example labels..."
    echo ""
    
    # Get list of managed clusters (excluding local-cluster)
    CLUSTERS=$(oc get managedclusters -o jsonpath='{.items[?(@.metadata.name!="local-cluster")].metadata.name}')
    
    if [ -z "$CLUSTERS" ]; then
        echo -e "${YELLOW}⚠ No managed clusters found (excluding local-cluster)${NC}"
        exit 0
    fi
    
    # Convert to array
    CLUSTER_ARRAY=($CLUSTERS)
    CLUSTER_COUNT=${#CLUSTER_ARRAY[@]}
    
    echo "Found $CLUSTER_COUNT managed cluster(s)"
    echo ""
    
    # Label first cluster as production
    if [ $CLUSTER_COUNT -ge 1 ]; then
        CLUSTER=${CLUSTER_ARRAY[0]}
        echo -e "${BLUE}Cluster 1: $CLUSTER${NC}"
        label_cluster "$CLUSTER" "environment" "production"
        label_cluster "$CLUSTER" "region" "us-east-1"
        label_cluster "$CLUSTER" "cloud" "aws"
        label_cluster "$CLUSTER" "criticality" "high"
        echo -e "${GREEN}✓ Labeled as production cluster${NC}"
        echo ""
    fi
    
    # Label second cluster as staging
    if [ $CLUSTER_COUNT -ge 2 ]; then
        CLUSTER=${CLUSTER_ARRAY[1]}
        echo -e "${BLUE}Cluster 2: $CLUSTER${NC}"
        label_cluster "$CLUSTER" "environment" "staging"
        label_cluster "$CLUSTER" "region" "us-west-2"
        label_cluster "$CLUSTER" "cloud" "aws"
        label_cluster "$CLUSTER" "criticality" "medium"
        echo -e "${GREEN}✓ Labeled as staging cluster${NC}"
        echo ""
    fi
    
    # Label remaining clusters as development
    if [ $CLUSTER_COUNT -ge 3 ]; then
        for i in $(seq 2 $((CLUSTER_COUNT-1))); do
            CLUSTER=${CLUSTER_ARRAY[$i]}
            echo -e "${BLUE}Cluster $((i+1)): $CLUSTER${NC}"
            label_cluster "$CLUSTER" "environment" "development"
            label_cluster "$CLUSTER" "region" "us-east-1"
            label_cluster "$CLUSTER" "cloud" "on-prem"
            label_cluster "$CLUSTER" "criticality" "low"
            echo -e "${GREEN}✓ Labeled as development cluster${NC}"
            echo ""
        done
    fi
    
else
    echo ""
    echo "================================================"
    echo "Manual Labeling Examples"
    echo "================================================"
    echo ""
    echo "Label a specific cluster:"
    echo "  oc label managedcluster <cluster-name> environment=production"
    echo "  oc label managedcluster <cluster-name> region=us-east-1"
    echo "  oc label managedcluster <cluster-name> cloud=aws"
    echo ""
    echo "Label multiple clusters at once:"
    echo "  for cluster in cluster1 cluster2 cluster3; do"
    echo "    oc label managedcluster \$cluster environment=production"
    echo "  done"
    echo ""
    echo "Remove a label:"
    echo "  oc label managedcluster <cluster-name> environment-"
    echo ""
    exit 0
fi

echo ""
echo "================================================"
echo "Current Cluster Labels"
echo "================================================"
echo ""

# Show current labels
oc get managedclusters -o custom-columns=\
NAME:.metadata.name,\
ENVIRONMENT:.metadata.labels.environment,\
REGION:.metadata.labels.region,\
CLOUD:.metadata.labels.cloud,\
CRITICALITY:.metadata.labels.criticality

echo ""
echo "================================================"
echo "Next Steps"
echo "================================================"
echo ""
echo "1. Apply a Placement that filters by labels:"
echo "   oc apply -f placement-by-labels.yaml"
echo ""
echo "2. Check which clusters are selected:"
echo "   oc get placementdecision -n rhacm-policies"
echo ""
echo "3. View specific placement decisions:"
echo "   oc get placementdecision -n rhacm-policies \\"
echo "     -l cluster.open-cluster-management.io/placement=production-clusters \\"
echo "     -o yaml"
echo ""
echo "4. Bind a policy to the placement:"
echo "   oc apply -f your-policy.yaml"
echo "   oc apply -f placement-binding.yaml"
echo ""
echo "✅ Labeling complete!"


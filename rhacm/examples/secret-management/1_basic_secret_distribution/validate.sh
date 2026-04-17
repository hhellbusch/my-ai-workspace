#!/bin/bash

# Validation script for basic secret distribution
# This script checks if secrets were successfully distributed to managed clusters

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================================"
echo "RHACM Secret Distribution Validation"
echo "================================================"
echo ""

# Check if we're connected to the Hub cluster
echo "🔍 Checking Hub cluster connection..."
if ! oc get multiclusterhub -n open-cluster-management &>/dev/null; then
    echo -e "${RED}❌ Not connected to RHACM Hub cluster${NC}"
    echo "Please ensure you're connected to the Hub cluster with 'oc login'"
    exit 1
fi
echo -e "${GREEN}✓ Connected to RHACM Hub${NC}"
echo ""

# Check if policies exist
echo "🔍 Checking policies..."
POLICY_NAMESPACE="rhacm-policies"

if ! oc get namespace $POLICY_NAMESPACE &>/dev/null; then
    echo -e "${YELLOW}⚠ Namespace '$POLICY_NAMESPACE' not found${NC}"
    echo "Create it with: oc create namespace $POLICY_NAMESPACE"
    exit 1
fi

POLICIES=$(oc get policy -n $POLICY_NAMESPACE -o name 2>/dev/null || true)
if [ -z "$POLICIES" ]; then
    echo -e "${YELLOW}⚠ No policies found in namespace $POLICY_NAMESPACE${NC}"
    echo "Apply policies with: oc apply -f ."
    exit 1
fi

echo -e "${GREEN}✓ Found policies:${NC}"
for policy in $POLICIES; do
    POLICY_NAME=$(echo $policy | cut -d'/' -f2)
    STATUS=$(oc get policy $POLICY_NAME -n $POLICY_NAMESPACE -o jsonpath='{.status.compliant}' 2>/dev/null || echo "Unknown")
    
    if [ "$STATUS" = "Compliant" ]; then
        echo -e "  ${GREEN}✓ $POLICY_NAME: $STATUS${NC}"
    elif [ "$STATUS" = "NonCompliant" ]; then
        echo -e "  ${RED}✗ $POLICY_NAME: $STATUS${NC}"
    else
        echo -e "  ${YELLOW}⚠ $POLICY_NAME: $STATUS${NC}"
    fi
done
echo ""

# Check PlacementRules
echo "🔍 Checking placements..."
PLACEMENTS=$(oc get placementrule -n $POLICY_NAMESPACE -o name 2>/dev/null || true)
if [ -z "$PLACEMENTS" ]; then
    echo -e "${YELLOW}⚠ No placement rules found${NC}"
else
    for placement in $PLACEMENTS; do
        PLACEMENT_NAME=$(echo $placement | cut -d'/' -f2)
        DECISIONS=$(oc get placementrule $PLACEMENT_NAME -n $POLICY_NAMESPACE -o jsonpath='{.status.decisions}' 2>/dev/null || echo "[]")
        
        if [ "$DECISIONS" = "[]" ] || [ -z "$DECISIONS" ]; then
            echo -e "  ${YELLOW}⚠ $PLACEMENT_NAME: No clusters selected${NC}"
        else
            CLUSTER_COUNT=$(echo $DECISIONS | jq '. | length' 2>/dev/null || echo "0")
            echo -e "  ${GREEN}✓ $PLACEMENT_NAME: $CLUSTER_COUNT cluster(s) selected${NC}"
            
            # Show which clusters
            CLUSTER_NAMES=$(echo $DECISIONS | jq -r '.[].clusterName' 2>/dev/null || echo "")
            for cluster in $CLUSTER_NAMES; do
                echo "    - $cluster"
            done
        fi
    done
fi
echo ""

# Check managed clusters
echo "🔍 Listing managed clusters..."
CLUSTERS=$(oc get managedcluster -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || true)
if [ -z "$CLUSTERS" ]; then
    echo -e "${YELLOW}⚠ No managed clusters found${NC}"
    exit 0
fi

for cluster in $CLUSTERS; do
    if [ "$cluster" = "local-cluster" ]; then
        continue
    fi
    
    echo ""
    echo "Cluster: $cluster"
    
    # Check cluster availability
    AVAILABLE=$(oc get managedcluster $cluster -o jsonpath='{.status.conditions[?(@.type=="ManagedClusterConditionAvailable")].status}' 2>/dev/null || echo "Unknown")
    if [ "$AVAILABLE" = "True" ]; then
        echo -e "  ${GREEN}✓ Status: Available${NC}"
    else
        echo -e "  ${RED}✗ Status: Not Available ($AVAILABLE)${NC}"
        continue
    fi
    
    # Check for secrets in default namespace
    echo "  Checking secrets in 'default' namespace..."
    SECRET_CHECK=$(oc get secret my-app-secret -n default --context=$cluster 2>/dev/null && echo "exists" || echo "missing")
    if [ "$SECRET_CHECK" = "exists" ]; then
        echo -e "    ${GREEN}✓ Secret 'my-app-secret' exists${NC}"
    else
        echo -e "    ${YELLOW}⚠ Secret 'my-app-secret' not found${NC}"
    fi
    
    # Check for secrets in my-app namespace
    echo "  Checking secrets in 'my-app' namespace..."
    SECRET_CHECK=$(oc get secret app-config -n my-app --context=$cluster 2>/dev/null && echo "exists" || echo "missing")
    if [ "$SECRET_CHECK" = "exists" ]; then
        echo -e "    ${GREEN}✓ Secret 'app-config' exists${NC}"
    else
        echo -e "    ${YELLOW}⚠ Secret 'app-config' not found (or namespace doesn't exist)${NC}"
    fi
done

echo ""
echo "================================================"
echo "Validation complete!"
echo "================================================"
echo ""
echo "To manually verify a secret on a managed cluster:"
echo "  oc --context=<cluster-name> get secret my-app-secret -n default -o yaml"
echo ""
echo "To view policy details:"
echo "  oc describe policy <policy-name> -n $POLICY_NAMESPACE"
echo ""


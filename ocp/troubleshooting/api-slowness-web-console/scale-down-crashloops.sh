#!/bin/bash
#
# Scale Down CrashLooping Deployments
#
# This script identifies deployments with pods in CrashLoopBackOff and
# scales them down to 0 replicas. It properly follows the ownership chain:
# Pod → ReplicaSet → Deployment
#
# Usage: ./scale-down-crashloops.sh [--dry-run] [--exclude-namespaces "ns1,ns2"]

set -euo pipefail

# Color output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse arguments
DRY_RUN=false
EXCLUDE_NS=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --exclude-namespaces)
      EXCLUDE_NS="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--dry-run] [--exclude-namespaces \"ns1,ns2\"]"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}=== CrashLooping Deployment Scaling Tool ===${NC}"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}DRY RUN MODE - No changes will be made${NC}"
  echo ""
fi

# Create backup file
BACKUP_FILE="deployment-replicas-backup-$(date +%Y%m%d-%H%M%S).txt"
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

echo "Creating backup of current replica counts..."
oc get deployments -A -o json | \
  jq -r '.items[] | "\(.metadata.namespace) \(.metadata.name) \(.spec.replicas)"' > "$BACKUP_FILE"
echo -e "${GREEN}✓${NC} Backup saved to: $BACKUP_FILE"
echo ""

# Find crashlooping pods and trace to deployments
echo "Finding crashlooping pods and tracing ownership..."

# Get all crashlooping pods with their replicaset owners
oc get pods -A -o json | \
  jq -r '.items[] | 
    select(.status.containerStatuses[]?.state.waiting?.reason == "CrashLoopBackOff") | 
    select(.metadata.ownerReferences[0].kind == "ReplicaSet") |
    {
      namespace: .metadata.namespace,
      pod: .metadata.name,
      replicaset: .metadata.ownerReferences[0].name,
      restarts: .status.containerStatuses[0].restartCount
    } | 
    "\(.namespace)|\(.pod)|\(.replicaset)|\(.restarts)"' > "$TEMP_FILE"

if [ ! -s "$TEMP_FILE" ]; then
  echo -e "${GREEN}✓${NC} No pods in CrashLoopBackOff found"
  rm -f "$BACKUP_FILE"
  exit 0
fi

echo -e "${YELLOW}Found $(wc -l < $TEMP_FILE) crashlooping pod(s)${NC}"
echo ""

# For each namespace/replicaset, find the deployment owner
declare -A DEPLOYMENTS
declare -A POD_COUNTS
declare -A MAX_RESTARTS

while IFS='|' read -r namespace pod replicaset restarts; do
  # Skip if namespace is in exclude list
  if [ -n "$EXCLUDE_NS" ]; then
    if echo ",$EXCLUDE_NS," | grep -q ",$namespace,"; then
      echo -e "${YELLOW}⊘${NC} Skipping $namespace/$pod (excluded namespace)"
      continue
    fi
  fi
  
  # Get the deployment that owns this replicaset
  DEPLOYMENT=$(oc get replicaset "$replicaset" -n "$namespace" -o json 2>/dev/null | \
    jq -r 'select(.metadata.ownerReferences[0].kind == "Deployment") | .metadata.ownerReferences[0].name')
  
  if [ -n "$DEPLOYMENT" ] && [ "$DEPLOYMENT" != "null" ]; then
    KEY="${namespace}/${DEPLOYMENT}"
    DEPLOYMENTS[$KEY]=1
    
    # Count pods
    if [ -z "${POD_COUNTS[$KEY]:-}" ]; then
      POD_COUNTS[$KEY]=1
    else
      POD_COUNTS[$KEY]=$((${POD_COUNTS[$KEY]} + 1))
    fi
    
    # Track max restarts
    if [ -z "${MAX_RESTARTS[$KEY]:-}" ] || [ "$restarts" -gt "${MAX_RESTARTS[$KEY]}" ]; then
      MAX_RESTARTS[$KEY]=$restarts
    fi
  else
    echo -e "${YELLOW}⚠${NC} Could not find deployment for $namespace/$replicaset (pod: $pod)"
  fi
done < "$TEMP_FILE"

# Check if any deployments found
if [ ${#DEPLOYMENTS[@]} -eq 0 ]; then
  echo -e "${GREEN}✓${NC} No deployments with crashlooping pods found"
  rm -f "$BACKUP_FILE"
  exit 0
fi

# Display findings
echo -e "${YELLOW}Found ${#DEPLOYMENTS[@]} deployment(s) with crashlooping pods:${NC}"
echo ""

# Sort and display
for KEY in "${!DEPLOYMENTS[@]}"; do
  NAMESPACE=$(echo "$KEY" | cut -d/ -f1)
  DEPLOYMENT=$(echo "$KEY" | cut -d/ -f2)
  PODS=${POD_COUNTS[$KEY]}
  RESTARTS=${MAX_RESTARTS[$KEY]}
  
  # Get current replicas
  CURRENT_REPLICAS=$(oc get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "?")
  
  # Check if system namespace
  if [[ $NAMESPACE =~ ^(openshift-|kube-|default) ]]; then
    echo -e "  ${RED}⚠${NC} $KEY"
  else
    echo -e "  • $KEY"
  fi
  echo "    └─ $PODS pod(s) crashlooping, max $RESTARTS restarts, current replicas: $CURRENT_REPLICAS"
done | sort

echo ""
echo -e "${BLUE}Namespace Summary:${NC}"
for KEY in "${!DEPLOYMENTS[@]}"; do
  echo "$KEY" | cut -d/ -f1
done | sort -u | while read ns; do
  if [[ $ns =~ ^(openshift-|kube-|default) ]]; then
    echo -e "  ${RED}⚠${NC} $ns ${RED}(SYSTEM NAMESPACE - CAUTION!)${NC}"
  else
    echo "  • $ns"
  fi
done

echo ""

if [ "$DRY_RUN" = true ]; then
  echo -e "${YELLOW}DRY RUN: Would scale down ${#DEPLOYMENTS[@]} deployment(s)${NC}"
  echo ""
  echo "To actually scale down, run without --dry-run flag"
  exit 0
fi

echo -e "${YELLOW}WARNING:${NC} This will scale ${#DEPLOYMENTS[@]} deployment(s) to 0 replicas"
echo ""
echo "Deployments can be restored later using:"
echo "  oc scale deployment <name> -n <namespace> --replicas=<count>"
echo ""
echo "Original replica counts are backed up in: $BACKUP_FILE"
echo ""

read -p "Proceed with scaling down? (type 'YES' in caps to confirm): " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
  echo -e "${YELLOW}Cancelled${NC}"
  exit 0
fi

echo ""
echo "Scaling down deployments..."
echo ""

SCALED=0
FAILED=0

for KEY in "${!DEPLOYMENTS[@]}"; do
  NAMESPACE=$(echo "$KEY" | cut -d/ -f1)
  DEPLOYMENT=$(echo "$KEY" | cut -d/ -f2)
  
  echo -n "  $KEY ... "
  
  if oc scale deployment "$DEPLOYMENT" -n "$NAMESPACE" --replicas=0 2>/dev/null; then
    echo -e "${GREEN}✓ scaled to 0${NC}"
    ((SCALED++)) || true
  else
    echo -e "${RED}✗ FAILED${NC}"
    ((FAILED++)) || true
  fi
done

echo ""
echo -e "${BLUE}=== Summary ===${NC}"
echo -e "${GREEN}✓${NC} Successfully scaled: $SCALED"

if [ $FAILED -gt 0 ]; then
  echo -e "${RED}✗${NC} Failed to scale: $FAILED"
fi

echo ""
echo "Backup file: $BACKUP_FILE"
echo ""
echo "To restore a deployment:"
echo "  oc scale deployment <name> -n <namespace> --replicas=<count>"
echo ""
echo "To restore all from backup:"
echo "  while read ns deploy replicas; do"
echo "    oc scale deployment \$deploy -n \$ns --replicas=\$replicas"
echo "  done < $BACKUP_FILE"
echo ""

exit 0


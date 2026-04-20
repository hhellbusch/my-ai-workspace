#!/bin/bash

# Quick diagnostic for "resource name may not be empty" error
# This script checks if MCO resources exist and validates YAML files

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== MultiClusterObservability Name Diagnostic ===${NC}\n"

# Check if connected to cluster
if ! oc whoami &>/dev/null; then
    echo -e "${RED}✗ Not connected to cluster${NC}"
    echo "  Please login first: oc login <cluster-url>"
    exit 1
fi

echo -e "${GREEN}✓ Connected to cluster${NC}"
echo ""

# Check if MCO resources exist
echo -e "${YELLOW}[1] Checking existing MultiClusterObservability resources...${NC}"
if MCO_LIST=$(oc get multiclusterobservability 2>&1); then
    if echo "$MCO_LIST" | grep -q "No resources found"; then
        echo -e "${YELLOW}⚠ No MultiClusterObservability resources found${NC}"
        echo "  This is normal if you're creating a new one."
    else
        echo -e "${GREEN}✓ Found MCO resources:${NC}"
        echo "$MCO_LIST" | while IFS= read -r line; do
            echo "  $line"
        done
        echo ""
        
        # Get the name(s)
        MCO_NAMES=$(echo "$MCO_LIST" | awk 'NR>1 {print $1}')
        echo -e "${GREEN}Resource name(s) to use in commands:${NC}"
        for name in $MCO_NAMES; do
            echo -e "  ${GREEN}• $name${NC}"
            echo "    Example: oc delete multiclusterobservability $name"
            echo "    Example: oc edit multiclusterobservability $name"
        done
    fi
else
    echo -e "${RED}✗ Error checking MCO resources:${NC}"
    echo "$MCO_LIST" | sed 's/^/  /'
fi

echo ""

# Check if any YAML files in current directory
echo -e "${YELLOW}[2] Checking YAML files in current directory...${NC}"
if ls *.yaml &>/dev/null || ls *.yml &>/dev/null; then
    for file in *.yaml *.yml; do
        [ -f "$file" ] || continue
        
        # Check if it's an MCO file
        if grep -q "kind: MultiClusterObservability" "$file" 2>/dev/null; then
            echo -e "\n${YELLOW}Checking: $file${NC}"
            
            # Check for metadata.name
            if NAME=$(grep -A 5 "^metadata:" "$file" | grep "^  name:" | head -1 | awk '{print $2}'); then
                if [ -n "$NAME" ]; then
                    echo -e "${GREEN}✓ metadata.name found: $NAME${NC}"
                else
                    echo -e "${RED}✗ metadata.name exists but is empty!${NC}"
                    echo -e "${YELLOW}  Fix: Add a value after 'name:' in the metadata section${NC}"
                fi
            else
                echo -e "${RED}✗ metadata.name is MISSING!${NC}"
                echo -e "${YELLOW}  Fix: Add 'name: observability' under metadata: section${NC}"
                echo ""
                echo "  Current metadata section:"
                grep -A 5 "^metadata:" "$file" | sed 's/^/    /'
            fi
            
            # Check for storageConfig.metricObjectStorage.name
            if grep -q "metricObjectStorage:" "$file"; then
                if STORAGE_NAME=$(grep -A 3 "metricObjectStorage:" "$file" | grep "name:" | head -1 | awk '{print $2}'); then
                    if [ -n "$STORAGE_NAME" ]; then
                        echo -e "${GREEN}✓ storageConfig.metricObjectStorage.name found: $STORAGE_NAME${NC}"
                        
                        # Check if the secret exists
                        if oc get secret "$STORAGE_NAME" -n open-cluster-management-observability &>/dev/null; then
                            echo -e "${GREEN}✓ Secret '$STORAGE_NAME' exists${NC}"
                        else
                            echo -e "${RED}✗ Secret '$STORAGE_NAME' not found${NC}"
                            echo -e "${YELLOW}  Fix: Create the secret first:${NC}"
                            echo "    oc create secret generic $STORAGE_NAME \\"
                            echo "      -n open-cluster-management-observability \\"
                            echo "      --from-file=thanos.yaml"
                        fi
                    else
                        echo -e "${RED}✗ storageConfig.metricObjectStorage.name is empty!${NC}"
                    fi
                else
                    echo -e "${RED}✗ storageConfig.metricObjectStorage.name is MISSING!${NC}"
                    echo -e "${YELLOW}  Fix: Add 'name: <secret-name>' under metricObjectStorage:${NC}"
                fi
            fi
            
            # Validate the YAML
            echo ""
            echo "Attempting dry-run validation..."
            if oc apply -f "$file" --dry-run=server 2>&1 | grep -q "resource name may not be empty"; then
                echo -e "${RED}✗ Validation failed with 'resource name may not be empty'${NC}"
                echo -e "${YELLOW}  This confirms metadata.name is missing or empty${NC}"
            elif oc apply -f "$file" --dry-run=server &>/dev/null; then
                echo -e "${GREEN}✓ YAML validation passed!${NC}"
            else
                echo -e "${YELLOW}⚠ Validation had other issues (not the name problem):${NC}"
                oc apply -f "$file" --dry-run=server 2>&1 | tail -5 | sed 's/^/  /'
            fi
        fi
    done
else
    echo "  No YAML files found in current directory"
fi

echo ""
echo -e "${YELLOW}=== Summary ===${NC}"
echo ""
echo "Common fixes for 'resource name may not be empty':"
echo ""
echo "1. When using commands, always include the resource name:"
echo "   oc get multiclusterobservability                    # ← Get the name first"
echo "   oc delete multiclusterobservability <name-here>     # ← Use the name"
echo ""
echo "2. In YAML files, ensure metadata.name is present:"
echo "   metadata:"
echo "     name: observability    # ← This is required!"
echo ""
echo "3. Ensure nested storage config has a name:"
echo "   spec:"
echo "     storageConfig:"
echo "       metricObjectStorage:"
echo "         name: thanos-object-storage    # ← This is required!"
echo "         key: thanos.yaml"
echo ""
echo "See QUICK-FIX.md or README.md for more details."

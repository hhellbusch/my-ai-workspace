#!/bin/bash
# Offline diff generation for ArgoCD App of Apps pattern
# Compares two git revisions and generates diffs for parent and all child apps
#
# Usage: ./diff-app-of-apps.sh <old-revision> <new-revision> [environment]
#
# Example:
#   ./diff-app-of-apps.sh v1.2.3 v1.2.4 production
#   ./diff-app-of-apps.sh main feature/new-app staging
#   ./diff-app-of-apps.sh v1.2.3 HEAD development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
OLD_REVISION=${1:-main}
NEW_REVISION=${2:-HEAD}
ENVIRONMENT=${3:-production}
PARENT_CHART_PATH="charts/argocd-apps"
WORK_DIR="/tmp/argocd-app-of-apps-diff-$$"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}ArgoCD App of Apps - Offline Diff Generator${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Old Revision:  ${YELLOW}${OLD_REVISION}${NC}"
echo -e "New Revision:  ${YELLOW}${NEW_REVISION}${NC}"
echo -e "Environment:   ${YELLOW}${ENVIRONMENT}${NC}"
echo -e "Working Dir:   ${YELLOW}${WORK_DIR}${NC}"
echo ""

# Check prerequisites
if ! command -v helm &> /dev/null; then
    echo -e "${RED}❌ Error: Helm is not installed${NC}"
    exit 1
fi

if ! command -v yq &> /dev/null; then
    echo -e "${YELLOW}⚠️  Warning: yq is not installed. Child app extraction will use basic parsing.${NC}"
    echo -e "${YELLOW}   Install yq for better results: https://github.com/mikefarah/yq${NC}"
    echo ""
fi

# Create working directory structure
mkdir -p "${WORK_DIR}"/{old,new}/{parent,children}

echo -e "${BLUE}[1/5]${NC} Extracting charts from git..."

# Extract parent chart from OLD revision
git archive "${OLD_REVISION}" "${PARENT_CHART_PATH}" 2>/dev/null | tar -x -C "${WORK_DIR}/old/" || {
    echo -e "${RED}❌ Error: Could not extract ${PARENT_CHART_PATH} from ${OLD_REVISION}${NC}"
    exit 1
}

# Extract parent chart from NEW revision
git archive "${NEW_REVISION}" "${PARENT_CHART_PATH}" 2>/dev/null | tar -x -C "${WORK_DIR}/new/" || {
    echo -e "${RED}❌ Error: Could not extract ${PARENT_CHART_PATH} from ${NEW_REVISION}${NC}"
    exit 1
}

echo -e "${GREEN}✅ Extracted charts from both revisions${NC}"
echo ""

echo -e "${BLUE}[2/5]${NC} Rendering parent app (Application CRDs)..."

# Render parent app from OLD revision
helm template argocd-apps "${WORK_DIR}/old/${PARENT_CHART_PATH}" \
    --values "${WORK_DIR}/old/${PARENT_CHART_PATH}/values.yaml" \
    --values "${WORK_DIR}/old/${PARENT_CHART_PATH}/values-${ENVIRONMENT}.yaml" \
    --namespace argocd \
    > "${WORK_DIR}/old/parent/applications.yaml" 2>/dev/null || {
    echo -e "${RED}❌ Error: Could not render parent chart from ${OLD_REVISION}${NC}"
    exit 1
}

# Render parent app from NEW revision
helm template argocd-apps "${WORK_DIR}/new/${PARENT_CHART_PATH}" \
    --values "${WORK_DIR}/new/${PARENT_CHART_PATH}/values.yaml" \
    --values "${WORK_DIR}/new/${PARENT_CHART_PATH}/values-${ENVIRONMENT}.yaml" \
    --namespace argocd \
    > "${WORK_DIR}/new/parent/applications.yaml" 2>/dev/null || {
    echo -e "${RED}❌ Error: Could not render parent chart from ${NEW_REVISION}${NC}"
    exit 1
}

echo -e "${GREEN}✅ Rendered parent Application CRDs${NC}"
echo ""

echo -e "${BLUE}[3/5]${NC} Extracting child app definitions..."

# Function to extract child app information
extract_child_apps() {
    local manifest_file=$1
    local output_dir=$2
    
    if command -v yq &> /dev/null; then
        # Use yq for proper YAML parsing
        yq eval 'select(.kind == "Application") | [.metadata.name, .spec.source.repoURL, .spec.source.path, .spec.source.targetRevision] | join("|")' "${manifest_file}" > "${output_dir}/child-apps.list"
    else
        # Fallback to grep/awk (less reliable but works for simple cases)
        awk '
            /^kind: Application$/ { in_app=1; next }
            in_app && /^  name:/ { app_name=$2 }
            in_app && /repoURL:/ { repo=$2 }
            in_app && /path:/ { path=$2 }
            in_app && /targetRevision:/ { revision=$2; print app_name"|"repo"|"path"|"revision; in_app=0 }
        ' "${manifest_file}" > "${output_dir}/child-apps.list"
    fi
}

extract_child_apps "${WORK_DIR}/old/parent/applications.yaml" "${WORK_DIR}/old/parent"
extract_child_apps "${WORK_DIR}/new/parent/applications.yaml" "${WORK_DIR}/new/parent"

# Get unique list of all child apps (union of old and new)
cat "${WORK_DIR}/old/parent/child-apps.list" "${WORK_DIR}/new/parent/child-apps.list" 2>/dev/null | \
    cut -d'|' -f1 | sort -u > "${WORK_DIR}/all-child-apps.list"

CHILD_COUNT=$(wc -l < "${WORK_DIR}/all-child-apps.list" | tr -d ' ')
echo -e "${GREEN}✅ Found ${CHILD_COUNT} child applications${NC}"

if [ "${CHILD_COUNT}" -gt 0 ]; then
    echo -e "${BLUE}Child apps:${NC}"
    cat "${WORK_DIR}/all-child-apps.list" | while read app; do
        echo -e "  - ${app}"
    done
fi
echo ""

echo -e "${BLUE}[4/5]${NC} Rendering child app manifests..."

# Function to render child app manifests
render_child_app() {
    local app_name=$1
    local revision=$2
    local output_file=$3
    local child_apps_file=$4
    
    # Get app details from the list
    local app_info=$(grep "^${app_name}|" "${child_apps_file}" 2>/dev/null | head -1)
    
    if [ -z "${app_info}" ]; then
        echo "# Application not found in this revision" > "${output_file}"
        return
    fi
    
    local repo=$(echo "${app_info}" | cut -d'|' -f2)
    local path=$(echo "${app_info}" | cut -d'|' -f3)
    local target_rev=$(echo "${app_info}" | cut -d'|' -f4)
    
    # Check if this is the same repo (relative path) or external
    if [[ "${repo}" == "."* ]] || [[ "${repo}" == "/"* ]] || [[ -z "${repo}" ]]; then
        # Local repo - extract from git
        local extract_dir=$(dirname "${output_file}")
        
        git archive "${revision}" "${path}" 2>/dev/null | tar -x -C "${extract_dir}/" 2>/dev/null || {
            echo "# Could not extract ${path} from ${revision}" > "${output_file}"
            return
        }
        
        # Determine if it's a Helm chart or plain manifests
        if [ -f "${extract_dir}/${path}/Chart.yaml" ]; then
            # Helm chart
            helm template "${app_name}" "${extract_dir}/${path}" \
                --namespace "${app_name}" \
                > "${output_file}" 2>/dev/null || {
                echo "# Could not render Helm chart ${path}" > "${output_file}"
            }
        else
            # Plain YAML manifests
            cat "${extract_dir}/${path}"/*.yaml > "${output_file}" 2>/dev/null || {
                cat "${extract_dir}/${path}"/*.yml > "${output_file}" 2>/dev/null || {
                    echo "# No manifests found in ${path}" > "${output_file}"
                }
            }
        fi
    else
        # External repo - can't fetch offline
        echo "# External repository: ${repo}" > "${output_file}"
        echo "# Path: ${path}" >> "${output_file}"
        echo "# Target Revision: ${target_rev}" >> "${output_file}"
        echo "# Cannot render external repos in offline mode" >> "${output_file}"
    fi
}

# Render each child app from both revisions
while read app_name; do
    echo -e "  Rendering: ${app_name}..."
    
    render_child_app "${app_name}" "${OLD_REVISION}" \
        "${WORK_DIR}/old/children/${app_name}.yaml" \
        "${WORK_DIR}/old/parent/child-apps.list"
    
    render_child_app "${app_name}" "${NEW_REVISION}" \
        "${WORK_DIR}/new/children/${app_name}.yaml" \
        "${WORK_DIR}/new/parent/child-apps.list"
        
done < "${WORK_DIR}/all-child-apps.list"

echo -e "${GREEN}✅ Rendered all child app manifests${NC}"
echo ""

echo -e "${BLUE}[5/5]${NC} Generating diffs..."
echo ""

# Create diffs directory
mkdir -p "${WORK_DIR}/diffs"

# Track if any changes found
HAS_CHANGES=false

# Generate diff for parent app
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}Parent App: Application CRDs${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"

PARENT_DIFF=$(diff -u "${WORK_DIR}/old/parent/applications.yaml" \
    "${WORK_DIR}/new/parent/applications.yaml" 2>/dev/null || true)

if [ -n "${PARENT_DIFF}" ]; then
    HAS_CHANGES=true
    echo "${PARENT_DIFF}" | tee "${WORK_DIR}/diffs/parent-app.diff"
    echo ""
else
    echo -e "${GREEN}✅ No changes to Application CRDs${NC}"
    echo ""
fi

# Generate diff for each child app
while read app_name; do
    echo -e "${BLUE}───────────────────────────────────────────${NC}"
    echo -e "${BLUE}Child App: ${app_name}${NC}"
    echo -e "${BLUE}───────────────────────────────────────────${NC}"
    
    CHILD_DIFF=$(diff -u "${WORK_DIR}/old/children/${app_name}.yaml" \
        "${WORK_DIR}/new/children/${app_name}.yaml" 2>/dev/null || true)
    
    if [ -n "${CHILD_DIFF}" ]; then
        HAS_CHANGES=true
        
        # Count changes
        ADDITIONS=$(echo "${CHILD_DIFF}" | grep "^+" | grep -v "^+++" | wc -l | tr -d ' ')
        DELETIONS=$(echo "${CHILD_DIFF}" | grep "^-" | grep -v "^---" | wc -l | tr -d ' ')
        
        echo -e "${GREEN}Changes: +${ADDITIONS} -${DELETIONS}${NC}"
        echo ""
        
        echo "${CHILD_DIFF}" | tee "${WORK_DIR}/diffs/${app_name}.diff"
        echo ""
    else
        echo -e "${GREEN}✅ No changes${NC}"
        echo ""
    fi
    
done < "${WORK_DIR}/all-child-apps.list"

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ "${HAS_CHANGES}" = true ]; then
    echo -e "${YELLOW}📊 Changes detected between ${OLD_REVISION} and ${NEW_REVISION}${NC}"
else
    echo -e "${GREEN}✅ No changes detected between ${OLD_REVISION} and ${NEW_REVISION}${NC}"
fi

echo ""
echo -e "${BLUE}📁 Artifacts saved to:${NC}"
echo -e "   ${WORK_DIR}/"
echo ""
echo -e "${BLUE}Directory structure:${NC}"
echo "   ├── old/"
echo "   │   ├── parent/applications.yaml    # OLD Application CRDs"
echo "   │   └── children/*.yaml             # OLD rendered manifests"
echo "   ├── new/"
echo "   │   ├── parent/applications.yaml    # NEW Application CRDs"
echo "   │   └── children/*.yaml             # NEW rendered manifests"
echo "   └── diffs/"
echo "       ├── parent-app.diff             # Parent changes"
echo "       └── *.diff                      # Child app changes"
echo ""

if [ "${HAS_CHANGES}" = true ]; then
    echo -e "${BLUE}💡 Next steps:${NC}"
    echo "   1. Review diffs above"
    echo "   2. Examine detailed artifacts in ${WORK_DIR}/"
    echo "   3. Test deployment in non-production environment"
    echo "   4. Create release tag and deploy"
else
    echo -e "${BLUE}💡 Cleanup:${NC}"
    echo "   rm -rf ${WORK_DIR}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

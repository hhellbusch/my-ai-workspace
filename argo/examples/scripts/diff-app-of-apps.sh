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

# Function to extract child app information (supports both source and sources)
extract_child_apps() {
    local manifest_file=$1
    local output_dir=$2
    
    if command -v yq &> /dev/null; then
        # Use yq for proper YAML parsing - handles both source and sources
        yq eval '
            select(.kind == "Application") |
            .metadata.name as $name |
            (
                # Check if using sources (plural)
                if .spec.sources then
                    .spec.sources | 
                    to_entries | 
                    map([$name, .key, .value.repoURL // "", .value.path // "", .value.targetRevision // "", .value.ref // ""] | join("|")) |
                    .[]
                # Otherwise use source (singular)
                else
                    [$name, "0", .spec.source.repoURL // "", .spec.source.path // "", .spec.source.targetRevision // "", ""] | join("|")
                end
            )
        ' "${manifest_file}" > "${output_dir}/child-apps-raw.list"
        
        # Create simplified list with app names for compatibility
        cut -d'|' -f1 "${output_dir}/child-apps-raw.list" | sort -u > "${output_dir}/child-apps.list"
    else
        # Fallback: basic parsing (single source only)
        echo -e "${YELLOW}⚠️  Note: Without yq, multiple sources not fully supported${NC}" >&2
        awk '
            /^kind: Application$/ { in_app=1; next }
            in_app && /^  name:/ { app_name=$2 }
            in_app && /repoURL:/ { repo=$2 }
            in_app && /path:/ { path=$2 }
            in_app && /targetRevision:/ { revision=$2; print app_name"|0|"repo"|"path"|"revision"|"; in_app=0 }
        ' "${manifest_file}" > "${output_dir}/child-apps-raw.list"
        
        cut -d'|' -f1 "${output_dir}/child-apps-raw.list" | sort -u > "${output_dir}/child-apps.list"
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
        # Count sources for this app
        local source_count_old=$(grep -c "^${app}|" "${WORK_DIR}/old/parent/child-apps-raw.list" 2>/dev/null || echo "0")
        local source_count_new=$(grep -c "^${app}|" "${WORK_DIR}/new/parent/child-apps-raw.list" 2>/dev/null || echo "0")
        
        if [ "${source_count_old}" -gt 1 ] || [ "${source_count_new}" -gt 1 ]; then
            echo -e "  - ${app} ${YELLOW}(multi-source)${NC}"
        else
            echo -e "  - ${app}"
        fi
    done
fi
echo ""

echo -e "${BLUE}[4/5]${NC} Rendering child app manifests..."

# Function to render child app manifests (supports multiple sources)
render_child_app() {
    local app_name=$1
    local revision=$2
    local output_file=$3
    local parent_dir=$4
    
    local raw_apps_file="${parent_dir}/child-apps-raw.list"
    
    # Get all sources for this app
    local app_sources=$(grep "^${app_name}|" "${raw_apps_file}" 2>/dev/null)
    
    if [ -z "${app_sources}" ]; then
        echo "# Application not found in this revision" > "${output_file}"
        return
    fi
    
    local extract_dir=$(dirname "${output_file}")/temp-${app_name}
    mkdir -p "${extract_dir}"
    
    # Parse sources
    local source_count=$(echo "${app_sources}" | wc -l | tr -d ' ')
    local chart_source=""
    local values_sources=()
    local helm_flags=()
    local has_external=false
    
    # Process each source
    while IFS='|' read -r name idx repo path target_rev ref; do
        # Check if this is the same repo (relative path) or external
        if [[ "${repo}" == "."* ]] || [[ "${repo}" == "/"* ]] || [[ -z "${repo}" ]]; then
            # Local repo - extract from git
            if [ -n "${path}" ]; then
                local source_extract_dir="${extract_dir}/source-${idx}"
                mkdir -p "${source_extract_dir}"
                
                git archive "${revision}" "${path}" 2>/dev/null | tar -x -C "${source_extract_dir}/" 2>/dev/null || {
                    echo "# Could not extract ${path} from ${revision}" > "${output_file}"
                    rm -rf "${extract_dir}"
                    return
                }
                
                # Determine if this is the chart source or values source
                if [ -f "${source_extract_dir}/${path}/Chart.yaml" ]; then
                    # This is the chart source
                    chart_source="${source_extract_dir}/${path}"
                elif [ -f "${source_extract_dir}/${path}/values.yaml" ]; then
                    # This is a values source
                    helm_flags+=("-f" "${source_extract_dir}/${path}/values.yaml")
                elif [ -f "${source_extract_dir}/${path}" ] && [[ "${path}" == *.yaml ]] || [[ "${path}" == *.yml ]]; then
                    # Single values file
                    helm_flags+=("-f" "${source_extract_dir}/${path}")
                elif [ -z "${chart_source}" ]; then
                    # Might be plain YAML or first source
                    chart_source="${source_extract_dir}/${path}"
                fi
            fi
        else
            # External repo
            has_external=true
            echo "# Source ${idx}: External repository: ${repo}" >> "${output_file}.sources"
            echo "#   Path: ${path}" >> "${output_file}.sources"
            echo "#   Target Revision: ${target_rev}" >> "${output_file}.sources"
        fi
    done <<< "${app_sources}"
    
    # Render the application
    if [ "${has_external}" = true ]; then
        cat "${output_file}.sources" > "${output_file}"
        echo "# Cannot render apps with external repos in offline mode" >> "${output_file}"
        rm -f "${output_file}.sources"
    elif [ -n "${chart_source}" ]; then
        # Check if it's a Helm chart
        if [ -f "${chart_source}/Chart.yaml" ]; then
            # Helm chart with potentially multiple value sources
            helm template "${app_name}" "${chart_source}" \
                --namespace "${app_name}" \
                "${helm_flags[@]}" \
                > "${output_file}" 2>/dev/null || {
                echo "# Could not render Helm chart ${chart_source}" > "${output_file}"
                echo "# Helm flags: ${helm_flags[*]}" >> "${output_file}"
            }
        else
            # Plain YAML manifests
            if [ -f "${chart_source}" ]; then
                # Single file
                cat "${chart_source}" > "${output_file}" 2>/dev/null
            else
                # Directory of manifests
                cat "${chart_source}"/*.yaml > "${output_file}" 2>/dev/null || {
                    cat "${chart_source}"/*.yml > "${output_file}" 2>/dev/null || {
                        echo "# No manifests found in ${chart_source}" > "${output_file}"
                    }
                }
            fi
        fi
    else
        echo "# Could not determine chart source for ${app_name}" > "${output_file}"
    fi
    
    # Cleanup temp directory
    rm -rf "${extract_dir}"
}

# Render each child app from both revisions
while read app_name; do
    echo -e "  Rendering: ${app_name}..."
    
    render_child_app "${app_name}" "${OLD_REVISION}" \
        "${WORK_DIR}/old/children/${app_name}.yaml" \
        "${WORK_DIR}/old/parent"
    
    render_child_app "${app_name}" "${NEW_REVISION}" \
        "${WORK_DIR}/new/children/${app_name}.yaml" \
        "${WORK_DIR}/new/parent"
        
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

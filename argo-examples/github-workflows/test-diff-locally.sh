#!/bin/bash
# Test ArgoCD diff generation locally before pushing
# Usage: ./test-diff-locally.sh [environment]

set -e

ENVIRONMENT=${1:-production}
CHART_PATH="./charts/argocd-apps"
VALUES_FILE="${CHART_PATH}/values.yaml"
ENV_VALUES_FILE="${CHART_PATH}/values-${ENVIRONMENT}.yaml"

echo "🔍 Testing ArgoCD Diff Generation Locally"
echo "=========================================="
echo "Environment: ${ENVIRONMENT}"
echo ""

# Check if required files exist
if [ ! -f "$VALUES_FILE" ]; then
    echo "❌ Error: Values file not found: $VALUES_FILE"
    exit 1
fi

if [ ! -f "$ENV_VALUES_FILE" ]; then
    echo "❌ Error: Environment values file not found: $ENV_VALUES_FILE"
    exit 1
fi

echo "✅ Found values files"
echo ""

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ Error: Helm is not installed"
    echo "Install: https://helm.sh/docs/intro/install/"
    exit 1
fi

echo "✅ Helm is installed: $(helm version --short)"
echo ""

# Generate manifests for current branch
echo "📝 Generating manifests for current branch..."
CURRENT_BRANCH=$(git branch --show-current)
echo "Current branch: ${CURRENT_BRANCH}"

mkdir -p /tmp/argocd-diff-test/current

helm template argocd-apps "$CHART_PATH" \
    --values "$VALUES_FILE" \
    --values "$ENV_VALUES_FILE" \
    --namespace argocd \
    > /tmp/argocd-diff-test/current/${ENVIRONMENT}.yaml

echo "✅ Generated current manifest: /tmp/argocd-diff-test/current/${ENVIRONMENT}.yaml"
echo ""

# Generate manifests for base branch (main/master)
echo "📝 Generating manifests for base branch..."

# Detect base branch
if git rev-parse --verify main >/dev/null 2>&1; then
    BASE_BRANCH="main"
elif git rev-parse --verify master >/dev/null 2>&1; then
    BASE_BRANCH="master"
else
    echo "❌ Error: Could not find main or master branch"
    exit 1
fi

echo "Base branch: ${BASE_BRANCH}"

# Save current state
CURRENT_SHA=$(git rev-parse HEAD)

# Checkout base branch
git checkout "$BASE_BRANCH" 2>/dev/null || {
    echo "❌ Error: Could not checkout ${BASE_BRANCH}"
    git checkout "$CURRENT_BRANCH"
    exit 1
}

mkdir -p /tmp/argocd-diff-test/base

helm template argocd-apps "$CHART_PATH" \
    --values "$VALUES_FILE" \
    --values "$ENV_VALUES_FILE" \
    --namespace argocd \
    > /tmp/argocd-diff-test/base/${ENVIRONMENT}.yaml 2>/dev/null || {
    echo "⚠️  Warning: Could not generate base manifest (files may not exist on base branch)"
    echo "# No base manifest" > /tmp/argocd-diff-test/base/${ENVIRONMENT}.yaml
}

echo "✅ Generated base manifest: /tmp/argocd-diff-test/base/${ENVIRONMENT}.yaml"
echo ""

# Return to original branch
git checkout "$CURRENT_BRANCH" 2>/dev/null

# Generate diff
echo "🔍 Generating diff..."
echo ""

DIFF_OUTPUT=$(diff -u \
    /tmp/argocd-diff-test/base/${ENVIRONMENT}.yaml \
    /tmp/argocd-diff-test/current/${ENVIRONMENT}.yaml \
    || true)

if [ -z "$DIFF_OUTPUT" ]; then
    echo "✅ No changes detected between ${CURRENT_BRANCH} and ${BASE_BRANCH}"
    echo ""
    echo "Your branch does not introduce any changes to the ${ENVIRONMENT} environment."
else
    echo "📊 Changes detected:"
    echo "===================="
    echo ""
    echo "$DIFF_OUTPUT" | head -n 100
    
    DIFF_LINES=$(echo "$DIFF_OUTPUT" | wc -l)
    if [ "$DIFF_LINES" -gt 100 ]; then
        echo ""
        echo "... (truncated, showing first 100 lines of $DIFF_LINES total)"
    fi
    
    # Save full diff
    echo "$DIFF_OUTPUT" > /tmp/argocd-diff-test/${ENVIRONMENT}.diff
    echo ""
    echo "📄 Full diff saved to: /tmp/argocd-diff-test/${ENVIRONMENT}.diff"
fi

echo ""
echo "📁 Test artifacts location:"
echo "   /tmp/argocd-diff-test/current/${ENVIRONMENT}.yaml"
echo "   /tmp/argocd-diff-test/base/${ENVIRONMENT}.yaml"
echo "   /tmp/argocd-diff-test/${ENVIRONMENT}.diff"
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Diff generation test complete!"
echo ""
echo "Next steps:"
echo "  1. Review the diff above"
echo "  2. If satisfied, commit and push your changes"
echo "  3. Create a PR - the GitHub Action will run automatically"
echo "  4. Review the diff in the PR comment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"


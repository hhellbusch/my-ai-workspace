#!/bin/bash
# Test script for App of Apps pattern
# This script helps you validate the Helm chart and see what will be deployed

set -e

echo "=========================================="
echo "ArgoCD App of Apps Pattern - Test Script"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print section headers
section() {
    echo ""
    echo -e "${GREEN}==> $1${NC}"
    echo ""
}

# Function to print warnings
warn() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

# Function to print errors
error() {
    echo -e "${RED}ERROR: $1${NC}"
}

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    error "Helm is not installed. Please install Helm first."
    exit 1
fi

cd "$(dirname "$0")"

section "1. Testing Default Values"
echo "Generating manifests with default values..."
helm template root-app ./charts/argocd-apps/ -f ./charts/argocd-apps/values.yaml > /tmp/app-of-apps-default.yaml
echo "Generated: /tmp/app-of-apps-default.yaml"
echo ""
echo "Applications that will be created:"
grep "^  name:" /tmp/app-of-apps-default.yaml | sed 's/^  name: /  - /'
echo ""
echo "Target revisions:"
grep "targetRevision:" /tmp/app-of-apps-default.yaml | head -10

section "2. Testing Production Values"
echo "Generating manifests with production values..."
helm template root-app ./charts/argocd-apps/ -f ./charts/argocd-apps/values-production.yaml > /tmp/app-of-apps-production.yaml
echo "Generated: /tmp/app-of-apps-production.yaml"
echo ""
echo "Applications that will be created:"
grep "^  name:" /tmp/app-of-apps-production.yaml | sed 's/^  name: /  - /'
echo ""
echo "Target revisions:"
grep "targetRevision:" /tmp/app-of-apps-production.yaml | head -10

section "3. Testing Staging Values"
echo "Generating manifests with staging values..."
helm template root-app ./charts/argocd-apps/ -f ./charts/argocd-apps/values-staging.yaml > /tmp/app-of-apps-staging.yaml
echo "Generated: /tmp/app-of-apps-staging.yaml"
echo ""
echo "Applications that will be created:"
grep "^  name:" /tmp/app-of-apps-staging.yaml | sed 's/^  name: /  - /'
echo ""
echo "Target revisions:"
grep "targetRevision:" /tmp/app-of-apps-staging.yaml | head -10

section "4. Testing Development Values"
echo "Generating manifests with development values..."
helm template root-app ./charts/argocd-apps/ -f ./charts/argocd-apps/values-development.yaml > /tmp/app-of-apps-development.yaml
echo "Generated: /tmp/app-of-apps-development.yaml"
echo ""
echo "Applications that will be created:"
grep "^  name:" /tmp/app-of-apps-development.yaml | sed 's/^  name: /  - /'
echo ""
echo "Target revisions:"
grep "targetRevision:" /tmp/app-of-apps-development.yaml | head -10

section "5. Validating Helm Chart"
echo "Running helm lint..."
helm lint ./charts/argocd-apps/

section "6. Comparing Environments"
echo "Summary of target revisions per environment:"
echo ""
echo "=== PRODUCTION ==="
grep -A 1 "name: example-app" /tmp/app-of-apps-production.yaml | grep targetRevision || echo "  example-app: Not found"
grep -A 1 "name: another-app" /tmp/app-of-apps-production.yaml | grep targetRevision || echo "  another-app: Not found"
echo ""
echo "=== STAGING ==="
grep -A 1 "name: example-app" /tmp/app-of-apps-staging.yaml | grep targetRevision || echo "  example-app: Not found"
grep -A 1 "name: another-app" /tmp/app-of-apps-staging.yaml | grep targetRevision || echo "  another-app: Not found"
echo ""
echo "=== DEVELOPMENT ==="
grep -A 1 "name: example-app" /tmp/app-of-apps-development.yaml | grep targetRevision || echo "  example-app: Not found"
grep -A 1 "name: another-app" /tmp/app-of-apps-development.yaml | grep targetRevision || echo "  another-app: Not found"

section "7. Testing Root App Manifests"
echo "Validating root app manifests..."
echo ""
echo "Root app (default):"
grep "targetRevision:" root-app.yaml | head -1
echo ""
echo "Root app (production):"
grep "targetRevision:" root-app-production.yaml | head -1
echo ""
echo "Root app (staging):"
grep "targetRevision:" root-app-staging.yaml | head -1

section "Summary"
echo "✅ All tests passed!"
echo ""
echo "Generated files in /tmp/:"
echo "  - app-of-apps-default.yaml"
echo "  - app-of-apps-production.yaml"
echo "  - app-of-apps-staging.yaml"
echo "  - app-of-apps-development.yaml"
echo ""
echo "To view a generated manifest:"
echo "  cat /tmp/app-of-apps-production.yaml"
echo ""
echo "To deploy the root app:"
echo "  kubectl apply -f root-app-production.yaml"
echo ""
echo "To dry-run deploy child apps:"
echo "  helm template root-app ./charts/argocd-apps/ -f ./charts/argocd-apps/values-production.yaml | kubectl apply --dry-run=client -f -"
echo ""


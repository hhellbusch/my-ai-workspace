#!/bin/bash

# Script to set up Hub secrets for testing fromSecret template function
# Run this on the RHACM Hub cluster

set -euo pipefail

echo "================================================"
echo "Setting up Hub Secrets for RHACM Policies"
echo "================================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if we're on Hub cluster
if ! oc get multiclusterhub -n open-cluster-management &>/dev/null; then
    echo "❌ Not connected to RHACM Hub cluster"
    exit 1
fi

echo -e "${GREEN}✓ Connected to RHACM Hub${NC}"
echo ""

# Create namespace for Hub secrets
echo "📦 Creating namespace 'rhacm-secrets'..."
oc create namespace rhacm-secrets --dry-run=client -o yaml | oc apply -f -
echo -e "${GREEN}✓ Namespace created${NC}"
echo ""

# Create database credentials
echo "🔐 Creating database credentials..."
oc create secret generic prod-database \
  -n rhacm-secrets \
  --from-literal=username='prod_admin' \
  --from-literal=password='P@ssw0rd123' \
  --from-literal=host='postgres-prod.example.com' \
  --from-literal=port='5432' \
  --from-literal=database='myapp_production' \
  --dry-run=client -o yaml | oc apply -f -
echo -e "${GREEN}✓ Database credentials created${NC}"

# Create API credentials
echo "🔑 Creating API credentials..."
oc create secret generic api-credentials \
  -n rhacm-secrets \
  --from-literal=api-key='ak_prod_123456789' \
  --from-literal=api-secret='as_prod_secret_abcdefg' \
  --dry-run=client -o yaml | oc apply -f -
echo -e "${GREEN}✓ API credentials created${NC}"

# Create registry credentials
echo "🐳 Creating registry credentials..."
oc create secret docker-registry quay-pull-secret \
  -n rhacm-secrets \
  --docker-server=quay.io \
  --docker-username='demo-user' \
  --docker-password='demo-token-12345' \
  --docker-email='user@example.com' \
  --dry-run=client -o yaml | oc apply -f -
echo -e "${GREEN}✓ Registry credentials created${NC}"

# Create TLS certificate (self-signed example)
echo "🔒 Creating TLS certificate..."
if command -v openssl &>/dev/null; then
    # Generate self-signed cert for testing
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout /tmp/tls.key \
      -out /tmp/tls.crt \
      -subj "/CN=*.example.com/O=Example Inc/C=US" \
      2>/dev/null
    
    oc create secret tls wildcard-example-com-cert \
      -n rhacm-secrets \
      --cert=/tmp/tls.crt \
      --key=/tmp/tls.key \
      --dry-run=client -o yaml | oc apply -f -
    
    rm -f /tmp/tls.key /tmp/tls.crt
    echo -e "${GREEN}✓ TLS certificate created${NC}"
else
    echo -e "${YELLOW}⚠ openssl not found, skipping TLS certificate creation${NC}"
fi

echo ""
echo "================================================"
echo "RBAC Setup"
echo "================================================"
echo ""

# Create RBAC to allow RHACM to read secrets
echo "🔐 Setting up RBAC for RHACM..."

cat <<EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: rhacm-secret-reader
  namespace: rhacm-secrets
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: rhacm-secret-reader-binding
  namespace: rhacm-secrets
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: rhacm-secret-reader
subjects:
- kind: ServiceAccount
  name: governance-policy-propagator
  namespace: open-cluster-management
EOF

echo -e "${GREEN}✓ RBAC configured${NC}"
echo ""

echo "================================================"
echo "Summary"
echo "================================================"
echo ""
echo "Created Hub secrets in namespace 'rhacm-secrets':"
echo ""
oc get secrets -n rhacm-secrets -o custom-columns=NAME:.metadata.name,TYPE:.type,AGE:.metadata.creationTimestamp
echo ""
echo "You can now use these secrets in policies with the fromSecret template:"
echo ""
echo "Example:"
echo "  stringData:"
echo "    password: '{{hub fromSecret \"rhacm-secrets\" \"prod-database\" \"password\" hub}}'"
echo ""
echo "To apply the example policies:"
echo "  oc apply -f hub-secret-reference-policy.yaml"
echo "  oc apply -f placement-binding.yaml"
echo ""
echo "✅ Setup complete!"


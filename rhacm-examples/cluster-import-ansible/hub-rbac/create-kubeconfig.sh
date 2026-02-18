#!/bin/bash
# Create kubeconfig file for service account

set -e

SA_NAME="cluster-importer"
NAMESPACE="open-cluster-management"
CLUSTER_NAME="rhacm-hub"
TOKEN_FILE="/tmp/cluster-importer-token.txt"
OUTPUT_FILE="/tmp/cluster-importer-kubeconfig"

echo "=========================================="
echo "Creating Service Account Kubeconfig"
echo "=========================================="
echo "Service Account: ${SA_NAME}"
echo "Namespace: ${NAMESPACE}"
echo "Cluster Name: ${CLUSTER_NAME}"
echo ""

# Check if token file exists
if [ ! -f ${TOKEN_FILE} ]; then
    echo "❌ Error: Token file not found: ${TOKEN_FILE}"
    echo ""
    echo "Run ./extract-token.sh first to generate the token"
    exit 1
fi

# Get cluster details
echo "Extracting cluster configuration..."
SERVER_URL=$(oc whoami --show-server)
CA_CERT=$(oc config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
TOKEN=$(cat ${TOKEN_FILE})

if [ -z "$SERVER_URL" ] || [ -z "$CA_CERT" ] || [ -z "$TOKEN" ]; then
    echo "❌ Error: Failed to extract cluster configuration"
    echo "Make sure you're logged into the hub cluster"
    exit 1
fi

# Create kubeconfig
cat > ${OUTPUT_FILE} <<EOF
apiVersion: v1
kind: Config
clusters:
  - cluster:
      certificate-authority-data: ${CA_CERT}
      server: ${SERVER_URL}
    name: ${CLUSTER_NAME}
contexts:
  - context:
      cluster: ${CLUSTER_NAME}
      namespace: ${NAMESPACE}
      user: ${SA_NAME}
    name: ${SA_NAME}@${CLUSTER_NAME}
current-context: ${SA_NAME}@${CLUSTER_NAME}
users:
  - name: ${SA_NAME}
    user:
      token: ${TOKEN}
EOF

chmod 600 ${OUTPUT_FILE}

echo ""
echo "✓ Kubeconfig created successfully"
echo ""
echo "Location: ${OUTPUT_FILE}"
echo "Server: ${SERVER_URL}"
echo ""
echo "Test the kubeconfig:"
echo "  export KUBECONFIG=${OUTPUT_FILE}"
echo "  oc whoami"
echo "  oc auth can-i create managedcluster"
echo ""
echo "Update your Ansible inventory:"
echo "  [rhacm_hub]"
echo "  hub-cluster kubeconfig_path=${OUTPUT_FILE}"

#!/bin/bash

# Generate dockerconfigjson for container registry authentication
# Usage: ./generate-dockerconfig.sh <registry> <username> <password>

set -euo pipefail

if [ $# -lt 3 ]; then
    echo "Usage: $0 <registry> <username> <password>"
    echo ""
    echo "Examples:"
    echo "  $0 docker.io myuser mypassword"
    echo "  $0 quay.io robot+myrobot token123"
    echo "  $0 registry.redhat.io '12345|service-account' token456"
    echo ""
    exit 1
fi

REGISTRY=$1
USERNAME=$2
PASSWORD=$3

# Generate base64-encoded auth string
AUTH=$(echo -n "$USERNAME:$PASSWORD" | base64 -w 0)

# Generate dockerconfigjson
DOCKER_CONFIG=$(cat <<EOF
{
  "auths": {
    "$REGISTRY": {
      "username": "$USERNAME",
      "password": "$PASSWORD",
      "auth": "$AUTH"
    }
  }
}
EOF
)

echo "================================================"
echo "Docker Config JSON (for stringData)"
echo "================================================"
echo "$DOCKER_CONFIG"
echo ""
echo "================================================"
echo "Base64-encoded (for data field)"
echo "================================================"
echo -n "$DOCKER_CONFIG" | base64 -w 0
echo ""
echo ""
echo "================================================"
echo "Create Secret Command"
echo "================================================"
echo "kubectl create secret docker-registry registry-credentials \\"
echo "  --docker-server=$REGISTRY \\"
echo "  --docker-username='$USERNAME' \\"
echo "  --docker-password='$PASSWORD' \\"
echo "  --namespace=<namespace>"
echo ""
echo "================================================"
echo "Test Login"
echo "================================================"
echo "echo '$PASSWORD' | docker login $REGISTRY -u '$USERNAME' --password-stdin"
echo ""


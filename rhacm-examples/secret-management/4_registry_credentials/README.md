# Container Registry Credentials with RHACM

Practical example for distributing container registry pull secrets across managed clusters using RHACM.

## Overview

Container registries require authentication to pull private images. This example shows how to:

1. Distribute registry credentials to managed clusters
2. Configure imagePullSecrets for different namespaces
3. Support multiple registries (Docker Hub, Quay.io, private registries)
4. Handle OpenShift-specific global pull secrets

## Use Cases

- **Private Container Registries** - Distribute credentials for private Docker registries
- **Multiple Registries** - Configure access to Docker Hub, Quay, GCR, ECR, ACR
- **Namespace-Specific** - Different credentials per namespace/environment
- **Global Pull Secrets** - OpenShift cluster-wide image pull configuration

## Prerequisites

- Registry credentials (username/password or token)
- RHACM Hub with managed clusters
- Target namespaces identified

## Registry Types

### Docker Hub
```
registry: docker.io
username: <your-username>
password: <your-password-or-token>
```

### Quay.io
```
registry: quay.io
username: <username>
password: <token>
```

### Red Hat Registry
```
registry: registry.redhat.io
username: <registry-service-account-username>
password: <registry-service-account-token>
```

### AWS ECR
```
registry: <account-id>.dkr.ecr.<region>.amazonaws.com
username: AWS
password: <aws ecr get-login-password>
```

## Quick Start

### 1. Create Registry Secret Policy

```bash
# Edit registry-credentials-policy.yaml with your credentials
oc apply -f registry-credentials-policy.yaml
oc apply -f placement-binding.yaml
```

### 2. Verify Secret Created

```bash
# Check on managed cluster
oc --context=<cluster-name> get secret registry-credentials -n <namespace>

# Test pulling an image
oc --context=<cluster-name> run test \
  --image=<your-private-image> \
  --overrides='{"spec":{"imagePullSecrets":[{"name":"registry-credentials"}]}}'
```

## Example Configurations

### Example 1: Single Registry (Docker Hub)

```yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: docker-hub-credentials
  namespace: rhacm-policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: docker-hub-pull-secret
      spec:
        remediationAction: enforce
        severity: high
        namespaceSelector:
          include:
          - default
          - production
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: Secret
            metadata:
              name: docker-hub-credentials
              namespace: "{{ (lookup "v1" "Namespace" "" "").metadata.name }}"
            type: kubernetes.io/dockerconfigjson
            data:
              .dockerconfigjson: eyJhdXRocyI6eyJkb2NrZXIuaW8iOnsidXNlcm5hbWUiOiJ5b3VydXNlcm5hbWUiLCJwYXNzd29yZCI6InlvdXJwYXNzd29yZCIsImF1dGgiOiJZWFYwYUc1aGJXVTZjR0Z6YzNkdmNtUT0ifX19
```

To generate the `.dockerconfigjson` value:
```bash
echo -n '{"auths":{"docker.io":{"username":"your-username","password":"your-password","auth":"'$(echo -n 'your-username:your-password' | base64)'"}}}' | base64 -w 0
```

### Example 2: Multiple Registries

```yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: multi-registry-credentials
  namespace: rhacm-policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: multi-registry-secret
      spec:
        remediationAction: enforce
        severity: high
        namespaceSelector:
          include:
          - production-apps
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: Secret
            metadata:
              name: all-registry-credentials
              namespace: production-apps
            type: kubernetes.io/dockerconfigjson
            stringData:
              .dockerconfigjson: |
                {
                  "auths": {
                    "docker.io": {
                      "username": "docker-user",
                      "password": "docker-token",
                      "auth": "<base64-encoded-user:pass>"
                    },
                    "quay.io": {
                      "username": "quay-user",
                      "password": "quay-token",
                      "auth": "<base64-encoded-user:pass>"
                    },
                    "registry.redhat.io": {
                      "username": "service-account-id",
                      "password": "service-account-token",
                      "auth": "<base64-encoded-user:pass>"
                    }
                  }
                }
```

### Example 3: OpenShift Global Pull Secret

Update cluster-wide pull secret configuration:

```yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: global-pull-secret
  namespace: rhacm-policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: update-global-pull-secret
      spec:
        remediationAction: enforce
        severity: high
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: Secret
            metadata:
              name: pull-secret
              namespace: openshift-config
            type: kubernetes.io/dockerconfigjson
            data:
              .dockerconfigjson: <base64-encoded-docker-config>
```

**Warning**: Updating the global pull secret triggers node restarts in OpenShift!

### Example 4: ServiceAccount with imagePullSecrets

Automatically link pull secret to ServiceAccount:

```yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: serviceaccount-with-pullsecret
  namespace: rhacm-policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  # Create the pull secret
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: create-pull-secret
      spec:
        remediationAction: enforce
        severity: high
        namespaceSelector:
          include:
          - my-app
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: Secret
            metadata:
              name: registry-credentials
              namespace: my-app
            type: kubernetes.io/dockerconfigjson
            stringData:
              .dockerconfigjson: '{"auths":{"quay.io":{"username":"user","password":"pass","auth":"dXNlcjpwYXNz"}}}'
  
  # Create ServiceAccount with imagePullSecrets
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: create-serviceaccount
      spec:
        remediationAction: enforce
        severity: medium
        namespaceSelector:
          include:
          - my-app
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: ServiceAccount
            metadata:
              name: app-deployer
              namespace: my-app
            imagePullSecrets:
            - name: registry-credentials
```

Now any Pod using this ServiceAccount automatically has access to the registry.

## Security Best Practices

### 1. Use Robot/Service Accounts

Don't use personal credentials:
- **Docker Hub**: Create access tokens
- **Quay.io**: Use robot accounts
- **Red Hat**: Registry service accounts
- **Harbor**: Robot accounts

### 2. Encrypt Secrets

The `.dockerconfigjson` should be base64-encoded, but consider:
- Using Hub secret references (RHACM 2.8+)
- External Secrets Operator for production
- Sealed Secrets for Git storage

### 3. Namespace Isolation

Create separate secrets per namespace/environment:
```yaml
namespaceSelector:
  include:
  - production-apps
  - staging-apps
  exclude:
  - kube-system
  - openshift-*
```

### 4. Audit Access

Monitor who can view secrets:
```bash
# Check RBAC
oc get rolebinding -n <namespace> -o wide | grep secrets
```

## Validation

### Test Image Pull

```bash
# Test with a pod
cat <<EOF | oc --context=<cluster-name> apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-registry-access
  namespace: my-app
spec:
  containers:
  - name: test
    image: quay.io/your-org/private-image:latest
  imagePullSecrets:
  - name: registry-credentials
  restartPolicy: Never
EOF

# Check if pod starts successfully
oc --context=<cluster-name> get pod test-registry-access -n my-app
oc --context=<cluster-name> logs test-registry-access -n my-app
```

### Verify Secret Format

```bash
# Get secret
oc get secret registry-credentials -n my-app -o yaml

# Decode and verify JSON structure
oc get secret registry-credentials -n my-app \
  -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d | jq .
```

## Troubleshooting

### ImagePullBackOff Errors

```bash
# Check pod events
oc describe pod <pod-name> -n <namespace>

# Common errors:
# - "pull access denied" - Wrong credentials
# - "unauthorized" - Token expired
# - "manifest unknown" - Image doesn't exist
# - "no basic auth credentials" - imagePullSecret not linked
```

### Secret Not Working

```bash
# Verify secret type
oc get secret registry-credentials -o jsonpath='{.type}'
# Should be: kubernetes.io/dockerconfigjson

# Verify .dockerconfigjson key exists
oc get secret registry-credentials -o jsonpath='{.data}'

# Test credentials manually
REGISTRY="docker.io"
USERNAME="your-user"
PASSWORD="your-pass"
echo "$PASSWORD" | docker login $REGISTRY -u $USERNAME --password-stdin
```

### ECR Token Expiration

AWS ECR tokens expire after 12 hours. Use External Secrets Operator:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: ecr-credentials
  namespace: my-app
spec:
  refreshInterval: 6h  # Refresh before expiration
  secretStoreRef:
    name: aws-secretstore
    kind: ClusterSecretStore
  target:
    name: ecr-pull-secret
    creationPolicy: Owner
    template:
      type: kubernetes.io/dockerconfigjson
      data:
        .dockerconfigjson: '{"auths":{"{{ .registry }}":{"username":"AWS","password":"{{ .token }}","auth":"{{ (print "AWS:" .token) | b64enc }}"}}}'
  data:
  - secretKey: registry
    remoteRef:
      key: ecr/config
      property: registry
  - secretKey: token
    remoteRef:
      key: ecr/config
      property: token
```

## Helper Scripts

### Generate dockerconfigjson

```bash
#!/bin/bash
# generate-dockerconfig.sh

REGISTRY=${1:-docker.io}
USERNAME=${2}
PASSWORD=${3}

if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo "Usage: $0 <registry> <username> <password>"
    exit 1
fi

AUTH=$(echo -n "$USERNAME:$PASSWORD" | base64 -w 0)

cat <<EOF
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
```

Usage:
```bash
./generate-dockerconfig.sh docker.io myuser mypass | base64 -w 0
```

## Next Steps

- [Example 5: Database Secrets](../5_database_secrets/) - Complete database credential workflow
- [Example 6: Advanced Patterns](../6_advanced_patterns/) - Complex scenarios

## References

- [Kubernetes Pull Secrets](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)
- [OpenShift Global Pull Secret](https://docs.openshift.com/container-platform/latest/openshift_images/managing_images/using-image-pull-secrets.html)
- [Docker Hub Access Tokens](https://docs.docker.com/docker-hub/access-tokens/)
- [Quay Robot Accounts](https://docs.quay.io/glossary/robot-accounts.html)


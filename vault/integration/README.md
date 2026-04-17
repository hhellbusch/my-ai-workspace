# Vault Integration for Multi-Cluster OpenShift Environments

**Version:** 1.0  
**Last Updated:** February 10, 2026  
**Status:** Published - Core patterns complete, additional sections planned

---

## 🤖 AI Disclosure

This document was created with substantial assistance from Claude (Anthropic's AI assistant). While comprehensive effort has been made to ensure accuracy and best practices, this content should be:

- **Validated** against official HashiCorp Vault and Red Hat OpenShift documentation
- **Tested** in non-production environments before implementation
- **Adapted** to your specific security requirements and infrastructure
- **Reviewed** by your security and operations teams

See [AI-DISCLOSURE.md](../AI-DISCLOSURE.md) for detailed guidance on using AI-generated content safely.

**Key validation points:**
- Verify Vault API compatibility with your Vault version
- Check OpenShift/Kubernetes API versions match your clusters
- Validate security policies against your compliance requirements
- Test all examples in isolated environments first

---

## Overview

This document provides security architecture designs for managing secrets across 100+ OpenShift clusters using HashiCorp Vault. It covers patterns for securely storing and distributing:

- PKI certificates (service mesh, ingress, internal CA)
- S3 access keys and credentials
- LDAP bind credentials
- Database passwords
- API tokens and service credentials

### What You'll Learn

✅ **The Bootstrap Problem Solved** - How to distribute Vault credentials to 100+ clusters without creating security vulnerabilities (Kubernetes Auth = no tokens to distribute!)

✅ **Shared Secret Organization** - Stop duplicating LDAP passwords 100+ times. Learn hierarchical secret structures with `shared/`, `regional/`, and cluster-specific paths.

✅ **KV v1 vs v2 Decision** - Understand versioning, rollback, and why KV v2 is essential for production (includes Check-and-Set for race condition prevention).

✅ **Architecture Patterns** - Three production-ready designs with detailed security analysis, ESO/RHACM integration examples, and Vault policies.

✅ **Namespace Clarity** - Clear distinction between Vault namespaces (multi-tenancy) and K8s namespaces (workload isolation).

✅ **Automation Examples** - Ansible playbooks, bash scripts, and YAML configs ready to adapt for your environment.

### Who This is For

- **Platform Engineers** managing multi-cluster OpenShift/Kubernetes fleets
- **Security Architects** designing secret management at scale
- **DevOps Teams** implementing GitOps with secure credential handling
- **Site Reliability Engineers** responsible for secret rotation and compliance
- **Anyone** evaluating Vault for enterprise Kubernetes secret management

## Table of Contents

### Core Concepts
1. [Terminology: Namespace Disambiguation](#terminology-namespace-disambiguation)
   - Vault Namespace vs K8s Namespace
2. [Vault KV Secrets Engine: v1 vs v2](#vault-kv-secrets-engine-v1-vs-v2)
   - Version comparison and recommendations
3. [Organizing Shared vs Cluster-Specific Secrets](#organizing-shared-vs-cluster-specific-secrets)
   - Hierarchical secret organization patterns

### Architecture Options
4. [Option 1: Centralized Vault + External Secrets Operator (ESO)](#option-1-centralized-vault--external-secrets-operator-eso) ⭐ RECOMMENDED
   - Most popular pattern for production deployments
5. [Option 2: RHACM Policy-Based Distribution + Vault](#option-2-rhacm-policy-based-distribution--vault)
   - Hub-and-spoke model for managed clusters
6. [Option 3: Vault Agent Sidecar Injection](#option-3-vault-agent-sidecar-injection)
   - Advanced pattern for in-memory secrets
7. [Hybrid Recommendation: Tiered Approach for 100+ Clusters](#hybrid-recommendation-tiered-approach-for-100-clusters) ⭐ **RECOMMENDED FOR LARGE FLEETS**
   - Three-tier model matching patterns to secret types
   - Tier 1: Infrastructure secrets via RHACM
   - Tier 2: Application secrets via ESO
   - Tier 3: Compliance workloads via Vault Agent
   - Implementation strategy and decision matrices

### Implementation & Operations
8. [Bootstrap Strategy: Distributing Vault Credentials](#bootstrap-strategy-distributing-vault-credentials-to-100-clusters)
   - Kubernetes Auth (recommended - no tokens!)
   - AppRole with Response Wrapping
   - Cloud Provider IAM
   - RHACM Distribution
9. [Security Best Practices](#security-best-practices)
10. [Troubleshooting Bootstrap Issues](#troubleshooting-bootstrap-issues)
11. [Quick Reference: Namespace Types](#quick-reference-namespace-types)

### Document Status
12. [Document Status & Roadmap](#document-status--roadmap)

---

## Terminology: Namespace Disambiguation

**IMPORTANT**: This document uses the term "namespace" in two distinct contexts:

### Vault Namespace
- **What it is**: HashiCorp Vault's multi-tenancy feature (Vault Enterprise)
- **Purpose**: Logical isolation within a single Vault cluster
- **Scope**: Separates secrets, policies, auth methods, and audit logs
- **Example**: `vault/prod/`, `vault/nonprod/`, `vault/cluster-group-a/`
- **Access**: Requires specific Vault token scoped to that Vault namespace
- **Format in this doc**: Will be referred to as **"Vault namespace"** or shown with `vault/` prefix

### Kubernetes/OpenShift Namespace  
- **What it is**: Kubernetes resource isolation boundary
- **Purpose**: Organizes and isolates workloads within a cluster
- **Scope**: Contains pods, services, secrets, configmaps, etc.
- **Example**: `default`, `kube-system`, `external-secrets`, `my-app-prod`
- **Access**: Controlled by RBAC (Roles, RoleBindings, ServiceAccounts)
- **Format in this doc**: Will be referred to as **"K8s namespace"** or **"OpenShift project"**

### Example Showing Both
```
Vault Cluster (vault.example.com)
├── Vault namespace: prod/                    ← Vault namespace
│   └── KV secret: cluster-001/s3-creds
│
OpenShift Cluster: cluster-001
├── K8s namespace: external-secrets            ← K8s namespace
│   └── Pod: external-secrets-operator
└── K8s namespace: my-application              ← K8s namespace
    └── Secret: s3-credentials (synced from Vault)
```

---

## Vault KV Secrets Engine: v1 vs v2

### Overview

Vault's Key-Value (KV) secrets engine comes in two versions with significantly different capabilities. Understanding these differences is critical for designing your multi-cluster secret management architecture.

### Quick Comparison

| Feature | KV v1 | KV v2 |
|---------|-------|-------|
| **Versioning** | ❌ No | ✅ Yes (configurable history depth) |
| **Secret Deletion** | Immediate, permanent | Soft delete + destroy option |
| **Undelete Capability** | ❌ No | ✅ Yes (if not destroyed) |
| **Check-and-Set (CAS)** | ❌ No | ✅ Yes (prevents race conditions) |
| **Secret Metadata** | ❌ No | ✅ Yes (created/updated timestamps, versions) |
| **API Path** | `secret/path` | `secret/data/path` (data), `secret/metadata/path` (metadata) |
| **Rollback Support** | ❌ No | ✅ Yes (to any version) |
| **TTL Support** | Per-mount only | Per-mount + per-secret |
| **Audit Trail** | Basic | Enhanced with version tracking |
| **Performance** | Slightly faster | Slightly slower (metadata overhead) |
| **Storage Overhead** | Lower | Higher (stores versions) |
| **Use Case** | Simple, ephemeral secrets | Production, compliance, audit requirements |

### KV Version 1

#### Characteristics

**Simple Key-Value Store**:
- Write a secret → overwrites previous value
- Delete a secret → gone forever
- No history, no recovery

#### API Paths

```bash
# Enable KV v1
vault secrets enable -path=secret-v1 kv

# Write secret (direct path)
vault write secret-v1/my-app/db-password password="supersecret"

# Read secret
vault read secret-v1/my-app/db-password

# API paths are simple
# Write: PUT /v1/secret-v1/my-app/db-password
# Read:  GET /v1/secret-v1/my-app/db-password
```

#### When to Use KV v1

✅ **Good for**:
- Development/testing environments
- Ephemeral secrets with no audit requirements
- High-performance scenarios (minimal overhead)
- Temporary secret storage
- Secrets that change rarely

❌ **Avoid for**:
- Production environments with compliance requirements
- Secrets that require change tracking
- Multi-user environments (race conditions possible)
- Anything requiring rollback capability

#### KV v1 with ESO Example

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-credentials
  namespace: my-app
spec:
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  
  target:
    name: db-credentials
  
  data:
  - secretKey: password
    remoteRef:
      key: secret-v1/my-app/db-password  # ← Direct path (KV v1)
      property: password
```

### KV Version 2

#### Characteristics

**Versioned Key-Value Store with Metadata**:
- Each write creates a new version (version 1, 2, 3, etc.)
- Soft delete: marks version as deleted but data remains
- Hard delete (destroy): permanently removes version
- Metadata tracks creation time, versions, deletion status
- Check-and-Set (CAS) prevents concurrent write conflicts

#### API Paths

```bash
# Enable KV v2 (default for 'secret/')
vault secrets enable -path=secret kv-v2

# Write secret (note: /data/ in path)
vault kv put secret/my-app/db-password password="supersecret"
# Creates version 1

vault kv put secret/my-app/db-password password="newsecret"
# Creates version 2 (version 1 still exists)

# Read latest version
vault kv get secret/my-app/db-password

# Read specific version
vault kv get -version=1 secret/my-app/db-password

# View all versions (metadata)
vault kv metadata get secret/my-app/db-password

# API paths have /data/ and /metadata/
# Write: POST /v1/secret/data/my-app/db-password
# Read:  GET  /v1/secret/data/my-app/db-password
# Meta:  GET  /v1/secret/metadata/my-app/db-password
```

#### Version Management

**List Versions**:
```bash
$ vault kv metadata get secret/my-app/db-password

Key                     Value
---                     -----
created_time            2024-01-15T10:30:00.123456Z
current_version         3
max_versions            10
oldest_version          1
updated_time            2024-01-20T14:22:00.789012Z
versions:
  1:
    created_time        2024-01-15T10:30:00.123456Z
    deletion_time       n/a
    destroyed           false
  2:
    created_time        2024-01-18T11:15:00.456789Z
    deletion_time       n/a
    destroyed           false
  3:
    created_time        2024-01-20T14:22:00.789012Z
    deletion_time       n/a
    destroyed           false
```

**Rollback to Previous Version**:
```bash
# Read old version
vault kv get -version=2 secret/my-app/db-password

# Write it back as new version (creates version 4 with version 2's data)
vault kv put secret/my-app/db-password password="<from-version-2>"

# Or use rollback command
vault kv rollback -version=2 secret/my-app/db-password
```

**Delete vs Destroy**:
```bash
# Soft delete (version 3 marked deleted, can be undeleted)
vault kv delete secret/my-app/db-password

# Version 3 now shows:
# deletion_time: 2024-01-21T09:00:00.123456Z
# destroyed: false

# Undelete (restores version 3)
vault kv undelete -versions=3 secret/my-app/db-password

# Hard delete (permanent, cannot be recovered)
vault kv destroy -versions=3 secret/my-app/db-password

# Version 3 now shows:
# destroyed: true
```

#### Check-and-Set (CAS)

Prevents concurrent modification issues:

```bash
# Current version is 5

# Write with CAS (only succeeds if current version is 5)
vault kv put -cas=5 secret/my-app/db-password password="updated"
# Success → creates version 6

# Another client tries to write with stale CAS
vault kv put -cas=5 secret/my-app/db-password password="different"
# Error: check-and-set parameter did not match the current version
```

**Why This Matters**:
- Multiple ESO instances syncing same secret
- GitOps pipelines updating secrets
- Manual operator changes during automation runs
- Prevents lost updates and race conditions

#### KV v2 with ESO Example

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-credentials
  namespace: my-app
spec:
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  
  target:
    name: db-credentials
  
  data:
  - secretKey: password
    remoteRef:
      key: my-app/db-password  # ← No 'data/' prefix (ESO handles it)
      property: password
      
      # Optional: Pin to specific version
      # version: "2"
```

**ESO ClusterSecretStore Configuration**:
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://vault.example.com:8200"
      namespace: "prod"  # ← Vault namespace
      path: "secret"     # ← KV v2 mount point
      version: "v2"      # ← IMPORTANT: Specify version!
      
      auth:
        kubernetes:
          mountPath: "kubernetes-cluster-001"
          role: "eso"
          serviceAccountRef:
            name: external-secrets
            namespace: external-secrets  # ← K8s namespace
```

#### Configuration Options

**Max Versions**:
```bash
# Configure secret to keep only last 10 versions
vault kv metadata put -max-versions=10 secret/my-app/db-password

# Older versions automatically deleted when limit exceeded
```

**Delete Version After (TTL)**:
```bash
# Auto-delete versions after 30 days
vault kv metadata put -delete-version-after=720h secret/my-app/db-password

# Useful for:
# - Temporary credentials
# - Compliance with data retention policies
# - Automatic secret rotation enforcement
```

**CAS Required**:
```bash
# Enforce CAS on all writes to this secret
vault kv metadata put -cas-required=true secret/my-app/db-password

# All writes must include -cas parameter
vault kv put -cas=5 secret/my-app/db-password password="newpass"
```

### Migration from v1 to v2

If you have existing KV v1 secrets, you cannot upgrade in-place. You must migrate:

```bash
#!/bin/bash
# Migration script: KV v1 → KV v2

SOURCE_PATH="secret-v1"
DEST_PATH="secret"  # KV v2 mount

# List all secrets in v1
vault list -format=json ${SOURCE_PATH}/ | jq -r '.[]' | while read -r secret; do
  echo "Migrating: ${secret}"
  
  # Read from v1
  vault read -format=json ${SOURCE_PATH}/${secret} > /tmp/secret.json
  
  # Extract data
  DATA=$(cat /tmp/secret.json | jq -r '.data')
  
  # Write to v2 (creates version 1)
  echo "$DATA" | vault kv put ${DEST_PATH}/${secret} -
  
  echo "✅ Migrated: ${secret}"
done

rm /tmp/secret.json
```

**Ansible Migration Playbook**:
```yaml
---
- name: Migrate KV v1 secrets to KV v2
  hosts: localhost
  vars:
    vault_namespace: "prod"  # ← Vault namespace
    source_mount: "secret-v1"
    dest_mount: "secret"
  
  tasks:
  - name: List all secrets in KV v1
    command: vault list -format=json {{ source_mount }}/
    register: secrets_list
    environment:
      VAULT_NAMESPACE: "{{ vault_namespace }}"
  
  - name: Parse secret list
    set_fact:
      secrets: "{{ secrets_list.stdout | from_json }}"
  
  - name: Migrate each secret
    loop: "{{ secrets }}"
    block:
    - name: Read secret from KV v1
      command: vault read -format=json {{ source_mount }}/{{ item }}
      register: secret_data
    
    - name: Write to KV v2
      command: vault kv put {{ dest_mount }}/{{ item }} {{ secret_data.stdout | from_json | json_query('data') | to_json }}
      environment:
        VAULT_NAMESPACE: "{{ vault_namespace }}"
    
    - debug:
        msg: "✅ Migrated {{ item }}"
```

### Security Implications

#### KV v1 Risks

❌ **Accidental Overwrite**: No protection against accidental updates  
❌ **No Recovery**: Deleted = gone forever  
❌ **Limited Audit**: Can't track who changed what when  
❌ **Race Conditions**: Two clients writing simultaneously = data loss  
❌ **No Rollback**: Can't undo a bad change

#### KV v2 Benefits

✅ **Change Tracking**: Full audit trail with timestamps  
✅ **Accident Recovery**: Undelete soft-deleted secrets  
✅ **Compliance**: Version history for audit requirements  
✅ **Rollback**: Restore previous working configuration  
✅ **CAS Protection**: Prevents concurrent modification issues  
✅ **Automated Cleanup**: TTL-based version deletion

### Recommendations for 100+ Clusters

#### Production Secrets: Use KV v2

```
vault/prod/secret/  ← KV v2 mount in Vault namespace 'prod/'
├── cluster-001/
│   ├── s3-credentials      (v1, v2, v3...)
│   ├── ldap-bind-password  (v1, v2...)
│   └── pki/certificates    (v1, v2...)
├── cluster-002/
│   └── ...
└── shared/
    └── ca-bundle           (v1, v2, v3...)

Configuration:
- max-versions: 10 (keep last 10 changes)
- delete-version-after: 2160h (90 days)
- cas-required: true (for critical secrets)
```

#### Non-Production: KV v2 (Simplified)

```
vault/nonprod/secret/  ← KV v2 mount in Vault namespace 'nonprod/'
├── dev-cluster-001/
│   └── test-credentials (v1, v2...)
└── qa-cluster-001/
    └── qa-credentials   (v1, v2...)

Configuration:
- max-versions: 5 (less history needed)
- delete-version-after: 720h (30 days)
- cas-required: false (more flexibility)
```

#### Ephemeral/Temporary: KV v1 (Optional)

```
vault/prod/temp/  ← KV v1 mount for temporary secrets
├── bootstrap-tokens/
└── one-time-passwords/

Use for:
- Bootstrap credentials (used once, then deleted)
- Temporary access tokens
- Short-lived test secrets
```

### ESO Configuration: Handling Both Versions

**ClusterSecretStore for KV v2** (recommended):
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-kv2
spec:
  provider:
    vault:
      server: "https://vault.example.com:8200"
      namespace: "prod"  # ← Vault namespace
      path: "secret"     # ← KV v2 mount
      version: "v2"      # ← Critical setting
      auth:
        kubernetes:
          mountPath: "kubernetes-cluster-001"
          role: "eso"
          serviceAccountRef:
            name: external-secrets
            namespace: external-secrets  # ← K8s namespace
```

**ClusterSecretStore for KV v1** (if needed):
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-kv1
spec:
  provider:
    vault:
      server: "https://vault.example.com:8200"
      namespace: "prod"  # ← Vault namespace
      path: "secret-v1"  # ← KV v1 mount
      version: "v1"      # ← Critical setting
      auth:
        kubernetes:
          mountPath: "kubernetes-cluster-001"
          role: "eso"
          serviceAccountRef:
            name: external-secrets
            namespace: external-secrets  # ← K8s namespace
```

### Vault Policies for KV v2

**Important**: Policies differ for KV v2 due to `/data/` and `/metadata/` paths:

```hcl
# Policy: cluster-001-eso-policy
# For KV v2 mount at 'secret/'

# Read secrets (note: /data/ path)
path "secret/data/cluster-001/*" {
  capabilities = ["read"]
}

# List secrets (note: /metadata/ path)
path "secret/metadata/cluster-001/*" {
  capabilities = ["list"]
}

# For read-write access (update operations):
path "secret/data/cluster-001/*" {
  capabilities = ["create", "read", "update"]
}

path "secret/metadata/cluster-001/*" {
  capabilities = ["list", "read"]
}

# Optional: Allow reading specific versions
path "secret/data/cluster-001/*" {
  capabilities = ["read"]
  allowed_parameters = {
    "version" = []
  }
}
```

**KV v1 Policy** (simpler):
```hcl
# Policy for KV v1 mount at 'secret-v1/'
path "secret-v1/cluster-001/*" {
  capabilities = ["read"]
}
```

### Common Mistakes

#### ❌ Wrong API Path for KV v2

```bash
# WRONG: Forgetting /data/ in path
vault read secret/my-app/password
# Error: unsupported operation

# CORRECT: Include /data/
vault read secret/data/my-app/password
```

```yaml
# WRONG in ExternalSecret
remoteRef:
  key: secret/data/my-app/password  # ← Don't include /data/ with ESO

# CORRECT
remoteRef:
  key: my-app/password  # ← ESO adds /data/ automatically when version: "v2"
```

#### ❌ Wrong Version in ClusterSecretStore

```yaml
# If your Vault mount is KV v2 but you configure v1:
spec:
  provider:
    vault:
      path: "secret"  # ← This is KV v2
      version: "v1"   # ← WRONG! Will cause errors
```

#### ❌ Not Configuring Max Versions

```bash
# Without limits, versions accumulate forever
# Secret with 1000 versions = slow reads, high storage

# Set limits:
vault kv metadata put -max-versions=10 secret/my-app/password
```

### Performance Considerations

**KV v1**:
- Faster writes (no versioning overhead)
- Lower storage usage
- Faster reads (no metadata lookup)

**KV v2**:
- Slightly slower writes (~10-20% overhead)
- Higher storage usage (keeps versions)
- Metadata lookups add latency

**Optimization for KV v2**:
```bash
# Keep max-versions reasonable
vault kv metadata put -max-versions=5 secret/high-traffic-app/config

# Use delete-version-after for auto-cleanup
vault kv metadata put -delete-version-after=168h secret/temp-creds/token

# Pin ESO to specific version for stable reads (avoids "latest" lookup)
```

---

## Organizing Shared vs Cluster-Specific Secrets

### The Challenge

In a fleet of 100+ clusters, some secrets are:
- **Cluster-specific**: S3 keys unique to each cluster, per-cluster PKI certificates
- **Shared across all clusters**: LDAP bind credentials, root CA bundles, shared database credentials
- **Shared within groups**: Regional proxy credentials, environment-specific API keys

Duplicating shared secrets 100+ times creates:
- ❌ **Operational overhead**: Update LDAP password = 100+ individual updates
- ❌ **Drift risk**: Clusters end up with different versions
- ❌ **Storage waste**: Same data stored hundreds of times
- ❌ **Audit complexity**: Hard to track which clusters have been updated

### Solution: Hierarchical Secret Organization

### Pattern 1: Shared Path with Per-Cluster Paths (RECOMMENDED)

**Vault Structure** (within Vault namespace `prod/`):

```
vault/prod/secret/data/
├── shared/                           # ← Shared secrets (all clusters)
│   ├── ldap/
│   │   ├── bind-credentials         # All clusters use this
│   │   ├── server-list              # LDAP server hostnames
│   │   └── ca-certificate           # LDAP server CA cert
│   ├── certificates/
│   │   ├── root-ca-bundle           # Organization root CA
│   │   └── intermediate-ca          # Shared intermediate CA
│   ├── observability/
│   │   ├── splunk-hec-token         # Shared logging token
│   │   └── prometheus-remote-write  # Shared monitoring credentials
│   └── registries/
│       ├── redhat-pull-secret       # Shared registry credentials
│       └── artifactory-credentials
│
├── regional/                         # ← Regional shared secrets
│   ├── us-east-1/
│   │   ├── proxy-credentials        # Proxy for US East clusters
│   │   └── s3-bucket-endpoint       # Regional S3 endpoint
│   ├── us-west-2/
│   │   └── proxy-credentials
│   └── eu-central-1/
│       └── proxy-credentials
│
├── cluster-001/                      # ← Cluster-specific secrets
│   ├── s3-credentials               # Unique to cluster-001
│   ├── etcd-encryption-key          # Unique encryption key
│   ├── certificates/
│   │   ├── api-server-cert
│   │   └── ingress-wildcard-cert
│   └── tokens/
│       └── github-webhook-secret
│
├── cluster-002/                      # ← Cluster-specific secrets
│   ├── s3-credentials
│   ├── etcd-encryption-key
│   └── ...
│
└── cluster-100/
    └── ...
```

**Vault Commands to Create Structure**:

```bash
#!/bin/bash
# Setup shared secrets structure

VAULT_NS="prod"  # ← Vault namespace
export VAULT_NAMESPACE="$VAULT_NS"

# Create shared LDAP credentials (used by all clusters)
vault kv put secret/shared/ldap/bind-credentials \
  bind_dn="cn=ldap-bind,ou=service-accounts,dc=example,dc=com" \
  bind_password="<secure-password>" \
  server="ldaps://ldap.example.com:636"

vault kv put secret/shared/ldap/ca-certificate \
  ca_cert="$(cat /path/to/ldap-ca.crt)"

# Create shared root CA bundle
vault kv put secret/shared/certificates/root-ca-bundle \
  ca_bundle="$(cat /path/to/root-ca-bundle.pem)"

# Create shared registry pull secret
vault kv put secret/shared/registries/redhat-pull-secret \
  pull_secret="$(cat ~/.docker/config.json)"

# Create regional proxy credentials
vault kv put secret/regional/us-east-1/proxy-credentials \
  http_proxy="http://proxy-east.example.com:3128" \
  https_proxy="https://proxy-east.example.com:3128" \
  proxy_user="proxy-service" \
  proxy_password="<secure-password>"

# Create cluster-specific secrets (per cluster)
for cluster in cluster-001 cluster-002 cluster-003; do
  vault kv put secret/${cluster}/s3-credentials \
    access_key="AKIA$(uuidgen | tr -d '-' | cut -c1-16)" \
    secret_key="$(openssl rand -base64 32)" \
    bucket="${cluster}-backups"
  
  vault kv put secret/${cluster}/etcd-encryption-key \
    key="$(openssl rand -base64 32)"
done
```

**Vault Policies** (grant access to both shared and cluster-specific):

```hcl
# Policy: cluster-001-eso-policy
# Allows cluster-001 to read its own secrets + shared secrets

# Access to cluster-specific secrets
path "secret/data/cluster-001/*" {
  capabilities = ["read"]
}

path "secret/metadata/cluster-001/*" {
  capabilities = ["list"]
}

# Access to shared secrets (all clusters)
path "secret/data/shared/*" {
  capabilities = ["read"]
}

path "secret/metadata/shared/*" {
  capabilities = ["list"]
}

# Access to regional secrets (if cluster is in us-east-1)
path "secret/data/regional/us-east-1/*" {
  capabilities = ["read"]
}

path "secret/metadata/regional/us-east-1/*" {
  capabilities = ["list"]
}
```

**Policy Generation Script** (automate for 100+ clusters):

```bash
#!/bin/bash
# generate-cluster-policy.sh

CLUSTER_NAME="$1"
REGION="$2"
VAULT_NS="prod"  # ← Vault namespace

cat > ${CLUSTER_NAME}-policy.hcl <<EOF
# Policy for ${CLUSTER_NAME}
# Generated: $(date)

# Cluster-specific secrets
path "secret/data/${CLUSTER_NAME}/*" {
  capabilities = ["read"]
}

path "secret/metadata/${CLUSTER_NAME}/*" {
  capabilities = ["list"]
}

# Shared secrets (all clusters)
path "secret/data/shared/*" {
  capabilities = ["read"]
}

path "secret/metadata/shared/*" {
  capabilities = ["list"]
}

# Regional secrets
path "secret/data/regional/${REGION}/*" {
  capabilities = ["read"]
}

path "secret/metadata/regional/${REGION}/*" {
  capabilities = ["list"]
}
EOF

# Write policy to Vault
export VAULT_NAMESPACE="$VAULT_NS"
vault policy write ${CLUSTER_NAME}-eso-policy ${CLUSTER_NAME}-policy.hcl

echo "✅ Created policy: ${CLUSTER_NAME}-eso-policy"
```

**Usage**:
```bash
./generate-cluster-policy.sh cluster-001 us-east-1
./generate-cluster-policy.sh cluster-002 us-east-1
./generate-cluster-policy.sh cluster-050 eu-central-1
```

**ESO Configuration** (access both shared and cluster-specific):

```yaml
---
# ClusterSecretStore (same for all clusters)
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://vault.example.com:8200"
      namespace: "prod"  # ← Vault namespace
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes-cluster-001"
          role: "eso"
          serviceAccountRef:
            name: external-secrets
            namespace: external-secrets  # ← K8s namespace

---
# ExternalSecret: Shared LDAP credentials (same for all clusters)
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: ldap-bind-credentials
  namespace: authentication  # ← K8s namespace
spec:
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  
  target:
    name: ldap-bind-credentials
  
  data:
  - secretKey: bind_dn
    remoteRef:
      key: shared/ldap/bind-credentials  # ← Shared path
      property: bind_dn
  
  - secretKey: bind_password
    remoteRef:
      key: shared/ldap/bind-credentials  # ← Shared path
      property: bind_password
  
  - secretKey: server
    remoteRef:
      key: shared/ldap/bind-credentials  # ← Shared path
      property: server
  
  - secretKey: ca_cert
    remoteRef:
      key: shared/ldap/ca-certificate  # ← Shared path
      property: ca_cert
  
  refreshInterval: 12h  # Check for updates twice daily

---
# ExternalSecret: Cluster-specific S3 credentials
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: s3-backup-credentials
  namespace: backup  # ← K8s namespace
spec:
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  
  target:
    name: s3-backup-credentials
  
  data:
  - secretKey: access_key
    remoteRef:
      key: cluster-001/s3-credentials  # ← Cluster-specific path
      property: access_key
  
  - secretKey: secret_key
    remoteRef:
      key: cluster-001/s3-credentials  # ← Cluster-specific path
      property: secret_key
  
  refreshInterval: 1h

---
# ExternalSecret: Regional proxy (shared within region)
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: proxy-credentials
  namespace: kube-system  # ← K8s namespace
spec:
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  
  target:
    name: proxy-credentials
  
  data:
  - secretKey: http_proxy
    remoteRef:
      key: regional/us-east-1/proxy-credentials  # ← Regional path
      property: http_proxy
  
  - secretKey: https_proxy
    remoteRef:
      key: regional/us-east-1/proxy-credentials  # ← Regional path
      property: https_proxy
  
  refreshInterval: 24h
```

### Pattern 2: Environment-Based Organization

**Structure** (multiple Vault namespaces):

```
vault/prod/secret/data/                # ← Vault namespace: prod/
├── shared/
│   └── ldap/bind-credentials         # Production LDAP
├── cluster-001/
├── cluster-002/
└── ...

vault/nonprod/secret/data/             # ← Vault namespace: nonprod/
├── shared/
│   └── ldap/bind-credentials         # Non-prod LDAP (different creds)
├── dev-cluster-001/
├── qa-cluster-001/
└── ...
```

**Benefits**:
- ✅ Complete isolation between prod and nonprod
- ✅ Different LDAP credentials per environment (security best practice)
- ✅ Separate audit logs per environment
- ✅ Blast radius containment

**Policy Example**:
```hcl
# Vault namespace: prod/
# Policy: prod-cluster-001-eso-policy

path "secret/data/shared/*" {
  capabilities = ["read"]
}

path "secret/data/cluster-001/*" {
  capabilities = ["read"]
}

# Cannot access nonprod secrets (different Vault namespace)
```

### Pattern 3: Composite Secrets (Combine Shared + Cluster-Specific)

**Use Case**: Secret requires both shared and cluster-specific values

**Example**: LDAP config with cluster-specific search base

```yaml
---
# ExternalSecret: Composite LDAP config
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: ldap-config
  namespace: authentication  # ← K8s namespace
spec:
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  
  target:
    name: ldap-config
    template:
      # Use Go templates to combine multiple sources
      data:
        ldap.conf: |
          # Shared LDAP server and bind credentials
          URI {{ .server }}
          BASE {{ .search_base }}
          BINDDN {{ .bind_dn }}
          BINDPW {{ .bind_password }}
          
          # Cluster-specific group filter
          GROUP_FILTER {{ .group_filter }}
          
          TLS_CACERT /etc/ldap/ca.crt
  
  data:
  # Shared credentials (all clusters)
  - secretKey: server
    remoteRef:
      key: shared/ldap/bind-credentials
      property: server
  
  - secretKey: bind_dn
    remoteRef:
      key: shared/ldap/bind-credentials
      property: bind_dn
  
  - secretKey: bind_password
    remoteRef:
      key: shared/ldap/bind-credentials
      property: bind_password
  
  # Cluster-specific settings
  - secretKey: search_base
    remoteRef:
      key: cluster-001/ldap-config
      property: search_base  # e.g., "ou=cluster-001,dc=example,dc=com"
  
  - secretKey: group_filter
    remoteRef:
      key: cluster-001/ldap-config
      property: group_filter  # e.g., "cn=cluster-001-*"
```

### Pattern 4: Secret References (Advanced)

**Use Case**: Store secret paths instead of duplicating values

```bash
# Instead of duplicating LDAP password in 100 policies,
# store a reference to the shared secret

# Cluster-specific path contains a reference
vault kv put secret/cluster-001/ldap-config \
  credentials_path="shared/ldap/bind-credentials" \
  search_base="ou=cluster-001,dc=example,dc=com"
```

**ESO with References**:
```yaml
---
# ExternalSecret that resolves references
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: ldap-credentials
  namespace: authentication  # ← K8s namespace
spec:
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  
  target:
    name: ldap-credentials
  
  # Step 1: Get the reference path
  dataFrom:
  - extract:
      key: cluster-001/ldap-config
  
  # Step 2: ESO follows the reference automatically
  # (Requires ESO v0.9.0+ with reference support)
```

### What Should Be Shared vs Cluster-Specific?

#### ✅ Good Candidates for Shared Secrets

| Secret Type | Why Share | Path Example |
|-------------|-----------|--------------|
| **LDAP bind credentials** | Single corporate LDAP server | `shared/ldap/bind-credentials` |
| **Root CA bundle** | Organization-wide trust anchors | `shared/certificates/root-ca-bundle` |
| **Registry pull secrets** | Red Hat, Quay, Artifactory access | `shared/registries/pull-secrets` |
| **Monitoring endpoints** | Splunk HEC, Prometheus remote-write | `shared/observability/endpoints` |
| **Shared database (read-only)** | Reporting database credentials | `shared/databases/reporting-ro` |
| **External API keys** | Third-party services (PagerDuty, Slack) | `shared/integrations/pagerduty` |

#### ❌ Should NOT Be Shared (Cluster-Specific)

| Secret Type | Why Separate | Path Example |
|-------------|-------------|--------------|
| **S3 bucket credentials** | Blast radius isolation | `cluster-001/s3-credentials` |
| **Etcd encryption keys** | Unique per cluster | `cluster-001/etcd-encryption-key` |
| **API server certificates** | Unique per cluster endpoint | `cluster-001/certificates/api-server` |
| **Ingress wildcard certs** | Different domains per cluster | `cluster-001/certificates/ingress` |
| **GitHub webhook secrets** | Unique per cluster webhook | `cluster-001/tokens/github-webhook` |
| **Database credentials (RW)** | Isolation, audit trail | `cluster-001/databases/app-db` |

#### ⚠️ Regional Shared Secrets

| Secret Type | Why Regional | Path Example |
|-------------|-------------|--------------|
| **Proxy credentials** | Different proxies per region | `regional/us-east-1/proxy` |
| **S3 endpoints** | Regional S3 buckets | `regional/us-west-2/s3-endpoint` |
| **DNS servers** | Regional DNS infrastructure | `regional/eu-central-1/dns` |
| **NTP servers** | Regional time sources | `regional/ap-southeast-1/ntp` |

### Rotation Strategy for Shared Secrets

**Challenge**: Rotating a shared LDAP password = updating 100+ clusters

**Solution 1: ESO Auto-Refresh** (RECOMMENDED)

```yaml
# All clusters configured with refreshInterval
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: ldap-bind-credentials
  namespace: authentication
spec:
  refreshInterval: 5m  # ← Check Vault every 5 minutes
  
  data:
  - secretKey: bind_password
    remoteRef:
      key: shared/ldap/bind-credentials
      property: bind_password
```

**Rotation Process**:
```bash
# 1. Update shared secret in Vault
vault kv put secret/shared/ldap/bind-credentials \
  bind_dn="cn=ldap-bind,ou=service-accounts,dc=example,dc=com" \
  bind_password="<new-password>" \
  server="ldaps://ldap.example.com:636"

# 2. ESO automatically syncs to all 100+ clusters within 5 minutes
# 3. Monitor sync status across all clusters
```

**Solution 2: Version Pinning + Controlled Rollout**

```yaml
# During rotation, pin clusters to old version
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: ldap-bind-credentials
  namespace: authentication
spec:
  data:
  - secretKey: bind_password
    remoteRef:
      key: shared/ldap/bind-credentials
      property: bind_password
      version: "5"  # ← Pin to version 5 (old password)
```

**Rotation Process**:
```bash
# 1. Update shared secret (creates version 6)
vault kv put secret/shared/ldap/bind-credentials \
  bind_password="<new-password>" \
  # ... other fields

# 2. Test with canary clusters (update ExternalSecret to version: "6")
kubectl patch externalsecret ldap-bind-credentials \
  -n authentication \
  --type=merge \
  -p '{"spec":{"data":[{"secretKey":"bind_password","remoteRef":{"version":"6"}}]}}'

# 3. Once validated, remove version pin (all clusters get version 6)
# 4. Or use GitOps to roll out version change gradually
```

**Solution 3: Dual Credentials During Transition**

```bash
# Vault secret with both old and new credentials
vault kv put secret/shared/ldap/bind-credentials \
  bind_dn="cn=ldap-bind,ou=service-accounts,dc=example,dc=com" \
  bind_password="<current-password>" \
  bind_password_new="<new-password>" \
  server="ldaps://ldap.example.com:636"

# Applications configured to try bind_password_new first, fallback to bind_password
# Once all clusters migrated, remove bind_password (old)
```

### Monitoring Shared Secret Access

**Vault Audit Log Analysis**:

```bash
# Query Vault audit logs for shared secret access
# Identify which clusters have accessed the shared LDAP secret

vault audit log | jq -r 'select(.request.path == "secret/data/shared/ldap/bind-credentials") | 
  "\(.auth.display_name) accessed LDAP credentials at \(.time)"'

# Output:
# cluster-001-eso accessed LDAP credentials at 2024-01-20T10:30:00Z
# cluster-002-eso accessed LDAP credentials at 2024-01-20T10:31:00Z
# cluster-050-eso accessed LDAP credentials at 2024-01-20T10:35:00Z
```

**Prometheus Metrics** (from ESO):

```promql
# Check if all clusters have synced the shared secret
count(externalsecrets_sync_calls_total{secret_key="shared/ldap/bind-credentials",status="success"})

# Alert if any cluster hasn't synced in last hour
externalsecrets_sync_calls_total{
  secret_key="shared/ldap/bind-credentials",
  status="success"
} < (time() - 3600)
```

### Security Considerations

#### ✅ Benefits of Shared Secrets

- **Operational efficiency**: Update once, propagate everywhere
- **Consistency**: All clusters have identical credentials
- **Reduced error rate**: No manual copy-paste across 100+ clusters
- **Faster rotation**: Single Vault update vs 100+ updates

#### ⚠️ Risks of Shared Secrets

- **Larger blast radius**: Compromised shared secret = all clusters affected
- **Wider access**: More Vault policies grant access to shared secrets
- **Rotation complexity**: All 100+ clusters must rotate simultaneously
- **Audit challenges**: Harder to track which cluster caused issue

#### 🛡️ Risk Mitigation

```hcl
# 1. Separate Vault namespaces for prod vs nonprod
# Even shared secrets are environment-isolated

vault/prod/secret/shared/ldap/bind-credentials      # Prod LDAP (different password)
vault/nonprod/secret/shared/ldap/bind-credentials   # Nonprod LDAP

# 2. Read-only shared credentials where possible
vault kv put secret/shared/databases/reporting-db \
  username="readonly-user" \
  password="<password>" \
  permissions="SELECT only"

# 3. Audit logging on shared secret paths
vault audit enable file file_path=/vault/logs/shared-secrets-audit.log

# 4. Alerts on shared secret changes
vault audit log | jq -r 'select(.request.path | startswith("secret/data/shared/")) | 
  "\(.auth.display_name) modified \(.request.path)"' | 
  send-to-siem

# 5. Require multiple approvers for shared secret changes (Vault Enterprise)
vault write secret/shared/ldap/bind-credentials \
  -require-approval=2 \  # Requires 2 approvers
  bind_password="<new-password>"
```

### Example: Complete Secret Organization for 100+ Cluster Fleet

```
vault/prod/secret/data/                    # ← Vault namespace: prod/
│
├── shared/                                # Shared by ALL prod clusters
│   ├── ldap/
│   │   ├── bind-credentials              # ★ Corporate LDAP
│   │   └── ca-certificate
│   ├── certificates/
│   │   ├── root-ca-bundle                # ★ Org root CA
│   │   └── intermediate-ca
│   ├── registries/
│   │   ├── redhat-pull-secret            # ★ Red Hat subscription
│   │   └── artifactory-credentials       # ★ Internal registry
│   ├── observability/
│   │   ├── splunk-hec-token              # ★ Shared Splunk
│   │   └── prometheus-remote-write       # ★ Shared Prometheus
│   └── integrations/
│       ├── pagerduty-api-key             # ★ Alerting
│       └── slack-webhook                 # ★ Notifications
│
├── regional/                              # Shared within REGION
│   ├── us-east-1/
│   │   ├── proxy-credentials             # ★ Regional proxy
│   │   ├── s3-endpoint                   # Regional S3
│   │   └── dns-servers
│   ├── us-west-2/
│   │   └── proxy-credentials
│   └── eu-central-1/
│       └── proxy-credentials
│
├── cluster-001/                           # Cluster-specific (us-east-1)
│   ├── s3-credentials                    # Unique S3 key
│   ├── etcd-encryption-key               # Unique encryption
│   ├── certificates/
│   │   ├── api-server-cert
│   │   └── ingress-wildcard-cert
│   ├── databases/
│   │   └── app-db-credentials            # Unique DB user
│   └── tokens/
│       └── github-webhook-secret
│
├── cluster-002/                           # Cluster-specific (us-east-1)
│   └── ... (same structure as cluster-001)
│
├── cluster-050/                           # Cluster-specific (eu-central-1)
│   └── ... (uses regional/eu-central-1 for regional secrets)
│
└── cluster-100/
    └── ...

# Result:
# - LDAP password: Stored ONCE, used by 100+ clusters
# - Proxy credentials: Stored 3 times (one per region)
# - S3 credentials: Stored 100+ times (unique per cluster)
```

---

## Architecture Design Options

This document presents four primary architectural patterns, followed by a hybrid recommendation for large-scale deployments.

---

## Option 1: Centralized Vault + External Secrets Operator (ESO)

**STATUS**: ✅ **RECOMMENDED** for most use cases

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│  Centralized Vault Cluster (vault.example.com)         │
│  ┌───────────────────────────────────────────────────┐ │
│  │ Vault namespace: prod/                            │ │
│  │   ├── auth/kubernetes/cluster-001/               │ │
│  │   ├── auth/kubernetes/cluster-002/               │ │
│  │   └── secret/data/cluster-*/...                  │ │
│  │                                                   │ │
│  │ Vault namespace: nonprod/                        │ │
│  │   └── secret/data/cluster-*/...                  │ │
│  └───────────────────────────────────────────────────┘ │
│  Storage: Raft (HA 5-node)                             │
└──────────────────┬──────────────────────────────────────┘
                   │ TLS 1.3 + mTLS
        ┌──────────┼──────────────────────┐
        │          │                      │
┌───────▼─────┐ ┌──▼──────────┐    ┌─────▼─────────┐
│ cluster-001 │ │ cluster-002 │    │ cluster-100   │
│ (OpenShift) │ │ (OpenShift) │... │ (OpenShift)   │
│             │ │             │    │               │
│ K8s NS:     │ │ K8s NS:     │    │ K8s NS:       │
│ external-   │ │ external-   │    │ external-     │
│ secrets     │ │ secrets     │    │ secrets       │
│   └─ESO     │ │   └─ESO     │    │   └─ESO       │
│             │ │             │    │               │
│ K8s NS:     │ │ K8s NS:     │    │ K8s NS:       │
│ my-app      │ │ production  │    │ workloads     │
│   └─Secret  │ │   └─Secret  │    │   └─Secret    │
└─────────────┘ └─────────────┘    └───────────────┘
```

### Components

#### Vault Configuration

**Vault Namespace Structure** (Vault Enterprise):
```
vault/
├── prod/                           # Vault namespace for production
│   ├── auth/kubernetes/           # K8s auth method
│   │   ├── cluster-001/          # Role per cluster
│   │   ├── cluster-002/
│   │   └── cluster-N/
│   ├── secret/kv/                # KV v2 secrets engine
│   │   ├── cluster-001/
│   │   │   ├── s3-credentials
│   │   │   ├── ldap-bind-password
│   │   │   └── certificates/
│   │   └── shared/               # Shared secrets (use sparingly)
│   └── pki/intermediate/         # PKI engine for certs
│
├── nonprod/                       # Vault namespace for non-prod
│   └── (similar structure)
│
└── security-team/                 # Administrative Vault namespace
    └── audit-logs/
```

**Auth Method: Kubernetes Auth** (configured per cluster):
```hcl
# Enable Kubernetes auth in Vault namespace: prod/
# This allows cluster-001 to authenticate using its K8s service accounts

vault write auth/kubernetes/config \
  kubernetes_host="https://api.cluster-001.example.com:6443" \
  kubernetes_ca_cert=@ca.crt \
  token_reviewer_jwt=@reviewer-token.jwt

# Create Vault role for cluster-001's external-secrets operator
vault write auth/kubernetes/role/cluster-001-eso \
  bound_service_account_names=external-secrets \
  bound_service_account_namespaces=external-secrets \
  policies=cluster-001-read-policy \
  ttl=1h \
  max_ttl=24h
```

**Vault Policy** (least privilege per cluster):
```hcl
# Policy: cluster-001-read-policy
# This runs in Vault namespace: prod/

# Allow reading secrets specific to cluster-001
path "secret/data/cluster-001/*" {
  capabilities = ["read", "list"]
}

# Allow reading shared secrets
path "secret/data/shared/*" {
  capabilities = ["read"]
}

# Allow issuing certificates from PKI
path "pki/intermediate/issue/cluster-001" {
  capabilities = ["create", "update"]
}

# Deny access to other clusters' secrets
path "secret/data/cluster-002/*" {
  capabilities = ["deny"]
}
```

#### OpenShift/K8s Configuration

**External Secrets Operator Deployment** (in K8s namespace: `external-secrets`):

```yaml
---
# K8s namespace for ESO
apiVersion: v1
kind: Namespace
metadata:
  name: external-secrets  # ← This is a K8s namespace
  labels:
    pod-security.kubernetes.io/enforce: restricted

---
# Install ESO via Helm or OLM
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: external-secrets-operator
  namespace: external-secrets  # ← K8s namespace
spec:
  channel: stable
  name: external-secrets-operator
  source: community-operators
  sourceNamespace: openshift-marketplace
```

**SecretStore** (defines Vault connection per cluster):

```yaml
---
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://vault.example.com:8200"
      
      # Specify Vault namespace (Vault Enterprise multi-tenancy)
      namespace: "prod"  # ← This is a VAULT namespace, not K8s!
      
      # Path to secrets in Vault
      path: "secret"  # KV v2 mount point
      version: "v2"   # KV version 2
      
      # Authentication: Kubernetes auth method
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "cluster-001-eso"  # Vault role
          
          # ServiceAccount in K8s namespace 'external-secrets'
          serviceAccountRef:
            name: external-secrets
            namespace: external-secrets  # ← This is a K8s namespace
      
      # TLS configuration
      caBundle: <base64-encoded-ca-cert>
      
  # Connection retry configuration
  retrySettings:
    maxRetries: 5
    retryInterval: "10s"
```

**ExternalSecret** (syncs a specific secret to K8s):

```yaml
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: s3-credentials
  namespace: my-application  # ← K8s namespace where secret will be created
spec:
  refreshInterval: 1h  # Check Vault every hour
  
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  
  target:
    name: s3-credentials  # Name of K8s Secret to create
    namespace: my-application  # ← K8s namespace (optional, defaults to ExternalSecret's NS)
    creationPolicy: Owner
    
  # Map Vault secret to K8s secret
  dataFrom:
  - extract:
      # Path in Vault (within Vault namespace 'prod/'):
      # Full path: vault.example.com/prod/secret/data/cluster-001/s3-creds
      key: cluster-001/s3-creds
      
      # Alternative: Use template for complex formats
      # rewrite:
      #   - regexp:
      #       source: "AWS_(.*)"
      #       target: "aws_$1"
```

**Result**: A native K8s Secret is created in K8s namespace `my-application`:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: s3-credentials
  namespace: my-application  # ← K8s namespace
  ownerReferences:
  - apiVersion: external-secrets.io/v1beta1
    kind: ExternalSecret
    name: s3-credentials
type: Opaque
data:
  access_key: <base64-encoded>
  secret_key: <base64-encoded>
```

### Security Features to USE

#### ✅ Vault Namespace Isolation (Vault Enterprise)
- **Purpose**: Separate prod/nonprod secrets at Vault level
- **Implementation**: Use dedicated Vault namespaces per environment
- **Benefit**: Complete isolation, separate audit logs, different policies

```bash
# Operator works in Vault namespace 'prod/'
vault secrets enable -namespace=prod -path=secret kv-v2

# Completely isolated from 'nonprod/'
vault secrets enable -namespace=nonprod -path=secret kv-v2
```

#### ✅ K8s Namespace Segregation per Operator
- **Purpose**: Isolate ESO from application workloads
- **Implementation**: Deploy ESO in dedicated K8s namespace: `external-secrets`
- **Benefit**: RBAC isolation, easier auditing, blast radius containment

```yaml
# ESO has RBAC only to create secrets in other namespaces
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: external-secrets-operator
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: ["external-secrets.io"]
  resources: ["externalsecrets", "secretstores"]
  verbs: ["get", "list", "watch"]
```

#### ✅ Per-Cluster Vault Authentication
- Each OpenShift cluster gets unique Kubernetes auth role in Vault
- Vault validates K8s ServiceAccount tokens against cluster API
- No shared credentials between clusters

#### ✅ Short-Lived Tokens with Automatic Renewal
```yaml
# In Vault role configuration
ttl: 1h          # Token expires after 1 hour
max_ttl: 24h     # Token cannot be renewed beyond 24 hours
```

ESO automatically renews tokens before expiration.

#### ✅ Secret Refresh Intervals Based on Sensitivity
```yaml
# High-sensitivity: Dynamic DB credentials
refreshInterval: 5m   # Check every 5 minutes

# Medium-sensitivity: API keys
refreshInterval: 1h   # Check hourly

# Low-sensitivity: Certificates (before expiry)
refreshInterval: 24h  # Check daily
```

#### ✅ Vault Audit Logging
```hcl
# Enable file-based audit in each Vault namespace
vault audit enable -namespace=prod file file_path=/vault/logs/audit-prod.log

# Do NOT log plaintext secrets
audit "file" {
  path = "/vault/logs/audit.log"
  log_raw = false  # ← Important: HMAC secrets in logs
}
```

Ship logs to SIEM:
- Splunk
- Elasticsearch
- Azure Monitor
- AWS CloudWatch

#### ✅ Transit Engine for Etcd Encryption
Encrypt K8s Secrets at rest in etcd using Vault transit engine:

```hcl
# Enable transit engine in Vault
vault secrets enable -namespace=prod transit

# Create encryption key per cluster
vault write -namespace=prod transit/keys/cluster-001-etcd \
  type=aes256-gcm96
```

OpenShift configuration:
```yaml
apiVersion: config.openshift.io/v1
kind: APIServer
metadata:
  name: cluster
spec:
  encryption:
    type: aescbc  # Or use KMS provider pointing to Vault transit
```

### Security Features to AVOID

#### ❌ Long-Lived Vault Tokens
**Problem**: Tokens that don't expire become permanent credentials  
**Risk**: If stolen, attacker has indefinite access  
**Instead**: Use TTL ≤ 24h, prefer 1-8 hours

#### ❌ Shared Vault Roles Across Clusters
**Problem**: One compromised cluster = all clusters compromised  
**Risk**: Lateral movement, blast radius expansion  
**Instead**: Unique Vault role per cluster with bound namespaces

```hcl
# BAD: One role for all clusters
vault write auth/kubernetes/role/all-clusters \
  bound_service_account_names=external-secrets \
  bound_service_account_namespaces=* \  # ← DANGEROUS
  policies=read-all-secrets              # ← DANGEROUS

# GOOD: Role per cluster with specific binding
vault write auth/kubernetes/role/cluster-001-eso \
  bound_service_account_names=external-secrets \
  bound_service_account_namespaces=external-secrets \  # ← Specific K8s NS
  policies=cluster-001-read-only                       # ← Scoped policy
```

#### ❌ Storing Vault Tokens in Git (Even Encrypted)
**Problem**: Tokens in repos can be discovered via git history  
**Risk**: Credential exposure, audit trail gaps  
**Instead**: Use K8s auth with ServiceAccount tokens

#### ❌ Using K8s Namespace: `default`
**Problem**: Default namespace is overloaded and less secure  
**Risk**: Confusion, accidental exposure, poor RBAC  
**Instead**: Create dedicated K8s namespaces: `external-secrets`, `vault-integration`

#### ❌ Overly Broad Vault Policies
```hcl
# BAD: Wildcard access to all secrets
path "secret/*" {
  capabilities = ["read"]
}

# GOOD: Scoped to cluster-specific path
path "secret/data/cluster-001/*" {
  capabilities = ["read"]
}
```

#### ❌ Unencrypted Transit Between ESO and Vault
**Problem**: Secrets exposed on network  
**Risk**: Man-in-the-middle attacks  
**Instead**: Always use TLS 1.3 with mutual authentication

```yaml
# In SecretStore spec
spec:
  provider:
    vault:
      server: "https://vault.example.com:8200"  # ← HTTPS required
      caBundle: <ca-cert>                        # ← Validate server cert
      # Optional: Client cert for mTLS
      clientCert:
        secretRef:
          name: vault-client-cert
          namespace: external-secrets  # ← K8s namespace
```

### Pros

✅ **Centralized Secret Management**: Single source of truth  
✅ **Audit Trail**: All access logged in Vault  
✅ **Dynamic Secrets**: Generate DB passwords, PKI certs on-demand  
✅ **Native K8s Integration**: ESO creates standard K8s Secrets  
✅ **Automatic Rotation**: Refresh secrets without manual intervention  
✅ **Mature Ecosystem**: ESO supports multiple backends (Vault, AWS, Azure, GCP)  
✅ **Templating Support**: Transform secrets for specific formats  
✅ **Namespace Isolation**: Both Vault namespaces and K8s namespaces provide layers of security

### Cons

⚠️ **Network Dependency**: Vault unavailable = no secret refresh  
⚠️ **Single Failure Domain**: Vault cluster down = all clusters affected  
⚠️ **Complex Initial Setup**: Requires configuring 100+ auth backends  
⚠️ **Token Renewal Logic**: Must monitor ESO health to ensure renewals  
⚠️ **Vault Enterprise Cost**: Vault namespaces require Enterprise license

**Mitigations**:
- Deploy Vault in HA mode (Raft 5-node cluster)
- Use caching in ESO to survive short outages
- Implement disaster recovery with Vault snapshots
- Consider Vault OSS if namespaces not required (use path-based separation)

---

## Option 2: RHACM Policy-Based Distribution + Vault

**STATUS**: ✅ **RECOMMENDED** for hub-and-spoke topologies with RHACM

### Architecture Diagram

```
┌──────────────────────────────┐
│  Vault Cluster               │
│  (vault.example.com)         │
│                              │
│  Vault NS: prod/            │
│    └── secret/hub-secrets/   │
└──────────────┬───────────────┘
               │ TLS 1.3
               │ (Only Hub authenticates)
               │
┌──────────────▼───────────────┐
│  RHACM Hub Cluster           │
│  (hub.example.com)           │
│                              │
│  K8s NS: vault-integration   │ ← K8s namespace on Hub
│    └── Vault Agent           │
│                              │
│  K8s NS: rhacm-policies      │ ← K8s namespace on Hub
│    └── Policy Generator      │
│                              │
│  GitOps: ArgoCD/ACM          │
└──────────┬───────────────────┘
           │ Policy Distribution
           │ (Secrets templated per cluster)
    ┌──────┼───────┬─────────┐
    │      │       │         │
┌───▼──┐ ┌─▼───┐ ┌▼────┐ ┌──▼────┐
│Spoke1│ │Spoke2│ │Spoke3│ │Spoke100│
│      │ │      │ │      │ │       │
│K8s NS│ │K8s NS│ │K8s NS│ │K8s NS │ ← K8s namespaces on spokes
│ app  │ │ app  │ │ app  │ │  app  │
└──────┘ └──────┘ └──────┘ └───────┘
```

### Components

#### Vault Configuration (Hub-Specific)

**Vault Namespace**: `prod/` (or `nonprod/`)

The Hub cluster is the only one with direct Vault access:

```hcl
# Kubernetes auth for Hub cluster only
vault write -namespace=prod auth/kubernetes/config \
  kubernetes_host="https://api.hub.example.com:6443" \
  kubernetes_ca_cert=@hub-ca.crt \
  token_reviewer_jwt=@hub-reviewer.jwt

# Vault role for Hub's vault-agent
vault write -namespace=prod auth/kubernetes/role/hub-vault-agent \
  bound_service_account_names=vault-agent \
  bound_service_account_namespaces=vault-integration \  # ← K8s namespace on Hub
  policies=hub-secret-reader \
  ttl=8h \
  max_ttl=24h
```

**Vault Policy** (Hub can read secrets for all clusters):
```hcl
# Policy: hub-secret-reader
# Runs in Vault namespace: prod/

# Hub reads secrets for distribution to all clusters
path "secret/data/cluster-*" {
  capabilities = ["read", "list"]
}

path "secret/data/shared/*" {
  capabilities = ["read"]
}

# Hub can issue certificates for spokes
path "pki/intermediate/issue/*" {
  capabilities = ["create", "update"]
}
```

**Secret Organization in Vault**:
```
vault/prod/secret/data/
├── cluster-001/
│   ├── s3-credentials
│   └── ldap-bind-password
├── cluster-002/
│   └── s3-credentials
├── shared/
│   └── ca-bundle
└── templates/
    └── ldap-config-template  # Used by Policy Generator
```

#### Hub Cluster Configuration

**Vault Agent on Hub** (runs in K8s namespace: `vault-integration`):

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: vault-integration  # ← K8s namespace on Hub
  labels:
    name: vault-integration

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vault-agent
  namespace: vault-integration  # ← K8s namespace

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vault-agent
  namespace: vault-integration  # ← K8s namespace
spec:
  replicas: 2
  selector:
    matchLabels:
      app: vault-agent
  template:
    metadata:
      labels:
        app: vault-agent
    spec:
      serviceAccountName: vault-agent
      containers:
      - name: vault-agent
        image: hashicorp/vault:1.15
        env:
        - name: VAULT_ADDR
          value: "https://vault.example.com:8200"
        - name: VAULT_NAMESPACE
          value: "prod"  # ← Vault namespace (NOT K8s!)
        
        volumeMounts:
        - name: vault-config
          mountPath: /vault/config
        - name: vault-secrets
          mountPath: /vault/secrets
        
        command:
        - vault
        - agent
        - -config=/vault/config/agent.hcl
      
      volumes:
      - name: vault-config
        configMap:
          name: vault-agent-config
      - name: vault-secrets
        emptyDir:
          medium: Memory  # tmpfs - secrets never hit disk
```

**Vault Agent Config**:
```hcl
# /vault/config/agent.hcl

# Auto-auth using Kubernetes service account
auto_auth {
  method {
    type = "kubernetes"
    
    # Vault namespace where auth is configured
    namespace = "prod"  # ← Vault namespace
    
    config = {
      role = "hub-vault-agent"
    }
  }
  
  sink {
    type = "file"
    config = {
      path = "/vault/secrets/.vault-token"
      mode = 0640
    }
  }
}

# Template secrets for RHACM Policy consumption
template {
  source      = "/vault/config/templates/s3-creds.tpl"
  destination = "/vault/secrets/s3-credentials.yaml"
}

# Cache for performance
cache {
  use_auto_auth_token = true
}

vault {
  address = "https://vault.example.com:8200"
  namespace = "prod"  # ← Vault namespace
}
```

**RHACM Policy Generator** (K8s namespace: `rhacm-policies` on Hub):

```yaml
---
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: distribute-s3-credentials
  namespace: rhacm-policies  # ← K8s namespace on Hub
spec:
  disabled: false
  
  # Policy applies to managed clusters
  remediationAction: enforce
  
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: create-s3-secret
      spec:
        severity: high
        remediationAction: enforce
        
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: Secret
            metadata:
              name: s3-credentials
              namespace: my-application  # ← K8s namespace on spoke clusters
            type: Opaque
            data:
              # Values populated from Vault via Hub
              access_key: '{{hub fromSecret "vault-integration" "s3-creds-cluster-001" "access_key" hub}}'
              secret_key: '{{hub fromSecret "vault-integration" "s3-creds-cluster-001" "secret_key" hub}}'

---
# PlacementRule: Target specific clusters
apiVersion: apps.open-cluster-management.io/v1
kind: PlacementRule
metadata:
  name: placement-cluster-001
  namespace: rhacm-policies  # ← K8s namespace on Hub
spec:
  clusterSelector:
    matchLabels:
      name: cluster-001

---
# PolicyBinding: Link policy to placement
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  name: binding-s3-credentials
  namespace: rhacm-policies  # ← K8s namespace on Hub
placementRef:
  name: placement-cluster-001
  kind: PlacementRule
  apiGroup: apps.open-cluster-management.io
subjects:
- name: distribute-s3-credentials
  kind: Policy
  apiGroup: policy.open-cluster-management.io
```

#### Spoke Cluster Result

On each spoke cluster, the Policy creates a Secret in the target K8s namespace:

```yaml
# On cluster-001, in K8s namespace: my-application
apiVersion: v1
kind: Secret
metadata:
  name: s3-credentials
  namespace: my-application  # ← K8s namespace on spoke
  labels:
    policy.open-cluster-management.io/policy: distribute-s3-credentials
type: Opaque
data:
  access_key: <base64>
  secret_key: <base64>
```

### Security Features to USE

#### ✅ Hub-Only Vault Access
- **Benefit**: Reduces attack surface—only 1 cluster authenticates to Vault
- **Implementation**: Vault firewall rules allow only Hub cluster IPs
- **Spoke isolation**: Spokes never have direct Vault credentials

#### ✅ Policy Compliance Monitoring
RHACM continuously checks if secrets exist and match expected state:

```bash
# View policy compliance across all clusters
oc get policies -n rhacm-policies

NAME                         REMEDIATION   COMPLIANCE
distribute-s3-credentials    enforce       Compliant
distribute-ldap-bind         enforce       NonCompliant  ← Investigate!
```

Alerts on:
- Secret deletion (drift)
- Secret modification (tampering)
- Policy violations

#### ✅ Per-Cluster Secret Templating
Use Hub templates to customize secrets per cluster:

```yaml
object-templates:
- complianceType: musthave
  objectDefinition:
    apiVersion: v1
    kind: Secret
    metadata:
      name: ldap-bind
      namespace: authentication  # ← K8s namespace on spoke
    stringData:
      # Different bind DN per cluster
      bind_dn: '{{hub index (lookup "v1" "ConfigMap" "vault-integration" "cluster-metadata").data (printf "%s-bind-dn" .ManagedClusterName) hub}}'
      bind_password: '{{hub fromSecret "vault-integration" (printf "ldap-%s" .ManagedClusterName) "password" hub}}'
```

#### ✅ Placement Rules for Targeted Distribution
Fine-grained control over which clusters receive which secrets:

```yaml
# Production clusters only
apiVersion: apps.open-cluster-management.io/v1
kind: PlacementRule
metadata:
  name: production-clusters
spec:
  clusterSelector:
    matchExpressions:
    - key: environment
      operator: In
      values:
      - production
    - key: region
      operator: In
      values:
      - us-east-1

---
# Non-production clusters
apiVersion: apps.open-cluster-management.io/v1
kind: PlacementRule
metadata:
  name: nonprod-clusters
spec:
  clusterSelector:
    matchLabels:
      environment: nonprod
```

#### ✅ Git as Source of Truth (with Vault as Secret Backend)
Policy manifests live in Git (without secret values):

```
git-repo/
├── policies/
│   ├── base/
│   │   ├── policy-s3-credentials.yaml      # References Vault secrets
│   │   └── policy-ldap-bind.yaml
│   └── overlays/
│       ├── prod/
│       │   └── kustomization.yaml          # Prod-specific labels
│       └── nonprod/
│           └── kustomization.yaml
```

Secrets themselves never in Git—only references to Vault paths.

### Security Features to AVOID

#### ❌ Storing Decrypted Secrets in Hub Git Repo
**Problem**: Even private repos are not secret stores  
**Instead**: Store only policy templates; Vault Agent renders at runtime

#### ❌ Overly Broad Placement Rules
```yaml
# BAD: All clusters get all secrets
clusterSelector:
  matchLabels: {}

# GOOD: Specific cluster groups
clusterSelector:
  matchLabels:
    secret-tier: high-security
```

#### ❌ Policy with `remediationAction: inform`
**Problem**: Secrets won't be created/updated automatically  
**Instead**: Use `enforce` for secret distribution

```yaml
spec:
  remediationAction: enforce  # ← Auto-remediate
```

#### ❌ Ignoring Compliance Violations
**Problem**: Drifted secrets may contain stale/compromised credentials  
**Instead**: Set up alerts on NonCompliant policies

### Pros

✅ **Reduced Network Exposure**: Only Hub talks to Vault  
✅ **Built-in Compliance Checking**: Real-time drift detection  
✅ **Git-Driven Workflows**: Policy-as-Code with GitOps  
✅ **Centralized Control**: Hub manages 100+ clusters from one place  
✅ **Namespace Isolation**: Vault namespaces separate environments; K8s namespaces isolate workloads  
✅ **Leverage Existing RHACM Investment**: No additional operators needed on spokes

### Cons

⚠️ **Hub is Single Point of Failure**: Hub down = no policy updates  
⚠️ **Slower Secret Propagation**: Policy sync interval (default: 10 minutes)  
⚠️ **Less Dynamic**: Hard to implement short-lived credentials  
⚠️ **Hub Credential Management**: Hub token must be carefully secured  
⚠️ **Policy Complexity**: Templates can become complex with many variables

**Mitigations**:
- Deploy Hub in HA mode with etcd backups
- Use GitOps for disaster recovery
- Implement Hub monitoring and alerting
- Consider hybrid approach (RHACM + ESO on spokes)

---

## Option 3: Vault Agent Sidecar Injection

**STATUS**: ⚠️ **ADVANCED** - Use for specific workloads requiring in-memory secrets

### Architecture Diagram

```
┌────────────────────────────────────────────┐
│  Vault Cluster                             │
│  Vault NS: prod/                           │ ← Vault namespace
│    └── secret/app-secrets/                 │
└──────────────┬─────────────────────────────┘
               │ TLS + K8s Auth
        ┌──────┼─────────────┐
        │      │             │
   ┌────▼───┐ │        ┌────▼───┐
   │Cluster1│ │        │Cluster2│
   │        │ │        │        │
   │ K8s NS:│ │        │ K8s NS:│ ← K8s namespaces
   │ prod-  │ │        │ prod-  │
   │ apps   │ │        │ apps   │
   │        │ │        │        │
   │ ┌──────▼─────────┐│        │
   │ │ Pod            ││        │
   │ │ ┌────────────┐ ││        │
   │ │ │   App      │ ││        │
   │ │ │ Container  │ ││        │
   │ │ │            │ ││        │
   │ │ │ Reads:     │ ││        │
   │ │ │ /vault/    │ ││        │
   │ │ │  secrets/  │◄┼┼────┐   │
   │ │ └────────────┘ ││    │   │
   │ │                ││    │   │
   │ │ ┌────────────┐ ││    │   │
   │ │ │   Vault    │ ││    │   │
   │ │ │   Agent    │ ├┼────┘   │
   │ │ │  Sidecar   │ ││        │
   │ │ │            │ ││        │
   │ │ │ Writes:    │ ││        │
   │ │ │ /vault/    │ ││        │
   │ │ │  secrets/  │ ││        │
   │ │ └────────────┘ ││        │
   │ │                ││        │
   │ │ Shared Volume: ││        │
   │ │   tmpfs (RAM)  ││        │
   │ └────────────────┘│        │
   └───────────────────┘        │
                                │
   (Secrets never written       │
    to disk or K8s etcd)        │
```

### Components

#### Vault Configuration

Similar to Option 1, but auth is per-namespace, per-service-account:

```hcl
# In Vault namespace: prod/

# K8s auth for cluster-001
vault write auth/kubernetes/config \
  kubernetes_host="https://api.cluster-001.example.com:6443" \
  kubernetes_ca_cert=@ca.crt \
  token_reviewer_jwt=@reviewer.jwt

# Role for specific app in K8s namespace: prod-apps
vault write auth/kubernetes/role/my-app-prod \
  bound_service_account_names=my-app \       # ← K8s ServiceAccount
  bound_service_account_namespaces=prod-apps \  # ← K8s namespace
  policies=my-app-read-policy \
  ttl=1h \
  max_ttl=8h

# Vault policy scoped to this app
vault policy write my-app-read-policy - <<EOF
path "secret/data/prod-apps/my-app/*" {
  capabilities = ["read"]
}
EOF
```

#### OpenShift Pod Configuration

**Pod with Vault Agent Sidecar** (in K8s namespace: `prod-apps`):

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  namespace: prod-apps  # ← K8s namespace

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: prod-apps  # ← K8s namespace
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
      annotations:
        # Vault annotations for agent injector (optional if using webhook)
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/agent-inject-secret-database: "secret/data/prod-apps/my-app/db-creds"
        vault.hashicorp.com/role: "my-app-prod"
        vault.hashicorp.com/namespace: "prod"  # ← Vault namespace
    spec:
      serviceAccountName: my-app
      
      # Manual sidecar configuration (if not using webhook)
      containers:
      
      # Application container
      - name: app
        image: my-app:v1.0.0
        env:
        - name: DB_PASSWORD_FILE
          value: "/vault/secrets/database"
        volumeMounts:
        - name: vault-secrets
          mountPath: /vault/secrets
          readOnly: true
      
      # Vault Agent sidecar
      - name: vault-agent
        image: hashicorp/vault:1.15
        env:
        - name: VAULT_ADDR
          value: "https://vault.example.com:8200"
        - name: VAULT_NAMESPACE
          value: "prod"  # ← Vault namespace
        
        args:
        - agent
        - -config=/vault/config/agent.hcl
        
        volumeMounts:
        - name: vault-config
          mountPath: /vault/config
        - name: vault-secrets
          mountPath: /vault/secrets
        
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
      
      volumes:
      
      # Agent configuration
      - name: vault-config
        configMap:
          name: vault-agent-config
      
      # Shared volume for secrets (in-memory only)
      - name: vault-secrets
        emptyDir:
          medium: Memory  # ← tmpfs: secrets stored in RAM only!
```

**Vault Agent Config** (ConfigMap in K8s namespace: `prod-apps`):

```hcl
# vault-agent-config ConfigMap

auto_auth {
  method {
    type = "kubernetes"
    namespace = "prod"  # ← Vault namespace
    
    config = {
      role = "my-app-prod"  # Vault role
    }
  }
  
  sink {
    type = "file"
    config = {
      path = "/vault/secrets/.vault-token"
      mode = 0640
    }
  }
}

# Template: Render DB password
template {
  source      = "/vault/config/templates/database.tpl"
  destination = "/vault/secrets/database"
  perms       = "0640"
}

# Template: Render S3 credentials
template {
  source      = "/vault/config/templates/s3.tpl"
  destination = "/vault/secrets/s3-credentials.json"
  perms       = "0640"
}

# Cache with encryption
cache {
  use_auto_auth_token = true
  
  # Encrypt cached secrets
  encryption {
    type = "aes256-gcm96"
  }
}

vault {
  address = "https://vault.example.com:8200"
  namespace = "prod"  # ← Vault namespace
  
  # TLS configuration
  ca_cert = "/vault/tls/ca.crt"
}

# Auto-renewal
auto_auth {
  method {
    type = "kubernetes"
    namespace = "prod"  # ← Vault namespace
  }
}
```

**Template Example** (`/vault/config/templates/database.tpl`):

```
{{- with secret "secret/data/prod-apps/my-app/db-creds" -}}
export DB_USERNAME="{{ .Data.data.username }}"
export DB_PASSWORD="{{ .Data.data.password }}"
export DB_HOST="{{ .Data.data.host }}"
{{- end -}}
```

Application reads from `/vault/secrets/database`:
```bash
#!/bin/bash
# In application container
source /vault/secrets/database
psql -h $DB_HOST -U $DB_USERNAME
# Password read from $DB_PASSWORD
```

### Security Features to USE

#### ✅ Secrets in Memory Only (tmpfs)
```yaml
volumes:
- name: vault-secrets
  emptyDir:
    medium: Memory  # ← RAM-backed filesystem
    sizeLimit: "128Mi"
```

Benefits:
- Secrets never touch persistent disk
- Cleared on pod restart
- No risk of disk forensics

#### ✅ Per-Pod Service Account Binding
```hcl
# Vault role bound to specific K8s ServiceAccount + namespace
vault write auth/kubernetes/role/my-app-prod \
  bound_service_account_names=my-app \          # ← Only this SA
  bound_service_account_namespaces=prod-apps \  # ← Only this K8s namespace
  bound_service_accounts_namespaces=prod-apps
```

#### ✅ Automatic Token Renewal
Vault Agent handles token lifecycle—application never sees tokens:
```hcl
auto_auth {
  method {
    type = "kubernetes"
  }
  
  sink {
    type = "file"
    config = {
      path = "/vault/secrets/.vault-token"
      mode = 0600  # ← Agent-only access
    }
  }
}
```

#### ✅ Template-Based Secret Rendering
Transform Vault secrets into application-specific formats:

```
{{- with secret "secret/data/prod-apps/my-app/s3" -}}
{
  "accessKeyID": "{{ .Data.data.access_key }}",
  "secretAccessKey": "{{ .Data.data.secret_key }}",
  "region": "{{ .Data.data.region }}"
}
{{- end -}}
```

#### ✅ Cache Encryption
If using Vault Agent cache:
```hcl
cache {
  encryption {
    type = "aes256-gcm96"
  }
}
```

Protects cached secrets if agent memory is dumped.

### Security Features to AVOID

#### ❌ Persistent Volumes for Secrets
```yaml
# BAD
volumes:
- name: vault-secrets
  persistentVolumeClaim:
    claimName: secrets-pvc  # ← Secrets on disk!

# GOOD
volumes:
- name: vault-secrets
  emptyDir:
    medium: Memory  # ← RAM only
```

#### ❌ Environment Variables for Sensitive Data
```yaml
# RISKY: Env vars visible in ps, /proc, logs
env:
- name: DB_PASSWORD
  value: "{{ vault_secret }}"

# BETTER: Read from file
env:
- name: DB_PASSWORD_FILE
  value: "/vault/secrets/db-password"
```

Application:
```python
# Read from file
with open(os.getenv('DB_PASSWORD_FILE')) as f:
    db_password = f.read().strip()
```

#### ❌ Overly Permissive ServiceAccount Bindings
```hcl
# BAD: Any SA in any namespace
bound_service_account_names=* \
bound_service_account_namespaces=*

# GOOD: Specific SA + specific K8s namespace
bound_service_account_names=my-app \
bound_service_account_namespaces=prod-apps
```

#### ❌ Sharing Vault Agent Sidecar Across Pods
Each pod should have its own agent—don't use a centralized agent pod:
- Prevents secret leakage between pods
- Isolates credential lifecycles
- Aligns with least-privilege model

#### ❌ Unencrypted Cache
If cache is enabled, always encrypt:
```hcl
cache {
  use_auto_auth_token = true
  
  # Don't omit this:
  encryption {
    type = "aes256-gcm96"
  }
}
```

### Pros

✅ **Secrets Never in K8s Secrets**: Bypasses etcd storage  
✅ **Per-Pod Isolation**: Each pod authenticates independently  
✅ **Automatic Rotation**: Agent handles renewals without app changes  
✅ **Template Flexibility**: Render secrets in any format  
✅ **No Additional Operators**: Native Vault feature  
✅ **Strong Namespace Isolation**: Both Vault namespaces (tenancy) and K8s namespaces (RBAC)

### Cons

⚠️ **Resource Overhead**: Each pod gets a sidecar (CPU, memory)  
⚠️ **Complex Pod Specs**: More yaml configuration  
⚠️ **Not Suitable for All Workloads**: Operators/controllers that expect K8s Secrets won't work  
⚠️ **Vault Dependency Per Pod**: Every pod needs network access to Vault  
⚠️ **Doesn't Help with Cluster-Level Secrets**: Etcd encryption keys, cluster certs still need different solution

**Mitigations**:
- Use for high-security workloads only
- Combine with Option 1 (ESO) for cluster-level secrets
- Right-size sidecar resources
- Use Vault Agent injector webhook to simplify pod specs

---

## Hybrid Recommendation: Tiered Approach for 100+ Clusters

### Overview

For large-scale deployments (100+ clusters), **don't pick just one pattern**. Use a tiered approach that matches security patterns to secret types and sensitivity levels. This provides the best balance of security, operational efficiency, and flexibility.

### The Problem with Single-Pattern Approaches

**Only ESO Everywhere:**
- ❌ All secrets flow through Vault API (high load)
- ❌ Critical infrastructure secrets in K8s etcd (compliance risk)
- ❌ No differentiation between sensitivity levels

**Only RHACM Distribution:**
- ❌ Hub becomes single point of failure
- ❌ Slow propagation (policy sync intervals)
- ❌ Poor support for dynamic secrets (DB credentials)

**Only Vault Agent Sidecars:**
- ❌ Resource overhead at massive scale (100s of sidecars × 100s of clusters)
- ❌ Doesn't help with cluster-level secrets
- ❌ Complex for teams to manage

### Hybrid Architecture: Three-Tier Model

```
┌─────────────────────────────────────────────────────────────┐
│                    Vault Cluster (HA)                       │
│                    Vault NS: prod/                          │
└────┬──────────────────┬──────────────────┬──────────────────┘
     │                  │                  │
     │ Tier 1           │ Tier 2           │ Tier 3
     │ (RHACM)          │ (ESO)            │ (Vault Agent)
     │                  │                  │
┌────▼────────────┐ ┌───▼─────────────┐ ┌─▼─────────────────┐
│ RHACM Hub       │ │ All Clusters    │ │ Specific Workloads│
│ Distributes:    │ │ ESO syncs:      │ │ Agent injects:    │
│                 │ │                 │ │                   │
│ • LDAP bind     │ │ • S3 keys       │ │ • DB passwords    │
│ • Root CAs      │ │ • PKI certs     │ │ • API tokens      │
│ • Registry pull │ │ • App configs   │ │ • Payment creds   │
│ • Etcd keys     │ │ • Monitoring    │ │ • PII encryption  │
└─────────────────┘ └─────────────────┘ └───────────────────┘
  Quarterly           Hourly/Daily        Per-pod/Minutes
  rotation            rotation            rotation
```

---

## Tier 1: Infrastructure Secrets (RHACM Policy Distribution)

### What Goes Here

**Critical infrastructure secrets that:**
- Change infrequently (quarterly rotation)
- Must be consistent across all clusters
- Have high operational impact if unavailable
- Require manual validation before distribution
- Need centralized audit and compliance tracking

### Examples

| Secret Type | Why RHACM | Rotation Frequency |
|-------------|-----------|-------------------|
| **LDAP bind credentials** | Shared by all clusters, infrequent changes | Quarterly |
| **Root CA bundles** | Organization trust anchors, stable | Annually |
| **Registry pull secrets** | Red Hat subscriptions, shared | When keys rotate |
| **Etcd encryption keys** | Critical cluster security | Bootstrap only |
| **Control plane certificates** | Cluster infrastructure | 90-day renewal |
| **Observability tokens** | Splunk HEC, Prometheus remote-write | Quarterly |

### Architecture

```yaml
# On RHACM Hub - K8s namespace: rhacm-policies
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: distribute-infrastructure-secrets
  namespace: rhacm-policies
spec:
  disabled: false
  remediationAction: enforce
  
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: create-ldap-credentials
      spec:
        severity: critical
        remediationAction: enforce
        
        object-templates:
        # LDAP bind credentials (shared across all clusters)
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: Secret
            metadata:
              name: ldap-bind-credentials
              namespace: authentication
            type: Opaque
            stringData:
              bind_dn: '{{hub fromSecret "vault-integration" "shared-ldap" "bind_dn" hub}}'
              bind_password: '{{hub fromSecret "vault-integration" "shared-ldap" "bind_password" hub}}'
        
        # Root CA bundle
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: ConfigMap
            metadata:
              name: root-ca-bundle
              namespace: openshift-config
            data:
              ca-bundle.crt: '{{hub fromConfigMap "vault-integration" "root-ca" "ca-bundle.crt" hub}}'
        
        # Cluster-specific etcd encryption key
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: Secret
            metadata:
              name: etcd-encryption-key
              namespace: openshift-config
            type: Opaque
            stringData:
              key: '{{hub fromSecret "vault-integration" (printf "etcd-key-%s" .ManagedClusterName) "key" hub}}'

---
# PlacementRule: All production clusters
apiVersion: apps.open-cluster-management.io/v1
kind: PlacementRule
metadata:
  name: all-production-clusters
  namespace: rhacm-policies
spec:
  clusterSelector:
    matchLabels:
      environment: production

---
# PolicyBinding
apiVersion: policy.open-cluster-management.io/v1
kind: PlacementBinding
metadata:
  name: bind-infrastructure-secrets
  namespace: rhacm-policies
placementRef:
  name: all-production-clusters
  kind: PlacementRule
subjects:
- name: distribute-infrastructure-secrets
  kind: Policy
```

### Vault Organization (Tier 1)

```bash
# In Vault namespace: prod/
vault/prod/secret/data/
├── infrastructure/                    # Tier 1 secrets
│   ├── ldap/
│   │   └── bind-credentials          # Quarterly rotation
│   ├── certificates/
│   │   ├── root-ca-bundle            # Annual update
│   │   └── intermediate-ca
│   ├── registries/
│   │   └── redhat-pull-secret        # When subscription renews
│   └── observability/
│       ├── splunk-hec-token
│       └── prometheus-token
│
├── cluster-infrastructure/            # Per-cluster critical secrets
│   ├── cluster-001/
│   │   ├── etcd-encryption-key       # Bootstrap, never rotate
│   │   └── control-plane-certs
│   ├── cluster-002/
│   │   └── ...
│   └── cluster-100/
│       └── ...
```

### Why RHACM for Tier 1

✅ **Centralized control**: Operations team reviews all changes  
✅ **Compliance visibility**: Policy compliance dashboard  
✅ **Reduced Vault load**: Hub fetches once, distributes 100+ times  
✅ **Controlled rollout**: Can target specific clusters for testing  
✅ **Network resilience**: Spokes don't need Vault network access  
✅ **Audit integration**: RHACM compliance events

### Rotation Process (Tier 1)

```bash
# 1. Update secret in Vault
vault kv put secret/infrastructure/ldap/bind-credentials \
  bind_dn="cn=ldap-bind,ou=service,dc=example,dc=com" \
  bind_password="<new-password>"

# 2. Update Hub's cached copy (Vault Agent on Hub syncs automatically)
# Hub Vault Agent config refreshes infrastructure secrets every 1 hour

# 3. RHACM Policy propagates to spokes
# Default sync: 10 minutes (configurable)

# 4. Monitor policy compliance
oc get policies -n rhacm-policies
# All clusters should show "Compliant" within 10 minutes

# 5. Verify on sample spoke clusters
for cluster in cluster-001 cluster-050 cluster-100; do
  oc --context=$cluster get secret ldap-bind-credentials -n authentication \
    -o jsonpath='{.metadata.creationTimestamp}'
done
```

---

## Tier 2: Application Secrets (External Secrets Operator)

### What Goes Here

**Application and service secrets that:**
- Change regularly (hourly to daily)
- Are cluster-specific or application-specific
- Need automatic rotation without manual intervention
- Support dynamic generation (PKI certificates)
- Scale to hundreds of unique secrets per cluster

### Examples

| Secret Type | Why ESO | Rotation Frequency |
|-------------|---------|-------------------|
| **S3 bucket credentials** | Unique per cluster | Daily (IAM temporary creds) |
| **PKI certificates** | Auto-renewed from Vault PKI engine | 90 days |
| **Application database passwords** | Dynamic, per-app | 24 hours |
| **API tokens** | Per-service credentials | Weekly |
| **Object storage keys** | Per-application buckets | On-demand |
| **Service mesh certificates** | mTLS between services | 24-48 hours |
| **GitHub webhook secrets** | Per-cluster webhooks | On-demand |
| **Monitoring credentials** | Cluster-specific exporters | Monthly |

### Architecture

```yaml
---
# ClusterSecretStore (deployed to all 100+ clusters)
# K8s namespace: external-secrets
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://vault.example.com:8200"
      namespace: "prod"  # Vault namespace
      path: "secret"
      version: "v2"
      
      auth:
        kubernetes:
          mountPath: "kubernetes-cluster-001"
          role: "eso"
          serviceAccountRef:
            name: external-secrets
            namespace: external-secrets  # K8s namespace

---
# ExternalSecret: S3 credentials (cluster-specific)
# Deployed to K8s namespace: backup
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: s3-backup-credentials
  namespace: backup
spec:
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  
  refreshInterval: 1h  # Check Vault every hour
  
  target:
    name: s3-backup-credentials
    creationPolicy: Owner
  
  data:
  - secretKey: access_key
    remoteRef:
      key: cluster-001/s3-credentials
      property: access_key
  
  - secretKey: secret_key
    remoteRef:
      key: cluster-001/s3-credentials
      property: secret_key
  
  - secretKey: bucket
    remoteRef:
      key: cluster-001/s3-credentials
      property: bucket

---
# ExternalSecret: PKI certificate (auto-generated from Vault)
# Deployed to K8s namespace: istio-system
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: service-mesh-cert
  namespace: istio-system
spec:
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  
  refreshInterval: 12h  # Renew before expiry
  
  target:
    name: istio-gateway-cert
    template:
      type: kubernetes.io/tls
      data:
        tls.crt: "{{ .certificate }}"
        tls.key: "{{ .private_key }}"
        ca.crt: "{{ .issuing_ca }}"
  
  dataFrom:
  - extract:
      # Vault PKI engine generates cert on-demand
      key: pki/issue/service-mesh-role
      property: common_name
      value: "gateway.cluster-001.example.com"
```

### Vault Organization (Tier 2)

```bash
# In Vault namespace: prod/
vault/prod/
├── secret/data/                       # KV v2 engine
│   ├── cluster-001/                   # Cluster-specific app secrets
│   │   ├── s3-credentials            # Hourly/Daily rotation
│   │   ├── app-db-passwords
│   │   ├── api-tokens
│   │   └── github-webhooks
│   ├── cluster-002/
│   │   └── ...
│   └── shared/                        # Shared app secrets
│       ├── external-apis/
│       └── third-party-services/
│
└── pki/                               # PKI engine (Tier 2)
    ├── intermediate/
    │   └── issue/
    │       ├── service-mesh-role      # Auto-issue certs
    │       ├── ingress-role
    │       └── internal-ca-role
```

### Why ESO for Tier 2

✅ **Automatic rotation**: Refresh every 1h without manual intervention  
✅ **Dynamic secrets**: Vault PKI generates certs on-demand  
✅ **Scalability**: Each cluster independently syncs secrets  
✅ **Template support**: Transform secrets into K8s-native formats  
✅ **Native K8s integration**: Creates standard K8s Secrets  
✅ **Namespace scoping**: Different ExternalSecrets per K8s namespace

### Rotation Process (Tier 2)

**Static Secrets:**
```bash
# 1. Update secret in Vault (creates new version in KV v2)
vault kv put secret/cluster-001/s3-credentials \
  access_key="AKIA..." \
  secret_key="..." \
  bucket="cluster-001-backups"

# 2. ESO automatically syncs within refreshInterval (1h)
# No manual action required on clusters

# 3. Monitor sync status
kubectl get externalsecrets -A
# STATUS should show "SecretSynced"
```

**Dynamic Secrets (PKI):**
```bash
# Vault PKI engine auto-rotates
# ESO requests new cert at refreshInterval (12h)
# New cert issued if current expires within threshold
# Zero manual intervention required
```

---

## Tier 3: High-Security Workload Secrets (Vault Agent Sidecar)

### What Goes Here

**Extremely sensitive secrets that:**
- Must never exist as K8s Secrets in etcd
- Require per-pod isolation
- Change frequently (per-pod lifecycle)
- Involve payment processing, PII, or regulated data
- Need in-memory-only storage

### Examples

| Secret Type | Why Vault Agent | Rotation Frequency |
|-------------|----------------|-------------------|
| **Payment processor credentials** | PCI-DSS compliance | Per-transaction |
| **Database passwords (write)** | Dynamic, per-pod | Pod lifetime |
| **Encryption keys for PII** | Never persisted | Per-pod |
| **API keys for financial services** | Compliance requirement | Per-session |
| **HIPAA-regulated credentials** | Audit requirements | Per-access |
| **Zero-trust service mesh** | mTLS per-pod identity | Pod lifetime |

### Architecture

```yaml
---
# Deployment with Vault Agent sidecar
# K8s namespace: payments
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-processor
  namespace: payments
spec:
  replicas: 3
  selector:
    matchLabels:
      app: payment-processor
  template:
    metadata:
      labels:
        app: payment-processor
      annotations:
        # Vault Agent Injector annotations (if using webhook)
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/agent-inject-secret-payment-creds: "secret/data/payments/processor"
        vault.hashicorp.com/role: "payment-processor"
        vault.hashicorp.com/namespace: "prod"
    spec:
      serviceAccountName: payment-processor
      
      containers:
      # Application container
      - name: payment-app
        image: payment-processor:v1.0.0
        env:
        - name: PAYMENT_CREDS_PATH
          value: "/vault/secrets/payment-creds"
        
        volumeMounts:
        - name: vault-secrets
          mountPath: /vault/secrets
          readOnly: true
        
        # Application reads from /vault/secrets/payment-creds
        # Credentials rendered by Vault Agent
      
      # Vault Agent sidecar (auto-injected or manual)
      - name: vault-agent
        image: hashicorp/vault:1.15
        env:
        - name: VAULT_ADDR
          value: "https://vault.example.com:8200"
        - name: VAULT_NAMESPACE
          value: "prod"  # Vault namespace
        
        args:
        - agent
        - -config=/vault/config/agent.hcl
        
        volumeMounts:
        - name: vault-config
          mountPath: /vault/config
        - name: vault-secrets
          mountPath: /vault/secrets
        
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
      
      volumes:
      - name: vault-config
        configMap:
          name: vault-agent-config
      
      # tmpfs: secrets stored in RAM only, never on disk
      - name: vault-secrets
        emptyDir:
          medium: Memory
          sizeLimit: "10Mi"
```

### Vault Organization (Tier 3)

```bash
# In Vault namespace: prod/
vault/prod/
├── secret/data/
│   └── high-security/                 # Tier 3 secrets
│       ├── payments/
│       │   ├── stripe-api-key
│       │   └── processor-credentials
│       ├── pii-encryption/
│       │   └── master-key
│       └── financial-apis/
│           └── trading-credentials
│
├── database/                          # Dynamic DB credentials
│   ├── roles/
│   │   ├── payment-db-write          # Generate per-pod
│   │   └── user-db-write
│
└── pki/                               # Pod-specific certificates
    └── roles/
        └── service-identity           # mTLS per-pod
```

### Why Vault Agent for Tier 3

✅ **Never in etcd**: Secrets bypass K8s Secret storage entirely  
✅ **In-memory only**: tmpfs volumes, cleared on pod restart  
✅ **Per-pod isolation**: Each pod gets unique credentials  
✅ **Dynamic generation**: Database passwords generated per-pod  
✅ **Compliance**: Meets PCI-DSS, HIPAA requirements  
✅ **Zero-trust**: True per-workload identity

### Use Cases (Tier 3)

**Limit to specific namespaces:**
```bash
# K8s namespaces using Vault Agent:
- payments          # PCI-DSS workloads
- healthcare        # HIPAA workloads
- financial-trading # SEC compliance
- pii-processing    # GDPR compliance

# All other namespaces use Tier 2 (ESO)
```

---

## Implementation Strategy: Phased Rollout

### Phase 1: Foundation (Weeks 1-2)

**Goal**: Establish Vault and basic connectivity

```bash
# 1. Deploy Vault cluster (HA)
# - 5-node Raft storage
# - TLS with proper CA
# - Audit logging enabled

# 2. Configure Vault namespaces
vault namespace create prod
vault namespace create nonprod

# 3. Enable secrets engines
vault secrets enable -namespace=prod -path=secret kv-v2
vault secrets enable -namespace=prod pki

# 4. Test from 1-2 pilot clusters
# - Verify network connectivity
# - Test Kubernetes auth
# - Validate policies
```

### Phase 2: Tier 1 - Infrastructure Secrets (Weeks 3-4)

**Goal**: RHACM distribution of critical secrets

```bash
# 1. Deploy RHACM Hub (if not already present)
# 2. Configure Vault Agent on Hub
# 3. Create policies for infrastructure secrets
# 4. Test on 10 clusters (canary)
# 5. Rollout to all 100+ clusters
# 6. Validate compliance dashboard

# Secrets to migrate first:
- LDAP bind credentials (highest impact, lowest risk)
- Root CA bundles (stable, rarely changes)
- Registry pull secrets (easy to validate)
```

### Phase 3: Tier 2 - Application Secrets (Weeks 5-8)

**Goal**: ESO deployment to all clusters

```bash
# 1. Deploy ESO to all clusters via GitOps
# 2. Configure ClusterSecretStore per cluster
# 3. Migrate secrets namespace-by-namespace:
#    Week 5: backup namespace (S3 credentials)
#    Week 6: monitoring namespace (Prometheus creds)
#    Week 7: istio-system namespace (service mesh certs)
#    Week 8: application namespaces (app-specific secrets)

# 4. Monitor sync metrics
# 5. Establish alerting for sync failures
```

### Phase 4: Tier 3 - High-Security Workloads (Weeks 9-12)

**Goal**: Vault Agent for compliance workloads

```bash
# 1. Identify PCI/HIPAA/regulated workloads
# 2. Install Vault Agent Injector webhook
# 3. Migrate payments namespace (Week 9-10)
# 4. Migrate healthcare namespace (Week 11)
# 5. Migrate financial-trading namespace (Week 12)

# Criteria for Tier 3 migration:
- Compliance requirement (PCI-DSS, HIPAA, SOC 2)
- Secrets must not exist in etcd
- Dynamic credentials beneficial
- Team has capacity for complex pod specs
```

### Phase 5: Optimization & Automation (Weeks 13+)

```bash
# 1. Implement automated rotation workflows
# 2. Tune refresh intervals based on metrics
# 3. Optimize Vault policies (least privilege)
# 4. Establish runbooks for common operations
# 5. Train teams on new secret workflows
# 6. Continuous monitoring and improvement
```

---

## Decision Matrix: Which Pattern for Which Secret?

### Quick Decision Tree

```
Is the secret regulated (PCI-DSS, HIPAA)?
├─ YES → Tier 3 (Vault Agent)
└─ NO
   │
   Does it change rarely (quarterly+) AND affect all clusters?
   ├─ YES → Tier 1 (RHACM)
   └─ NO
      │
      Is it cluster-specific OR needs frequent rotation?
      ├─ YES → Tier 2 (ESO)
      └─ NO → Re-evaluate, may fit Tier 1
```

### Detailed Criteria Matrix

| Criteria | Tier 1 (RHACM) | Tier 2 (ESO) | Tier 3 (Vault Agent) |
|----------|----------------|--------------|----------------------|
| **Rotation Frequency** | Quarterly or less | Hourly to daily | Per-pod or minutes |
| **Scope** | All clusters | Per-cluster | Per-pod |
| **Sensitivity** | High (infrastructure) | Medium (application) | Critical (regulated) |
| **Change Impact** | High (manual review) | Low (automatic) | Medium (per-workload) |
| **Compliance** | Audit required | Standard | PCI/HIPAA/SOC2 |
| **Network Dependency** | Low (hub-only) | Medium (per-cluster) | High (per-pod) |
| **Storage Location** | K8s Secret (etcd) | K8s Secret (etcd) | Memory only (tmpfs) |
| **Dynamic Generation** | No | Yes (PKI, DB) | Yes (all types) |
| **Operational Overhead** | Low | Low | High |
| **Implementation Complexity** | Medium | Low | High |
| **Best for** | Stable, shared | App secrets | Compliance workloads |

---

## Monitoring the Hybrid Architecture

### Metrics to Track

**Tier 1 (RHACM):**
```promql
# Policy compliance rate
(count(acm_policy_status{status="Compliant"}) / count(acm_policy_status)) * 100

# Policy propagation time
histogram_quantile(0.95, acm_policy_propagation_seconds)

# Non-compliant clusters alert
count(acm_policy_status{status="NonCompliant"}) > 0
```

**Tier 2 (ESO):**
```promql
# Secret sync success rate
rate(externalsecrets_sync_calls_total{status="success"}[5m])

# Sync failures by cluster
sum by (cluster) (externalsecrets_sync_calls_error)

# Secret age (detect stale secrets)
(time() - externalsecrets_secret_last_sync_time) > 7200  # > 2 hours
```

**Tier 3 (Vault Agent):**
```promql
# Agent authentication failures
increase(vault_agent_auth_failure[5m]) > 0

# Token renewals
rate(vault_agent_token_renewal_success[5m])

# Memory usage (sidecar overhead)
avg(container_memory_usage_bytes{container="vault-agent"})
```

### Unified Dashboard

Create a single dashboard showing all three tiers:

```yaml
# Grafana dashboard definition
{
  "title": "Vault Hybrid Secret Management",
  "panels": [
    {
      "title": "Tier 1: Infrastructure Secrets (RHACM)",
      "metrics": ["Policy Compliance", "Hub Health", "Propagation Time"]
    },
    {
      "title": "Tier 2: Application Secrets (ESO)",
      "metrics": ["Sync Success Rate", "Failed Syncs by Cluster", "Secret Age"]
    },
    {
      "title": "Tier 3: High-Security (Vault Agent)",
      "metrics": ["Agent Health", "Dynamic Secret Generation", "Memory Usage"]
    },
    {
      "title": "Vault Cluster Health",
      "metrics": ["API Latency", "Storage Usage", "Audit Log Rate"]
    }
  ]
}
```

---

## Cost-Benefit Analysis

### Resource Usage Comparison

| Tier | Per-Cluster Overhead | Vault Load | Network Traffic | Operational Cost |
|------|---------------------|------------|-----------------|------------------|
| **Tier 1 (RHACM)** | None (Hub only) | Low (hub queries) | Low (policy sync) | Low (quarterly tasks) |
| **Tier 2 (ESO)** | 1 operator pod | Medium (100+ clients) | Medium (hourly syncs) | Low (automatic) |
| **Tier 3 (Vault Agent)** | 1 sidecar per pod | High (per-pod queries) | High (per-pod) | High (complex configs) |

**Example Fleet (100 clusters):**
- **Tier 1**: 1 hub + Vault Agent = 2 pods total
- **Tier 2**: 100 ESO pods (1 per cluster) = ~100 pods
- **Tier 3**: 10 namespaces × 20 pods × 100 clusters = 20,000 sidecars

**Recommendation**: Use Tier 3 sparingly (5-10% of workloads maximum)

---

## Migration from Single-Pattern to Hybrid

### Scenario: Currently Using ESO for Everything

**Current State**:
```
✓ ESO deployed to all 100 clusters
✓ All secrets synced via ESO (500+ ExternalSecrets per cluster)
✗ LDAP password updated = 100+ ExternalSecrets to monitor
✗ No differentiation by sensitivity
✗ Critical secrets in etcd
```

**Migration Path**:

**Week 1-2**: Add Tier 1 (RHACM)
```bash
# 1. Identify infrastructure secrets currently in ESO
grep -r "kind: ExternalSecret" | grep -E "(ldap|ca-bundle|registry)"

# 2. Create RHACM policies for these secrets
# 3. Test on 10 clusters (keep ESO as backup)
# 4. Once validated, delete ExternalSecret CRs
# 5. Rollout to remaining clusters
```

**Week 3-6**: Add Tier 3 (Vault Agent)
```bash
# 1. Identify compliance workloads (payments, healthcare)
# 2. Install Vault Agent Injector
# 3. Update deployments with sidecar annotations
# 4. Validate secrets no longer in etcd
# 5. Delete ExternalSecret CRs for migrated workloads
```

**Result**: Hybrid architecture with appropriate patterns per secret type

---

## Summary: Hybrid Recommendation

### The Winning Combination

```
┌─────────────────────────────────────────────────────────┐
│                  100+ Cluster Fleet                     │
│                                                         │
│  5-10 Infrastructure Secrets → Tier 1 (RHACM)          │
│  • LDAP, CAs, Registry, Etcd keys                      │
│  • Quarterly rotation, manual validation               │
│  • Hub distributes to all clusters                     │
│                                                         │
│  90-95% of Secrets → Tier 2 (ESO)                      │
│  • S3, PKI certs, app configs, monitoring              │
│  • Automatic hourly/daily rotation                     │
│  • Vault PKI for dynamic certificates                  │
│  • Independent per-cluster operation                   │
│                                                         │
│  5-10% of Workloads → Tier 3 (Vault Agent)             │
│  • Payments, PII, HIPAA, financial APIs                │
│  • In-memory only, never in etcd                       │
│  • Dynamic per-pod credentials                         │
│  • Compliance-driven requirement                       │
└─────────────────────────────────────────────────────────┘
```

**This hybrid approach provides:**
- ✅ Security: Right level of protection for each secret type
- ✅ Operations: Automation where possible, control where needed
- ✅ Compliance: Meets regulatory requirements (PCI, HIPAA)
- ✅ Scale: Efficient at 100+ clusters
- ✅ Flexibility: Adapt patterns as requirements evolve
- ✅ Cost: Optimize resource usage based on criticality

---

## Bootstrap Strategy: Distributing Vault Credentials to 100+ Clusters

### The Challenge

**The "Chicken and Egg" Problem**: External Secrets Operator (ESO) needs credentials to authenticate to Vault and fetch secrets. But how do you securely distribute those initial credentials to 100+ clusters without creating a security vulnerability?

This is the most critical operational security decision in multi-cluster secret management.

---

## Strategy 1: Kubernetes Auth Method (RECOMMENDED - No Tokens!)

**STATUS**: ✅ **BEST PRACTICE** - Eliminates credential distribution entirely

### How It Works

Vault's Kubernetes auth method uses the cluster's own identity to authenticate—**no tokens to distribute**!

```
┌─────────────────────────────────┐
│ Vault Cluster                   │
│ Vault NS: prod/                 │ ← Vault namespace
│                                 │
│ 1. Cluster-001 K8s API endpoint │
│    registered in Vault          │
│                                 │
│ 2. Vault validates JWT tokens   │
│    against cluster API          │
└────────────┬────────────────────┘
             │
             │ 3. ESO sends its K8s
             │    ServiceAccount JWT
             │
┌────────────▼────────────────────┐
│ cluster-001                     │
│                                 │
│ K8s NS: external-secrets        │ ← K8s namespace
│   ServiceAccount: external-secrets
│     └─ JWT token (auto-generated)
│                                 │
│   Pod: external-secrets-operator│
│     └─ Uses SA token to auth    │
└─────────────────────────────────┘
```

### Step-by-Step Implementation

#### Phase 1: Configure Vault (Per Cluster)

For each cluster, register its Kubernetes API endpoint with Vault:

```bash
#!/bin/bash
# Script: bootstrap-cluster-vault-auth.sh
# Run once per cluster

CLUSTER_NAME="cluster-001"
CLUSTER_API="https://api.cluster-001.example.com:6443"
VAULT_NS="prod"  # ← Vault namespace

# 1. Create a ServiceAccount in the cluster for Vault to use
# (Vault uses this to validate other ServiceAccount tokens)
oc create namespace vault-auth --dry-run=client -o yaml | oc apply -f -
oc create serviceaccount vault-auth -n vault-auth

# 2. Create ClusterRoleBinding for token review
cat <<EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: vault-auth-token-reviewer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator  # ← Built-in role for token review
subjects:
- kind: ServiceAccount
  name: vault-auth
  namespace: vault-auth  # ← K8s namespace
EOF

# 3. Extract the ServiceAccount token and CA cert
SA_SECRET=$(oc get sa vault-auth -n vault-auth -o jsonpath='{.secrets[0].name}')
SA_JWT_TOKEN=$(oc get secret $SA_SECRET -n vault-auth -o jsonpath='{.data.token}' | base64 -d)
SA_CA_CERT=$(oc get secret $SA_SECRET -n vault-auth -o jsonpath='{.data.ca\.crt}' | base64 -d)

# 4. Configure Kubernetes auth in Vault
# Set Vault namespace context
export VAULT_NAMESPACE="$VAULT_NS"

vault auth enable -path="kubernetes-${CLUSTER_NAME}" kubernetes

vault write auth/kubernetes-${CLUSTER_NAME}/config \
  kubernetes_host="$CLUSTER_API" \
  kubernetes_ca_cert="$SA_CA_CERT" \
  token_reviewer_jwt="$SA_JWT_TOKEN" \
  disable_local_ca_jwt=true

# 5. Create Vault role for ESO in this cluster
vault write auth/kubernetes-${CLUSTER_NAME}/role/eso \
  bound_service_account_names=external-secrets \
  bound_service_account_namespaces=external-secrets \  # ← K8s namespace
  policies="${CLUSTER_NAME}-eso-policy" \
  ttl=1h \
  max_ttl=24h

echo "✅ Vault Kubernetes auth configured for ${CLUSTER_NAME}"
```

#### Phase 2: Deploy ESO to Cluster (No Secrets Needed!)

```yaml
---
# File: eso-deployment.yaml
# Deploy to K8s namespace: external-secrets

apiVersion: v1
kind: Namespace
metadata:
  name: external-secrets  # ← K8s namespace

---
# ServiceAccount (automatically gets JWT token)
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-secrets
  namespace: external-secrets  # ← K8s namespace

---
# Install ESO (via Helm, OLM, or manifest)
# ESO pod will use the ServiceAccount above

---
# ClusterSecretStore: NO CREDENTIALS IN YAML!
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://vault.example.com:8200"
      namespace: "prod"  # ← Vault namespace
      path: "secret"
      version: "v2"
      
      auth:
        kubernetes:
          mountPath: "kubernetes-cluster-001"  # ← Auth path in Vault
          role: "eso"  # ← Vault role
          
          # Reference to K8s ServiceAccount (uses its JWT automatically)
          serviceAccountRef:
            name: external-secrets
            namespace: external-secrets  # ← K8s namespace
          
          # Optional: Specify SA token path if non-standard
          # secretRef:
          #   name: external-secrets-token
          #   key: token
      
      caBundle: <base64-vault-ca-cert>
```

#### Phase 3: Automate for 100+ Clusters

```yaml
---
# File: ansible-playbook-bootstrap-vault-auth.yml
# Automate Vault auth setup across all clusters

- name: Bootstrap Vault Kubernetes Auth for All Clusters
  hosts: localhost
  vars:
    vault_addr: "https://vault.example.com:8200"
    vault_namespace: "prod"  # ← Vault namespace
    clusters:
      - name: cluster-001
        api_url: https://api.cluster-001.example.com:6443
        kubeconfig: /path/to/cluster-001-kubeconfig
      - name: cluster-002
        api_url: https://api.cluster-002.example.com:6443
        kubeconfig: /path/to/cluster-002-kubeconfig
      # ... 100+ clusters
  
  tasks:
  - name: Set Vault namespace
    set_fact:
      vault_env:
        VAULT_ADDR: "{{ vault_addr }}"
        VAULT_NAMESPACE: "{{ vault_namespace }}"
  
  - name: Configure Vault auth for each cluster
    environment: "{{ vault_env }}"
    loop: "{{ clusters }}"
    block:
    
    - name: Create vault-auth namespace in cluster
      kubernetes.core.k8ns:
        name: vault-auth
        kubeconfig: "{{ item.kubeconfig }}"
        state: present
    
    - name: Create ServiceAccount for Vault
      kubernetes.core.k8s:
        kubeconfig: "{{ item.kubeconfig }}"
        definition:
          apiVersion: v1
          kind: ServiceAccount
          metadata:
            name: vault-auth
            namespace: vault-auth  # ← K8s namespace
    
    - name: Create ClusterRoleBinding
      kubernetes.core.k8s:
        kubeconfig: "{{ item.kubeconfig }}"
        definition:
          apiVersion: rbac.authorization.k8s.io/v1
          kind: ClusterRoleBinding
          metadata:
            name: vault-auth-token-reviewer
          roleRef:
            apiGroup: rbac.authorization.k8s.io
            kind: ClusterRole
            name: system:auth-delegator
          subjects:
          - kind: ServiceAccount
            name: vault-auth
            namespace: vault-auth
    
    - name: Get ServiceAccount token
      kubernetes.core.k8s_info:
        kubeconfig: "{{ item.kubeconfig }}"
        kind: Secret
        namespace: vault-auth
        label_selectors:
          - "kubernetes.io/service-account.name=vault-auth"
      register: sa_secret
    
    - name: Extract token and CA cert
      set_fact:
        sa_token: "{{ sa_secret.resources[0].data.token | b64decode }}"
        sa_ca: "{{ sa_secret.resources[0].data['ca.crt'] | b64decode }}"
    
    - name: Enable Kubernetes auth in Vault
      hashivault_auth_method:
        method_type: kubernetes
        mount_point: "kubernetes-{{ item.name }}"
        state: present
    
    - name: Configure Kubernetes auth backend
      hashivault_write:
        secret: "auth/kubernetes-{{ item.name }}/config"
        data:
          kubernetes_host: "{{ item.api_url }}"
          kubernetes_ca_cert: "{{ sa_ca }}"
          token_reviewer_jwt: "{{ sa_token }}"
    
    - name: Create Vault role for ESO
      hashivault_write:
        secret: "auth/kubernetes-{{ item.name }}/role/eso"
        data:
          bound_service_account_names: external-secrets
          bound_service_account_namespaces: external-secrets
          policies: "{{ item.name }}-eso-policy"
          ttl: 3600
          max_ttl: 86400
```

### Why This is Secure

✅ **No Tokens to Distribute**: Kubernetes ServiceAccount tokens are auto-generated and mounted  
✅ **Cluster-Bound Authentication**: Vault validates tokens against specific cluster API  
✅ **Namespace Scoping**: Vault roles bound to specific K8s namespace + ServiceAccount  
✅ **Automatic Rotation**: K8s rotates SA tokens periodically  
✅ **Mutual Trust**: Vault trusts cluster CA, cluster validates Vault TLS  
✅ **Audit Trail**: All auth attempts logged in Vault audit log

### Limitations

⚠️ **Network Requirement**: Vault must reach cluster API servers (for token validation)  
⚠️ **Initial Setup Per Cluster**: Requires one-time configuration per cluster  
⚠️ **Vault Enterprise**: Vault namespaces require Enterprise (or use path-based separation)

---

## Strategy 2: AppRole with Response Wrapping (Manual Bootstrap)

**STATUS**: ⚠️ **ACCEPTABLE** for smaller fleets or where K8s auth isn't feasible

### How It Works

AppRole provides two credentials:
- **Role-ID**: Public identifier (can be in Git)
- **Secret-ID**: Sensitive, single-use, time-limited

```
┌─────────────────────────────────┐
│ Vault Cluster                   │
│ Vault NS: prod/                 │ ← Vault namespace
│                                 │
│ 1. Admin generates wrapped      │
│    secret-id (single-use)       │
│    TTL: 1 hour                  │
└────────────┬────────────────────┘
             │
             │ 2. Wrapped token delivered
             │    via secure channel
             │
┌────────────▼────────────────────┐
│ cluster-001                     │
│                                 │
│ 3. ESO unwraps secret-id        │
│    (can only be done once)      │
│                                 │
│ 4. ESO authenticates with       │
│    role-id + secret-id          │
│                                 │
│ 5. ESO gets Vault token         │
│    and stores in K8s Secret     │
└─────────────────────────────────┘
```

### Implementation

#### Step 1: Configure AppRole in Vault

```bash
#!/bin/bash
# Run on Vault admin workstation

CLUSTER_NAME="cluster-001"
VAULT_NS="prod"  # ← Vault namespace

export VAULT_NAMESPACE="$VAULT_NS"

# Enable AppRole auth
vault auth enable approle

# Create AppRole for cluster
vault write auth/approle/role/${CLUSTER_NAME}-eso \
  token_ttl=1h \
  token_max_ttl=24h \
  token_policies="${CLUSTER_NAME}-eso-policy" \
  bind_secret_id=true \
  secret_id_ttl=1h \
  secret_id_num_uses=1  # ← Single use!

# Get Role-ID (not sensitive, can be in Git)
ROLE_ID=$(vault read -field=role_id auth/approle/role/${CLUSTER_NAME}-eso/role-id)
echo "Role-ID: $ROLE_ID"  # Save this

# Generate wrapped Secret-ID (sensitive!)
WRAPPED_TOKEN=$(vault write -wrap-ttl=1h -field=wrapping_token \
  auth/approle/role/${CLUSTER_NAME}-eso/secret-id)

echo "Wrapped Secret-ID token: $WRAPPED_TOKEN"
# Deliver this securely to cluster admin (expiry: 1 hour)
```

#### Step 2: Bootstrap ESO in Cluster

```bash
#!/bin/bash
# Run on cluster-001 (by cluster admin)

ROLE_ID="<from-step-1>"
WRAPPED_TOKEN="<securely-delivered>"
VAULT_ADDR="https://vault.example.com:8200"
VAULT_NS="prod"  # ← Vault namespace

# Unwrap the secret-id (can only be done once!)
SECRET_ID=$(curl -s \
  --header "X-Vault-Token: $WRAPPED_TOKEN" \
  --header "X-Vault-Namespace: $VAULT_NS" \
  $VAULT_ADDR/v1/sys/wrapping/unwrap | jq -r '.data.secret_id')

# Create K8s Secret with AppRole credentials
oc create namespace external-secrets  # ← K8s namespace

oc create secret generic vault-approle \
  -n external-secrets \
  --from-literal=role-id="$ROLE_ID" \
  --from-literal=secret-id="$SECRET_ID"

# IMPORTANT: Delete local copy
unset SECRET_ID
unset WRAPPED_TOKEN
history -c
```

#### Step 3: Configure ClusterSecretStore

```yaml
---
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://vault.example.com:8200"
      namespace: "prod"  # ← Vault namespace
      path: "secret"
      version: "v2"
      
      auth:
        appRole:
          path: "approle"
          
          # Role-ID from K8s Secret
          roleId: "vault-approle"
          roleRef:
            name: vault-approle
            namespace: external-secrets  # ← K8s namespace
            key: role-id
          
          # Secret-ID from K8s Secret
          secretRef:
            name: vault-approle
            namespace: external-secrets  # ← K8s namespace
            key: secret-id
      
      caBundle: <base64-vault-ca-cert>
```

#### Step 4: Rotate to Long-Lived Secret-ID

After ESO is running, rotate to a longer TTL (ESO will auto-renew):

```bash
# In Vault
vault write auth/approle/role/${CLUSTER_NAME}-eso \
  secret_id_ttl=24h \
  secret_id_num_uses=0  # ← Unlimited uses (ESO will renew)

# Generate new secret-id
NEW_SECRET_ID=$(vault write -field=secret_id \
  auth/approle/role/${CLUSTER_NAME}-eso/secret-id)

# Update K8s Secret
oc patch secret vault-approle -n external-secrets \
  --type='json' \
  -p='[{"op": "replace", "path": "/data/secret-id", "value": "'$(echo -n $NEW_SECRET_ID | base64)'"}]'

# ESO will automatically pick up the new secret-id
```

### Security Considerations

✅ **Response Wrapping**: Secret-ID delivered wrapped (single-use, time-limited)  
✅ **No Long-Lived Secrets in Transit**: Wrapped token expires in 1 hour  
✅ **Single-Use Bootstrap**: Initial secret-id can only be unwrapped once  
✅ **Automatic Renewal**: ESO renews tokens before expiry

⚠️ **Manual Process**: Requires operator intervention per cluster  
⚠️ **K8s Secret Storage**: Secret-ID stored in etcd (ensure etcd encryption)  
⚠️ **Initial Delivery Risk**: Wrapped token must be delivered securely

### Automation for 100+ Clusters

```yaml
---
# Ansible playbook to automate AppRole bootstrap

- name: Bootstrap AppRole for All Clusters
  hosts: localhost
  vars:
    vault_namespace: "prod"  # ← Vault namespace
  
  tasks:
  - name: Generate wrapped secret-id for each cluster
    hashivault_write:
      secret: "auth/approle/role/{{ item.name }}-eso/secret-id"
      wrap_ttl: "1h"
    loop: "{{ clusters }}"
    register: wrapped_tokens
  
  - name: Store wrapped tokens securely
    copy:
      content: |
        Cluster: {{ item.item.name }}
        Wrapped Token: {{ item.wrap_info.token }}
        Expires: {{ item.wrap_info.creation_time + 3600 }}
        
        Deliver to: {{ item.item.admin_email }}
      dest: "/secure/tokens/{{ item.item.name }}-wrapped-token.txt"
      mode: '0600'
    loop: "{{ wrapped_tokens.results }}"
  
  - name: Send wrapped tokens to cluster admins
    mail:
      to: "{{ item.item.admin_email }}"
      subject: "Vault Secret-ID for {{ item.item.name }}"
      body: |
        Wrapped token (expires in 1 hour):
        {{ item.wrap_info.token }}
        
        Role-ID (not sensitive):
        {{ item.item.role_id }}
        
        Instructions:
        1. Run: export WRAPPED_TOKEN="{{ item.wrap_info.token }}"
        2. Follow bootstrap script in runbook
    loop: "{{ wrapped_tokens.results }}"
```

---

## Strategy 3: Cloud Provider IAM (AWS/Azure/GCP)

**STATUS**: ✅ **IDEAL** if clusters run on supported cloud providers

### AWS: IAM Roles for Service Accounts (IRSA)

```yaml
---
# ClusterSecretStore using AWS IAM auth
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://vault.example.com:8200"
      namespace: "prod"  # ← Vault namespace
      path: "secret"
      version: "v2"
      
      auth:
        aws:
          region: us-east-1
          role: "eso-cluster-001"  # ← Vault role
          
          # ESO uses IRSA to get AWS credentials
          # ServiceAccount annotated with IAM role ARN
          serviceAccountRef:
            name: external-secrets
            namespace: external-secrets  # ← K8s namespace
```

**Setup**:

```bash
# 1. Annotate ServiceAccount with IAM role
oc annotate serviceaccount external-secrets \
  -n external-secrets \
  eks.amazonaws.com/role-arn=arn:aws:iam::123456789012:role/eso-cluster-001

# 2. Configure Vault AWS auth
vault auth enable aws

vault write auth/aws/role/eso-cluster-001 \
  auth_type=iam \
  bound_iam_principal_arn="arn:aws:iam::123456789012:role/eso-cluster-001" \
  policies="cluster-001-eso-policy" \
  ttl=1h
```

✅ **No tokens to distribute**: Uses AWS IAM identity  
✅ **Cloud-native**: Leverages existing IAM infrastructure

### Azure: Managed Identity

```yaml
---
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://vault.example.com:8200"
      namespace: "prod"  # ← Vault namespace
      
      auth:
        azure:
          # Managed Identity of the AKS cluster
          subscriptionID: "12345678-1234-1234-1234-123456789012"
          resourceGroupName: "cluster-001-rg"
          identityName: "cluster-001-eso-identity"
```

### GCP: Workload Identity

```yaml
---
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://vault.example.com:8200"
      namespace: "prod"  # ← Vault namespace
      
      auth:
        gcp:
          workloadIdentity:
            serviceAccountRef:
              name: external-secrets
              namespace: external-secrets  # ← K8s namespace
          projectID: "my-gcp-project"
          clusterLocation: "us-central1-a"
          clusterName: "cluster-001"
```

---

## Strategy 4: RHACM/ACM Bootstrap Distribution

**STATUS**: ✅ **GOOD** for existing RHACM deployments

### How It Works

The RHACM Hub cluster securely distributes initial credentials to spoke clusters via Policies:

```yaml
---
# On Hub cluster, K8s namespace: rhacm-policies
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: distribute-vault-credentials
  namespace: rhacm-policies  # ← K8s namespace on Hub
spec:
  disabled: false
  remediationAction: enforce
  
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: create-vault-approle-secret
      spec:
        severity: high
        remediationAction: enforce
        
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: v1
            kind: Secret
            metadata:
              name: vault-approle
              namespace: external-secrets  # ← K8s namespace on spoke
            type: Opaque
            stringData:
              # Hub reads from its own secure storage
              # Different credentials per cluster using template
              role-id: '{{hub fromConfigMap "vault-integration" "cluster-credentials" (printf "%s-role-id" .ManagedClusterName) hub}}'
              secret-id: '{{hub fromSecret "vault-integration" (printf "vault-secret-%s" .ManagedClusterName) "secret-id" hub}}'
```

**Process**:

1. Hub authenticates to Vault (using K8s auth or AppRole)
2. Hub fetches cluster-specific credentials from Vault
3. Hub distributes via Policy to each spoke cluster
4. Spoke's ESO uses the credentials to authenticate directly to Vault

✅ **Centralized management**: Hub controls distribution  
✅ **Policy compliance**: Detects if credentials are deleted/modified  
✅ **Per-cluster isolation**: Each spoke gets unique credentials

⚠️ **Hub must be highly secure**: Compromise of Hub = all credentials exposed

---

## Comparison Matrix

| Strategy | Security | Scalability | Complexity | Cloud Native | Best For |
|----------|----------|-------------|------------|--------------|----------|
| **K8s Auth** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ✅ | Any K8s cluster with API access |
| **AppRole + Wrapping** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ✅ | Air-gapped or restricted networks |
| **Cloud IAM** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ | AWS/Azure/GCP clusters |
| **RHACM Distribution** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ✅ | Existing RHACM deployments |

---

## Recommended Approach for 100+ Clusters

### Primary: Kubernetes Auth

Use K8s auth as the default for all clusters where possible:

```bash
# Automation script
for cluster in $(cat clusters.txt); do
  ./bootstrap-k8s-auth.sh $cluster
done
```

### Fallback: Cloud Provider IAM

For cloud-hosted clusters, use native IAM where available:
- AWS EKS → IRSA
- Azure AKS → Managed Identity
- GCP GKE → Workload Identity

### Emergency: AppRole with Response Wrapping

For air-gapped or special cases:
- Generate wrapped secret-id
- Deliver via secure channel (encrypted email, secure portal)
- Time-limited (1-hour expiry)
- Single-use unwrap

---

## Security Best Practices

### ✅ DO

1. **Use Kubernetes Auth** as default—no tokens to distribute
2. **Automate bootstrap** with Ansible/Terraform across all clusters
3. **Monitor authentication failures** in Vault audit logs
4. **Rotate credentials regularly** (automated via ESO)
5. **Use Vault namespaces** to isolate environments (prod/nonprod)
6. **Bind to specific K8s namespaces** in Vault roles
7. **Enable audit logging** on both Vault and clusters

### ❌ DON'T

1. **Never store long-lived tokens in Git** (even encrypted)
2. **Never share credentials across clusters** (unique per cluster)
3. **Never use root tokens** for cluster authentication
4. **Never skip TLS validation** between ESO and Vault
5. **Never distribute unwrapped secret-ids** via insecure channels
6. **Never ignore authentication failures** (investigate immediately)
7. **Never store Vault tokens in ConfigMaps** (always use Secrets with etcd encryption)

---

## Troubleshooting Bootstrap Issues

### ESO Cannot Authenticate to Vault

```bash
# Check ESO logs
oc logs -n external-secrets deployment/external-secrets -f

# Common errors:
# 1. "permission denied" → Check Vault role/policy
# 2. "invalid token" → Check token expiry, rotation
# 3. "connection refused" → Check network, firewall, TLS
```

### Kubernetes Auth Fails

```bash
# Verify Vault can reach cluster API
vault write -namespace=prod auth/kubernetes-cluster-001/login \
  role=eso \
  jwt=<test-sa-token>

# Check Vault auth config
vault read -namespace=prod auth/kubernetes-cluster-001/config

# Verify ServiceAccount token is valid
oc serviceaccounts get-token external-secrets -n external-secrets
```

### AppRole Secret-ID Issues

```bash
# Check if secret-id is exhausted (num_uses)
vault write auth/approle/role/cluster-001-eso/secret-id

# List existing secret-ids
vault list auth/approle/role/cluster-001-eso/secret-id

# Revoke old secret-ids
vault write auth/approle/role/cluster-001-eso/secret-id-accessor/destroy \
  secret_id_accessor=<accessor>
```

---

## Quick Reference: Namespace Types

| Concept | What It Is | Example | Used In |
|---------|-----------|---------|---------|
| **Vault Namespace** | Multi-tenancy in Vault | `prod/`, `nonprod/` | Vault Enterprise |
| **K8s Namespace** | Resource isolation in cluster | `external-secrets`, `my-app` | OpenShift/K8s |
| **Vault Path** | Secret location within Vault | `secret/data/cluster-001/` | All Vault engines |
| **K8s ServiceAccount** | Pod identity | `external-secrets`, `my-app` | K8s RBAC |

---

## Document Status & Roadmap

### ✅ Version 1.0 - Complete

This version provides comprehensive coverage of:

**Core Concepts:**
- ✅ Vault namespace vs K8s namespace terminology
- ✅ KV v1 vs KV v2 comparison and recommendations
- ✅ Shared vs cluster-specific secret organization strategies

**Architecture Patterns:**
- ✅ Option 1: External Secrets Operator (ESO) - Production-ready pattern
- ✅ Option 2: RHACM Policy Distribution - Hub-spoke model
- ✅ Option 3: Vault Agent Sidecar - Advanced in-memory secrets
- ✅ **Hybrid Recommendation** - Three-tier approach for 100+ clusters ⭐

**Bootstrap & Operations:**
- ✅ Kubernetes Auth method (no credentials to distribute)
- ✅ AppRole with response wrapping
- ✅ Cloud provider IAM integration (AWS/Azure/GCP)
- ✅ RHACM-based credential distribution
- ✅ Security best practices and troubleshooting

**Hybrid Implementation:**
- ✅ Tier 1: Infrastructure secrets via RHACM
- ✅ Tier 2: Application secrets via ESO (90-95% of secrets)
- ✅ Tier 3: Compliance workloads via Vault Agent
- ✅ Decision matrices and phased rollout strategy
- ✅ Migration paths from single-pattern to hybrid
- ✅ Cost-benefit analysis and monitoring guidance

### 📋 Planned for Future Versions

**Option 4: Vault Secrets Operator (VSO)**
- HashiCorp's native Kubernetes operator
- Comparison with External Secrets Operator
- CRD-based secret management
- PKI and dynamic secret integration

**Implementation Runbooks**
- Step-by-step deployment guides
- Automation scripts (Ansible, Terraform)
- Day-2 operations procedures
- Certificate management workflows

**Monitoring & Observability**
- Prometheus metrics and alerts
- Grafana dashboards
- Vault audit log analysis
- Secret sync monitoring across fleet

**Disaster Recovery**
- Vault backup and restore procedures
- Cluster recovery scenarios
- Secret rotation emergency procedures
- Business continuity planning

**Advanced Patterns**
- Dynamic database credentials
- Certificate lifecycle automation
- Secret rotation strategies
- Multi-region Vault deployment

### 🤝 Contributing

This document is part of a DevOps examples repository. Contributions, corrections, and improvements are welcome. Please ensure:

- Examples are tested in lab environments
- Security best practices are followed
- Documentation includes clear explanations
- AI-generated content is disclosed

### 📚 Related Resources

**Official Documentation:**
- [HashiCorp Vault Documentation](https://developer.hashicorp.com/vault/docs)
- [External Secrets Operator](https://external-secrets.io/)
- [Red Hat OpenShift Documentation](https://docs.openshift.com/)
- [Red Hat Advanced Cluster Management](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/)

**Community Resources:**
- [Vault Best Practices](https://developer.hashicorp.com/vault/tutorials/operations/production-hardening)
- [Kubernetes Secrets Management](https://kubernetes.io/docs/concepts/configuration/secret/)
- [OpenShift Security Guide](https://docs.openshift.com/container-platform/latest/security/index.html)

### 📝 Feedback & Questions

This document represents patterns and recommendations based on security best practices and operational experience. Your specific requirements may vary based on:

- Organizational security policies
- Compliance requirements (PCI-DSS, HIPAA, SOC 2, etc.)
- Network topology and constraints
- Tool versions and capabilities
- Scale and complexity of deployments

Always validate recommendations against your specific environment and requirements.

---

**Document prepared with Claude AI assistance**  
**Review, validation, and testing remain user responsibility**

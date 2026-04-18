# OCM Subscription Automation

**Target Audience**: Platform Engineers, Cluster Administrators  
**Use Case**: Bare metal OpenShift cluster post-install subscription configuration  
**Last Updated**: March 2026

---

## Problem Statement

After a bare metal OpenShift cluster is installed and registers with Red Hat, an administrator must manually visit [console.redhat.com/openshift/cluster-list](https://console.redhat.com/openshift/cluster-list) to configure subscription properties:

1. Select **Premium** (support level)
2. Select **Red Hat Support (L1-L3)** (SLA)
3. Select **Production** or **Development/Test** (usage type)
4. Select **Cores or vCPUs** (billing unit)
5. Click **Save**
6. Refresh the cluster web console to verify the SLA shows **Premium Support Agreement**

This is manual, error-prone, and does not scale across many clusters. This guide documents two automation approaches and introduces **ClusterCurator** as the next evolution for bare metal lifecycle automation.

---

## Prerequisites

### OCM CLI

```bash
# Download latest release
curl -Lo ocm https://github.com/openshift-online/ocm-cli/releases/latest/download/ocm-linux-amd64
chmod +x ocm
sudo mv ocm /usr/local/bin/

# Verify
ocm version
```

### Red Hat Offline Token

Generate a long-lived token at [console.redhat.com/openshift/token](https://console.redhat.com/openshift/token).

This is **not** the pull secret. It is a separate OAuth token scoped to your Red Hat account for API access.

```bash
# Store securely - do not commit to Git
echo "your-token-here" > ~/rh-offline-token.txt
chmod 600 ~/rh-offline-token.txt
```

### python3

Required for JSON parsing in the scripts. Available by default on RHEL/Fedora.

---

## Option 1: OCM CLI (Interactive / One-Off)

Use this approach for ad-hoc changes, debugging, or verifying subscription state.

### Step 1 — Authenticate

```bash
ocm login --token="$(cat ~/rh-offline-token.txt)"
```

### Step 2 — Find the Cluster

```bash
# List all clusters registered to your account
ocm list clusters

# Look up by name
ocm get /api/clusters_mgmt/v1/clusters \
  --parameter "search=name='prod-bm-01'" | python3 -m json.tool

# Get the cluster's OCM internal ID
CLUSTER_ID=$(ocm get /api/clusters_mgmt/v1/clusters \
  --parameter "search=name='prod-bm-01'" | \
  python3 -c "import sys,json; print(json.load(sys.stdin)['items'][0]['id'])")

echo "Cluster ID: $CLUSTER_ID"
```

### Step 3 — Find the Subscription

```bash
SUB_ID=$(ocm get /api/accounts_mgmt/v1/subscriptions \
  --parameter "search=cluster_id='${CLUSTER_ID}'" | \
  python3 -c "import sys,json; print(json.load(sys.stdin)['items'][0]['id'])")

echo "Subscription ID: $SUB_ID"
```

### Step 4 — View Current Subscription Settings

```bash
ocm get /api/accounts_mgmt/v1/subscriptions/${SUB_ID} | \
  python3 -c "
import sys, json
d = json.load(sys.stdin)
for field in ['support_level', 'service_level', 'usage', 'system_units']:
    print(f'{field:20s}: {d.get(field, \"not set\")}')
"
```

### Step 5 — Apply Settings

```bash
ocm patch /api/accounts_mgmt/v1/subscriptions/${SUB_ID} \
  --body='{
    "support_level": "Premium",
    "service_level": "L1-L3",
    "usage":         "Production",
    "system_units":  "Cores/vCPU"
  }'
```

### Step 6 — Verify

```bash
ocm get /api/accounts_mgmt/v1/subscriptions/${SUB_ID} | \
  python3 -c "
import sys, json
d = json.load(sys.stdin)
print('support_level :', d.get('support_level'))
print('service_level :', d.get('service_level'))
print('usage         :', d.get('usage'))
print('system_units  :', d.get('system_units'))
"
```

Then refresh the cluster's OpenShift web console and verify the SLA shows **Premium Support Agreement**.

---

## Option 2: Standalone Script (`set-ocm-subscription.sh`)

Use this approach to automate the process in a CI/CD pipeline, Ansible playbook, or post-install hook.

### Script Location

```
rhacm/examples/ocm-subscription-automation/set-ocm-subscription.sh
```

### Usage Examples

```bash
# Standard Premium Production cluster (enterprise default)
./set-ocm-subscription.sh \
  --cluster-name prod-bm-01 \
  --token-file ~/rh-offline-token.txt

# Development/Test cluster with Standard support
./set-ocm-subscription.sh \
  --cluster-name dev-bm-01 \
  --token-file ~/rh-offline-token.txt \
  --support-level Standard \
  --service-level L3 \
  --usage "Development/Test"

# Dry run to preview changes without applying
./set-ocm-subscription.sh \
  --cluster-name prod-bm-01 \
  --token-file ~/rh-offline-token.txt \
  --dry-run

# Use cluster ID directly (skips name lookup, faster)
./set-ocm-subscription.sh \
  --cluster-id abc-123-def-456 \
  --token "$(cat ~/rh-offline-token.txt)"
```

### Script Options

| Option | Description | Default |
|---|---|---|
| `--cluster-name NAME` | Cluster name in OCM | (required) |
| `--cluster-id ID` | OCM cluster ID (skips lookup) | (required if no name) |
| `--token TOKEN` | Offline token string | (required) |
| `--token-file FILE` | Path to token file | (required if no token) |
| `--support-level` | `Premium`, `Standard`, `Self-Support`, `None` | `Premium` |
| `--service-level` | `L1-L3`, `L3` | `L1-L3` |
| `--usage` | `Production`, `Development/Test` | `Production` |
| `--system-units` | `Cores/vCPU`, `Sockets` | `Cores/vCPU` |
| `--dry-run` | Preview changes without applying | `false` |
| `--verbose` | Show debug output | `false` |

### Sample Output

```
[INFO]  Authenticating with Red Hat OCM...
[INFO]  Authenticated successfully
[INFO]  Looking up cluster: prod-bm-01
[INFO]  Target cluster ID: abc-123-def-456
[INFO]  Looking up subscription for cluster...

  Subscription: sub-789xyz
  ┌──────────────────┬──────────────────────┬──────────────────────┐
  │ Field            │ Current              │ Desired              │
  ├──────────────────┼──────────────────────┼──────────────────────┤
  │ support_level    │ Self-Support         │ Premium              │
  │ service_level    │ L3                   │ L1-L3                │
  │ usage            │ Development/Test     │ Production           │
  │ system_units     │ Sockets              │ Cores/vCPU           │
  └──────────────────┴──────────────────────┴──────────────────────┘

[INFO]  Applying subscription settings...
[INFO]  Subscription updated successfully
[INFO]  Verifying applied settings...
[INFO]  All settings verified successfully

  Next step: Refresh the cluster's OpenShift web console and verify
  the SLA now shows: Premium Support Agreement
```

### Integrate into a Pipeline

```bash
#!/bin/bash
# post-install.sh — Called after bare metal cluster install completes

CLUSTER_NAME="$1"
TOKEN_FILE="/etc/rh-credentials/ocm-token"

echo "Setting OCM subscription for: $CLUSTER_NAME"
/opt/scripts/set-ocm-subscription.sh \
  --cluster-name "$CLUSTER_NAME" \
  --token-file "$TOKEN_FILE" \
  --support-level Premium \
  --usage Production
```

### Store the Token as a Kubernetes Secret (for RHACM Hub)

```bash
# Create secret on RHACM hub for automation use
oc create secret generic rh-ocm-token \
  --from-file=token=~/rh-offline-token.txt \
  -n open-cluster-management

# Reference it in automation jobs
oc get secret rh-ocm-token -n open-cluster-management \
  -o jsonpath='{.data.token}' | base64 -d
```

---

## OCM Subscription Field Reference

| Console Label | API Field | Valid Values |
|---|---|---|
| Support Level | `support_level` | `Premium`, `Standard`, `Self-Support`, `None` |
| SLA | `service_level` | `L1-L3`, `L3` |
| Usage | `usage` | `Production`, `Development/Test` |
| Billing Unit | `system_units` | `Cores/vCPU`, `Sockets` |

### Field Meanings

**`support_level`** — Determines the entitlement tier:
- `Premium` — Full enterprise support, 24x7 access, fastest response times
- `Standard` — Business hours support
- `Self-Support` — Portal access only, no case support
- `None` — Evaluation/trial

**`service_level`** — Response time SLA:
- `L1-L3` — Red Hat handles L1 (basic), L2 (troubleshooting), and L3 (engineering escalation)
- `L3` — Customer handles L1/L2; Red Hat handles L3 engineering escalations only

**`usage`** — How the cluster is classified for entitlement purposes:
- `Production` — Running live workloads
- `Development/Test` — Non-production use; may affect entitlement counting

**`system_units`** — How cluster capacity is measured for subscription counting:
- `Cores/vCPU` — Count by CPU cores or virtual CPUs (most common for bare metal)
- `Sockets` — Count by physical CPU sockets (legacy licensing model)

---

## What is ClusterCurator?

See [cluster-curator/README.md](./cluster-curator/README.md) for a detailed explanation of ClusterCurator and how it enables automatic post-install subscription configuration for bare metal clusters.

**Short answer**: ClusterCurator is an RHACM component that lets you run **pre- and post-install automation hooks** (Ansible jobs) around cluster lifecycle events — provisioning, upgrading, scaling, and decommissioning. For bare metal, it eliminates the need to manually trigger the OCM subscription script after each cluster install.

---

## Troubleshooting

### "Cluster not found in OCM"

The cluster may not have phoned home yet. Check:

```bash
# On the cluster — is insights-operator running?
oc get clusteroperator insights
oc get pods -n openshift-insights

# Is the pull secret valid?
oc get secret pull-secret -n openshift-config \
  -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d | \
  python3 -m json.tool | grep -A2 "cloud.openshift.com"
```

### "No subscription found for cluster ID"

The cluster is registered but no subscription is attached. This happens when:
- The cluster was installed with a personal/developer Red Hat account that has no OCP entitlement
- The subscription was not yet propagated from Red Hat's backend

Contact your Red Hat account team or open a support case to manually attach the subscription.

### "support_level mismatch after patch"

Your Red Hat account may not have the `Premium` entitlement. Verify quota:

```bash
ocm get /api/accounts_mgmt/v1/quota_summary
```

### OCM CLI Authentication Fails

```bash
# Re-generate token at:
# https://console.redhat.com/openshift/token
# Then re-login:
ocm logout
ocm login --token="$(cat ~/rh-offline-token.txt)"
```

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

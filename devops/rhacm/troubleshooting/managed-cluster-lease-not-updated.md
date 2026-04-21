# Troubleshooting: Registration Agent Stopped Updating Its Lease

**Symptom:** One or more managed clusters show status `Unknown` with the message:

> The cluster is not reachable. Registration agent stopped updating its lease.

This guide covers diagnosis and recovery — with specific attention to the context of a hub cluster upgrade where the `MultiClusterHub` (MCH) is in a `Pending` or `Updating` state.

---

## How the Lease Mechanism Works

Each managed cluster runs a `klusterlet`, which includes a `registration-agent` component. The agent:

1. Continuously updates a `ManagedClusterLease` object on the hub (in the cluster's namespace, e.g. `open-cluster-management/<cluster-name>`)
2. Updates a local lease in `open-cluster-management-agent` on the managed cluster itself

The hub's `registration-controller` monitors these leases. If a lease is not updated for `leaseDurationSeconds × 5` (default: 60s × 5 = **300 seconds / 5 minutes**), the hub sets the cluster to `Unknown` with the lease message.

**During an ACM hub upgrade**, the `registration-controller` and other hub components are restarted as part of the MCH reconciliation. Per the official ACM 2.15 documentation:

> It can take up to 10 minutes for the `MultiClusterHub` custom resource to finish upgrading.

Clusters showing this lease error while the MCH is still in `Updating`/`Pending` state are **expected behavior** — they should self-recover once the hub returns to `Running`. If the error persists after the hub is healthy, use the diagnostic steps below.

**Reference:** [Red Hat ACM 2.15 — Upgrading your hub cluster](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html/install/installing#upgrading-hub)

---

## Step 1 — Determine if This Is Upgrade-Transient or Persistent

### Check hub upgrade status first

```bash
# Is the MCH still upgrading?
oc get mch -n open-cluster-management

# Detailed status including currentVersion vs desiredVersion
oc get mch multiclusterhub -n open-cluster-management \
  -o jsonpath='{.status.currentVersion} -> {.status.desiredVersion}{"\n"}'

# Full status conditions
oc get mch multiclusterhub -n open-cluster-management \
  -o jsonpath='{range .status.conditions[*]}{.type}: {.reason} — {.message}{"\n"}{end}'
```

**If MCH is still `Updating` or `Pending`:** wait for it to reach `Running` before investigating further. Monitor with:

```bash
watch -n 30 "oc get mch -n open-cluster-management && \
  oc get managedcluster"
```

**If MCH is `Running`** and clusters are still unknown: proceed to Step 2.

### Verify MCE compliance (ACM 2.15+)

During upgrade, ACM automatically upgrades the multicluster engine operator. Confirm it completed:

```bash
oc get multiclusterengine -o jsonpath='{.status.conditions[?(@.type=="ManagedClusterHubAcceptedCondition")]}'

# Check mceVersionCompliance — should show isCompliant: true after upgrade
oc get mch multiclusterhub -n open-cluster-management \
  -o jsonpath='{.status.components}' | jq '.[] | select(.name | contains("mce"))'
```

---

## Step 2 — Hub-Side Checks

Run these against the **hub cluster**.

### 2a. Managed cluster status and lease

```bash
CLUSTER=<your-cluster-name>

# Full managed cluster status
oc get managedcluster $CLUSTER -o yaml | grep -A 30 "status:"

# Check the lease object on the hub
oc get lease $CLUSTER -n $CLUSTER

# Last renewal time
oc get lease $CLUSTER -n $CLUSTER \
  -o jsonpath='Last renewed: {.spec.renewTime}{"\n"}'
```

If `renewTime` is many minutes old and the hub is healthy, the problem is on the managed cluster side (network or klusterlet).

### 2b. Registration controller logs

```bash
# Hub-side registration controller
oc logs -n open-cluster-management-hub \
  -l app=cluster-manager-registration-controller \
  --tail=100 | grep -i "$CLUSTER\|lease\|error\|unknown"

# If you have multiple replicas
oc logs -n open-cluster-management-hub \
  deploy/cluster-manager-registration-controller \
  --tail=200
```

### 2c. Hub events

```bash
oc get events -n $CLUSTER --sort-by=.lastTimestamp | tail -20
oc get events -n open-cluster-management-hub --sort-by=.lastTimestamp | tail -20
```

### 2d. Check for webhook issues

Webhook pods being down during upgrade can deadlock hub reconciliation:

```bash
oc get pods -n open-cluster-management-hub
oc get validatingwebhookconfigurations | grep -i "cluster\|acm\|ocm"
oc get mutatingwebhookconfigurations | grep -i "cluster\|acm\|ocm"
```

---

## Step 3 — Managed Cluster Side Checks

Run these against each **affected managed cluster**.

### 3a. Klusterlet pod health

```bash
# Registration and work agents
oc get pods -n open-cluster-management-agent
oc get pods -n open-cluster-management-agent-addon

# Look for CrashLoopBackOff, ImagePullBackOff, Pending, Error
oc get pods -n open-cluster-management-agent -o wide
```

### 3b. Klusterlet registration agent logs

```bash
# Registration agent — responsible for the lease
oc logs -n open-cluster-management-agent \
  -l app=klusterlet-registration-agent \
  --tail=100 | grep -i "lease\|error\|hub\|connect\|cert\|tls"

# Work agent
oc logs -n open-cluster-management-agent \
  -l app=klusterlet-work-agent \
  --tail=50
```

Common error signatures:

| Log pattern | Likely cause |
|---|---|
| `connection refused` / `i/o timeout` | Network path to hub API server broken |
| `certificate has expired` / `x509` | Agent certificates need rotation |
| `unauthorized` / `403` | RBAC or bootstrap kubeconfig issue |
| `no such host` | DNS resolution failure for hub API server |
| `context deadline exceeded` | Hub API server slow/unreachable |

### 3c. Klusterlet resource status

```bash
oc get klusterlet klusterlet -o yaml | grep -A 20 "status:"

# Check klusterlet conditions
oc get klusterlet klusterlet \
  -o jsonpath='{range .status.conditions[*]}{.type}: {.reason} — {.message}{"\n"}{end}'
```

### 3d. Lease on managed cluster

```bash
oc get lease -n open-cluster-management-agent

# The registration-agent lease — check renewTime
oc get lease -n open-cluster-management-agent \
  -l app=klusterlet-registration-agent -o yaml
```

### 3e. Hub connectivity from managed cluster

```bash
# What hub API endpoint is the klusterlet trying to reach?
HUB_SERVER=$(oc get secret hub-kubeconfig-secret \
  -n open-cluster-management-agent \
  -o jsonpath='{.data.kubeconfig}' | base64 -d | grep server | awk '{print $2}')

echo "Hub API server: $HUB_SERVER"

# Test connectivity (from a pod on the managed cluster if needed)
curl -k --connect-timeout 10 "$HUB_SERVER/healthz"
```

### 3f. Certificate expiry check

```bash
# Hub kubeconfig secret — contains the agent's client cert
oc get secret hub-kubeconfig-secret \
  -n open-cluster-management-agent -o yaml | head -5

# Decode the kubeconfig and check cert expiry
oc get secret hub-kubeconfig-secret \
  -n open-cluster-management-agent \
  -o jsonpath='{.data.kubeconfig}' | base64 -d | \
  python3 -c "
import sys, yaml, base64, subprocess
kc = yaml.safe_load(sys.stdin)
cert_b64 = kc['users'][0]['user'].get('client-certificate-data', '')
if cert_b64:
    import tempfile, os
    with tempfile.NamedTemporaryFile(delete=False, suffix='.crt') as f:
        f.write(base64.b64decode(cert_b64))
        fname = f.name
    subprocess.run(['openssl', 'x509', '-in', fname, '-noout', '-dates'])
    os.unlink(fname)
else:
    print('No inline cert found — may be using file reference')
"

# Bootstrap token / kubeconfig
oc get secret bootstrap-hub-kubeconfig \
  -n open-cluster-management-agent -o yaml | head -5
```

---

## Step 4 — Recovery Procedures

### Scenario A: Hub just finished upgrading, clusters still Unknown

Wait 2–3 minutes after MCH reaches `Running`. The registration-controller will detect updated lease timestamps and flip clusters back to `True`. If not:

```bash
# Restart registration agent on each affected managed cluster
oc rollout restart deployment/klusterlet-registration-agent \
  -n open-cluster-management-agent

oc rollout status deployment/klusterlet-registration-agent \
  -n open-cluster-management-agent
```

### Scenario B: Klusterlet pods are CrashLoopBackOff

```bash
# Describe the failing pod for the exact error
oc describe pod -n open-cluster-management-agent \
  -l app=klusterlet-registration-agent | tail -30

# Check for image pull issues (disconnected environments)
oc get events -n open-cluster-management-agent \
  --sort-by=.lastTimestamp | grep -i "pull\|image\|back"

# Check if the klusterlet operator itself needs updating
oc get csv -n open-cluster-management-agent
```

### Scenario C: Network path broken — hub API server unreachable

1. Verify the hub API server URL in the `hub-kubeconfig-secret` is correct and reachable
2. Check firewall rules between the managed cluster's node IPs and the hub's API server (typically port 6443)
3. Check for expired proxy configurations or changed load balancer endpoints

```bash
# If using a service account proxy — check cluster-proxy addon
oc get pods -n open-cluster-management-agent-addon | grep proxy
oc logs -n open-cluster-management-agent-addon \
  -l component=cluster-proxy-proxy-agent --tail=50
```

### Scenario D: Certificate rotation required

The klusterlet rotates its hub-facing certificates automatically under normal conditions. If certs have expired (e.g., cluster was offline for an extended period):

```bash
# Force re-bootstrap by deleting the hub kubeconfig secret
# WARNING: This causes re-import negotiation — cluster will briefly
# re-enter Pending/Unknown while the new cert is issued
oc delete secret hub-kubeconfig-secret \
  -n open-cluster-management-agent

# Monitor recovery
oc get pods -n open-cluster-management-agent -w
```

If the cluster was deleted and re-imported, also clean the managed cluster object on the hub:

```bash
# On hub — check if cluster is in terminating state
oc get managedcluster $CLUSTER

# If stuck terminating, check for finalizers
oc get managedcluster $CLUSTER \
  -o jsonpath='{.metadata.finalizers}' | jq .
```

### Scenario E: Upgrade stalled — MCH stuck Pending

See companion guide or the official procedure:
- [ACM 2.15 — Upgrading your hub cluster from the console](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html/install/installing#upgrading-hub)
- Disconnected upgrade: [Upgrading in a disconnected network environment](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html/install/installing#upgrading-disconnected)

Key disconnected-specific check — missing `mce-subscription-spec` annotation on MCH causes upgrade to stall:

```bash
# Check for the annotation (required in disconnected environments)
oc get mch multiclusterhub -n open-cluster-management \
  -o jsonpath='{.metadata.annotations}' | jq .

# Add if missing (replace with your actual CatalogSource name)
oc patch mch multiclusterhub -n open-cluster-management \
  --type=merge -p '{
    "metadata": {
      "annotations": {
        "installer.open-cluster-management.io/mce-subscription-spec":
          "{\"source\": \"<your-mirror-catalog-source>\"}"
      }
    }
  }'
```

---

## Step 5 — Validation

After applying fixes, confirm recovery:

```bash
# Managed cluster should return to Available: True, ManagedClusterConditionAvailable
oc get managedcluster $CLUSTER \
  -o jsonpath='{range .status.conditions[*]}{.type}: {.status} — {.message}{"\n"}{end}'

# Lease should be actively renewing
watch -n 30 "oc get lease $CLUSTER -n $CLUSTER \
  -o jsonpath='renewTime: {.spec.renewTime}{\"\\n\"}'"

# Hub and managed cluster components
oc get mch -n open-cluster-management
oc get pods -n open-cluster-management-agent
```

Expected healthy output for managed cluster conditions:

```
ManagedClusterConditionAvailable: True — Managed cluster is available
HubAcceptedManagedCluster: True — Accepted by hub cluster admin
ManagedClusterJoined: True — Managed cluster joined
```

---

## Quick Reference — Key Namespaces and Resources

| Location | Namespace | Resource |
|---|---|---|
| Hub | `open-cluster-management` | `ManagedCluster`, `ManagedClusterLease` |
| Hub | `open-cluster-management-hub` | Registration controller pods |
| Hub | `<cluster-name>` | Per-cluster namespace, `Lease` |
| Managed | `open-cluster-management-agent` | Klusterlet pods, `hub-kubeconfig-secret` |
| Managed | `open-cluster-management-agent-addon` | Add-on agent pods |

## Reference Documentation

- [ACM 2.15 — Installing and Upgrading](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html/install/installing)
- [ACM 2.15 — Upgrading your hub cluster](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html/install/installing#upgrading-hub)
- [ACM 2.15 — Upgrading in disconnected environments](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html/install/installing#upgrading-disconnected)
- [ACM Support Matrix](https://access.redhat.com/articles/7133095)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

---
review:
  status: unreviewed
  notes: "AI-generated from live diagnostic session 2026-04-29. Diagnostic flow (Steps 1–4) walked in session; operator restart as fix confirmed. Root cause (firewall blocking initial reconcile) is speculative — no logs confirmed it. Step 3 (operator logs) and Step 5 (cluster label gating) not exercised in this session. Red Hat docs URLs verified via WebFetch during session; not verified by curl. ACM 2.15.1."
---

# Troubleshooting: Observability Addon Missing for Some Clusters

**Symptom:** One or more managed clusters are not reporting metrics in the ACM Observability dashboards. The `observability-controller` `ManagedClusterAddon` does not exist in the cluster's namespace on the hub, and no `ManifestWork` for observability has been created.

```bash
# No output for the affected cluster:
oc get managedclusteraddon -n <cluster-name>
oc get manifestwork -n <cluster-name> | grep observ
```

---

## How the Observability Addon Is Deployed

The `multicluster-observability-operator` (running in `open-cluster-management`) watches all `ManagedCluster` objects. When a cluster becomes eligible, it:

1. Creates a `ManagedClusterAddon` named `observability-controller` in the cluster's namespace on the hub
2. The OCM addon framework generates a `ManifestWork` from that addon CR
3. The `work-agent` on the spoke applies the ManifestWork, deploying the `endpoint-observability-operator` and `metrics-collector` pods

**Two namespaces to know:**

| Namespace | What lives here |
|---|---|
| `open-cluster-management` | `multicluster-observability-operator` — creates `ManagedClusterAddon` CRs |
| `open-cluster-management-observability` | `observatorium-operator`, `endpoint-operator`, Thanos stack — the hub-side data plane |

The operator in `open-cluster-management` is the one that initiates addon deployment. The pods in `open-cluster-management-observability` are not responsible for creating the addon.

---

## Step 1 — Confirm the Scope

```bash
CLUSTER=<your-cluster-name>

# Which clusters have the addon?
oc get managedclusteraddon -A | grep observability

# Which clusters don't?
# Compare against all managed clusters:
oc get managedcluster

# For each missing cluster, confirm both absence points:
oc get managedclusteraddon -n $CLUSTER
oc get manifestwork -n $CLUSTER | grep observ
```

If `ManagedClusterAddon` is absent, the operator skipped this cluster entirely. Proceed to Step 2.

If `ManagedClusterAddon` exists but metrics aren't flowing, the addon deployed but the data plane is broken — see [Step 7](#step-7--if-the-addon-exists-but-metrics-are-not-flowing).

---

## Step 2 — Check the Obvious Exclusions First

```bash
# Disable label — most common intentional skip
# Per ACM 2.15 docs: "add the following cluster label: observability: disabled"
oc get managedcluster $CLUSTER \
  -o jsonpath='{.metadata.labels}' | jq

# Look for: "observability": "disabled"

# Cluster availability condition
oc get managedcluster $CLUSTER \
  -o jsonpath='{range .status.conditions[*]}{.type}: {.status} — {.message}{"\n"}{end}'

# Taints that block addon placement (ACM 2.7+)
oc get managedcluster $CLUSTER \
  -o jsonpath='{.spec.taints}'
```

The operator skips clusters that are not `ManagedClusterConditionAvailable: True`. A spoke that cannot establish its klusterlet connection back to the hub will show `Unknown` here, even if it appears imported.

---

## Step 3 — Check the Operator Logs

The operator is in `open-cluster-management`, not `open-cluster-management-observability`.

```bash
# Confirm the operator deployment exists
oc get deploy multicluster-observability-operator -n open-cluster-management

# Search logs for the affected cluster
oc logs -n open-cluster-management \
  deploy/multicluster-observability-operator \
  --since=2h | grep -i $CLUSTER

# If nothing appears for the cluster name, broaden to errors
oc logs -n open-cluster-management \
  deploy/multicluster-observability-operator \
  --since=2h | grep -iE "error|fail|skip"
```

Common log signatures:

| Log pattern | Likely cause |
|---|---|
| Cluster name with `skip` / `skipping` | Cluster excluded by condition or annotation |
| `not available` | Cluster not in Available state at time of reconcile |
| Cluster name absent entirely | Operator did not reconcile this cluster at all |
| Permission / RBAC errors | Operator can't create resources in the cluster namespace |

---

## Step 4 — Check the Cluster Namespace on the Hub

```bash
# Does the cluster namespace exist?
oc get namespace $CLUSTER

# Any events in the cluster namespace that suggest a problem?
oc get events -n $CLUSTER --sort-by=.lastTimestamp | tail -20
```

If the namespace is missing or in a bad state, the operator cannot create the `ManagedClusterAddon` CR within it.

---

## Step 5 — Check Cluster Labels

Some versions of the MCO operator gate on `vendor` or platform labels. Clusters missing expected labels may be silently skipped. *This step is unverified — not exercised in the session that produced this guide. Treat as a candidate cause if all other steps are clear.*

```bash
oc get managedcluster $CLUSTER \
  -o jsonpath='{.metadata.labels}' | jq

# Expected labels for an OCP spoke:
# vendor: OpenShift
# cloud: <provider>
# openshiftVersion: <version>
```

---

## Step 6 — Recovery: Restart the Operator

If the cluster is `Available`, has no skip annotation, and the operator logs show no activity for it, the most likely explanation is that the operator failed to reconcile this cluster at initial import (possibly because the firewall was blocking the spoke's connection at that moment) and did not retry.

Restarting the operator triggers a full reconcile across all managed clusters:

```bash
oc rollout restart deploy/multicluster-observability-operator \
  -n open-cluster-management

oc rollout status deploy/multicluster-observability-operator \
  -n open-cluster-management
```

Then watch for the addon to appear:

```bash
watch -n 15 "oc get managedclusteraddon -n $CLUSTER"
```

Within a few minutes you should see `observability-controller` created. The `ManifestWork` will follow shortly after.

---

## Step 7 — If the Addon Exists but Metrics Are Not Flowing

This is a data plane problem, not an addon deployment problem. The addon deployed but the `metrics-collector` on the spoke cannot push to the hub.

**Network requirements — spoke egress to hub:**

| Source | Destination | Port | Purpose |
|---|---|---|---|
| Spoke `metrics-collector` | Hub `observatorium-api` Route | 443 | Remote write metrics |
| Spoke `metrics-collector` | Hub `alertmanager` Route | 443 | Alert forwarding |

```bash
CLUSTER=<your-cluster-name>  # set if not already set from Step 1

# Get hub route hostnames — these are what the firewall team needs
oc get route -n open-cluster-management-observability

# Check metrics-collector logs on the spoke for connection errors
oc logs -n open-cluster-management-addon-observability \
  "$(oc get pod -n open-cluster-management-addon-observability \
    -l app=metrics-collector -o name)" | tail -50

# Common errors:
# "dial tcp <ip>:443: i/o timeout"       → firewall blocking egress
# "x509: certificate signed by unknown"  → TLS inspection in the path
# "connection refused"                   → route not reachable
```

Check the `ManagedClusterAddon` conditions:

```bash
oc get managedclusteraddon -n $CLUSTER observability-controller -o yaml
# Look for: Available: False, Degraded: True
```

---

## Quick Reference

| What to check | Where | Command |
|---|---|---|
| Addon CR | Hub, cluster namespace | `oc get managedclusteraddon -n $CLUSTER` |
| ManifestWork | Hub, cluster namespace | `oc get manifestwork -n $CLUSTER \| grep observ` |
| Operator logs | Hub, `open-cluster-management` | `oc logs deploy/multicluster-observability-operator -n open-cluster-management` |
| Cluster conditions | Hub | `oc get managedcluster $CLUSTER -o yaml` |
| Spoke addon pods | Spoke | `oc get pods -n open-cluster-management-addon-observability` |
| Hub data plane routes | Hub | `oc get route -n open-cluster-management-observability` |

---

## Reference Documentation

- [ACM 2.15 — Observability](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html/observability/observing-environments-intro)
- [ACM 2.15 — Enabling the Observability service](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html/observability/observing-environments-intro#enabling-observability-service)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

# Troubleshooting: MCH Stuck in Pending / Upgrading State

**Symptom:** After initiating a hub cluster upgrade, the `MultiClusterHub` resource stays in `Updating`, `Pending`, or `Installing` status indefinitely — beyond the expected window of up to 10 minutes.

```bash
oc get mch -n open-cluster-management
# NAME               STATUS     AGE
# multiclusterhub    Updating   47m   ← stuck
```

---

## How MCH Upgrade Works

When you change the OLM subscription channel (e.g., `release-2.13` → `release-2.15`):

1. OLM creates a new `InstallPlan` and updates the `ClusterServiceVersion` (CSV)
2. The `multiclusterhub-operator` picks up the new CSV and begins reconciling the `MultiClusterHub` resource
3. ACM automatically upgrades the **multicluster engine operator** (MCE) to the required version — do not upgrade MCE separately
4. The hub operator reconciles all sub-components (registration, work, addon-manager, search, observability, etc.)
5. MCH status transitions: `Updating` → `Running`

**Official time expectation:** Up to **10 minutes** per the ACM 2.15 documentation. Anything beyond ~15–20 minutes warrants investigation.

**Important constraints from ACM 2.15 docs:**
- Upgrades are only supported from the **immediate previous version** (no channel skipping except EUS-to-EUS)
- EUS skip-level: `2.13` (EUS) → `2.15` (EUS) is supported; other skips are not
- Do **not** upgrade multicluster engine operator independently — it must follow ACM
- Downgrade is **not** supported

**Reference:** [Red Hat ACM 2.15 — Upgrading your hub cluster](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html/install/installing#upgrading-hub)

---

## Step 1 — Establish Baseline Status

Run all of these before diving into any specific scenario.

```bash
# MCH current and desired version — are they mismatched?
oc get mch multiclusterhub -n open-cluster-management \
  -o jsonpath='current: {.status.currentVersion}  desired: {.status.desiredVersion}{"\n"}'

# Full MCH status conditions
oc get mch multiclusterhub -n open-cluster-management \
  -o jsonpath='{range .status.conditions[*]}{.type}: {.reason} — {.message}{"\n"}{end}'

# Which sub-components are not yet Available?
oc get mch multiclusterhub -n open-cluster-management \
  -o jsonpath='{range .status.components[*]}{.name}: {.status} — {.reason}{"\n"}{end}' \
  | grep -v "Available"

# CSV status — is the new version installed or still installing?
oc get csv -n open-cluster-management | grep advanced-cluster-management

# InstallPlan — is there one waiting for approval?
oc get installplan -n open-cluster-management

# MCE — did it upgrade as expected?
oc get multiclusterengine
oc get csv -n multicluster-engine | grep multicluster-engine
```

The component list from `.status.components` is the most useful signal — it shows exactly which sub-system is blocking the transition to `Running`.

---

## Step 2 — OLM Layer Checks

MCH upgrade depends on OLM completing the CSV installation first. If OLM is stuck, the hub operator never gets to reconcile.

### 2a. InstallPlan approval (Manual approval subscriptions)

```bash
oc get installplan -n open-cluster-management \
  -o custom-columns='NAME:.metadata.name,APPROVED:.spec.approved,PHASE:.status.phase,CSV:.spec.clusterServiceVersionNames[*]'
```

If `APPROVED` is `false` and `PHASE` is `RequiresApproval`:

```bash
# Approve the pending InstallPlan
INSTALLPLAN=$(oc get installplan -n open-cluster-management \
  -o jsonpath='{.items[?(@.spec.approved==false)].metadata.name}')

echo "Approving: $INSTALLPLAN"
oc patch installplan $INSTALLPLAN -n open-cluster-management \
  --type=merge -p '{"spec":{"approved":true}}'
```

### 2b. CSV stuck in Installing or Failed

```bash
oc get csv -n open-cluster-management -o wide

# Detailed status on the specific CSV
CSV_NAME=$(oc get csv -n open-cluster-management \
  -o jsonpath='{.items[?(@.spec.displayName=="Advanced Cluster Management for Kubernetes")].metadata.name}')

oc describe csv $CSV_NAME -n open-cluster-management | grep -A 10 "Message\|Reason\|Phase"
```

If the CSV shows `Failed` or `Degraded`, check the operator pod:

```bash
oc get pods -n open-cluster-management | grep multiclusterhub-operator
oc logs -n open-cluster-management deploy/multiclusterhub-operator --tail=100
```

### 2c. OLM operatorcondition — upgrade gate

OLM uses `OperatorCondition` to prevent skipping versions:

```bash
# Check if upgradeable is false (version skip guard)
oc get operatorcondition -n open-cluster-management \
  -o jsonpath='{range .items[*]}{.metadata.name}: {range .spec.conditions[*]}{.type}={.status} {end}{"\n"}{end}'
```

If `Upgradeable=False`, the operator is blocking the upgrade because a prerequisite version was not completed. You cannot skip channels — you must go through each one.

---

## Step 3 — Hub Operator Logs

```bash
# Primary operator — most diagnostic value
oc logs -n open-cluster-management \
  deploy/multiclusterhub-operator \
  --tail=200 | grep -i "error\|fail\|reconcil\|component\|degrad"

# Stream for live observation
oc logs -n open-cluster-management \
  deploy/multiclusterhub-operator -f
```

Look for:
- Component name + error (shows which sub-system is failing)
- `reconcile error` messages
- Image pull or registry errors
- Timeout or deadline exceeded messages

---

## Step 4 — Sub-Component Checks

Once you identify the failing component from `status.components`, drill into it.

### 4a. Pods not starting

```bash
# All pods in hub namespaces — find non-Running ones
oc get pods -n open-cluster-management | grep -v "Running\|Completed"
oc get pods -n open-cluster-management-hub | grep -v "Running\|Completed"
oc get pods -n multicluster-engine | grep -v "Running\|Completed"

# Describe a stuck pod
oc describe pod <pod-name> -n open-cluster-management | tail -30

# Check all pod events across hub namespaces
oc get events -n open-cluster-management \
  --sort-by=.lastTimestamp | tail -20
oc get events -n multicluster-engine \
  --sort-by=.lastTimestamp | tail -20
```

### 4b. Image pull failures

Image pull failures are the most common cause in **disconnected environments** or when a new image tag is not mirrored.

```bash
# Look for ImagePullBackOff across hub namespaces
oc get pods -A | grep -E "open-cluster-management|multicluster-engine" \
  | grep -i "pull\|backoff\|image"

# Events showing pull failures
oc get events -n open-cluster-management \
  --sort-by=.lastTimestamp \
  | grep -i "pull\|image\|registry\|mirror"

# Which image is failing?
oc describe pod <failing-pod> -n open-cluster-management \
  | grep -A 5 "Failed\|Error\|Back-off"
```

Fix: ensure your mirror registry has the images for the new ACM version. For `oc-mirror` or `opm` catalog mirroring, re-run your mirroring procedure targeting the new version before changing the OLM channel.

### 4c. MCE sub-operator stuck

ACM upgrades MCE automatically — if MCE is stuck, MCH stays stuck.

```bash
# MCE status
oc get multiclusterengine multiclusterengine -o yaml \
  | grep -A 20 "status:"

# MCE conditions
oc get multiclusterengine multiclusterengine \
  -o jsonpath='{range .status.conditions[*]}{.type}: {.reason} — {.message}{"\n"}{end}'

# MCE CSV
oc get csv -n multicluster-engine | grep multicluster-engine

# MCE operator pod logs
oc logs -n multicluster-engine \
  deploy/multicluster-engine-operator --tail=100
```

**Do not manually upgrade or patch MCE** — per official docs, upgrading MCE separately from ACM causes issues. Let the MCH operator drive it.

### 4d. Webhook blocking reconciliation

If a validating or mutating webhook pod is down during upgrade, API calls during reconciliation will fail, causing the hub operator to loop on errors.

```bash
# Webhook configurations pointing to ACM/MCE
oc get validatingwebhookconfigurations \
  | grep -i "acm\|ocm\|multicluster\|cluster-manager"
oc get mutatingwebhookconfigurations \
  | grep -i "acm\|ocm\|multicluster\|cluster-manager"

# Are the backing service pods healthy?
oc get pods -n open-cluster-management \
  | grep -i "webhook"
oc get pods -n open-cluster-management-hub \
  | grep -i "webhook"
```

If a webhook service endpoint is down:

```bash
# Temporarily patch the webhook to fail-open while upgrade completes
# Use with caution — only as a last resort to unblock upgrade
oc patch validatingwebhookconfiguration <webhook-name> \
  --type=json \
  -p '[{"op":"replace","path":"/webhooks/0/failurePolicy","value":"Ignore"}]'

# Restore after upgrade completes
oc patch validatingwebhookconfiguration <webhook-name> \
  --type=json \
  -p '[{"op":"replace","path":"/webhooks/0/failurePolicy","value":"Fail"}]'
```

### 4e. CRD conflicts

Stale CRDs from a previous version or a partial uninstall can block reconciliation.

```bash
# List all ACM/MCE CRDs and their versions
oc get crds | grep -E "open-cluster-management|multicluster"

# Check if any CRDs are in a non-established state
oc get crds -o jsonpath='{range .items[*]}{.metadata.name}: {range .status.conditions[*]}{.type}={.status} {end}{"\n"}{end}' \
  | grep "open-cluster-management\|multicluster" \
  | grep -v "Established=True"
```

---

## Step 5 — Disconnected Environment Checks

These apply when the hub cluster does not have internet access.

### 5a. Missing mce-subscription-spec annotation

This is the most common disconnected upgrade blocker. When upgrading in a disconnected environment, ACM tries to create a subscription for MCE using the same catalog source as ACM. If the catalog source name changed (e.g., you created a new mirrored catalog for the new version), the annotation must be updated first.

```bash
# Check current annotation
oc get mch multiclusterhub -n open-cluster-management \
  -o jsonpath='{.metadata.annotations.installer\.open-cluster-management\.io/mce-subscription-spec}{"\n"}'

# What CatalogSources exist in the marketplace?
oc get catalogsource -n openshift-marketplace

# The annotation should point to your mirror catalog source
# Add or update if missing/wrong:
oc patch mch multiclusterhub -n open-cluster-management \
  --type=merge -p '{
    "metadata": {
      "annotations": {
        "installer.open-cluster-management.io/mce-subscription-spec":
          "{\"source\": \"<your-catalogsource-name>\"}"
      }
    }
  }'
```

Per official docs:
> If you begin an upgrade before you add the annotation, the upgrade begins but stalls when the operator attempts to install a subscription to `multicluster-engine` in the background. The status of the `MultiClusterHub` resource continues to display `upgrading` during this time. To resolve this issue, run `oc edit` to add the `mce-subscription-spec` annotation.

### 5b. Mirror catalog not updated for the new version

```bash
# Verify the target ACM version is available in your catalog
oc get packagemanifest advanced-cluster-management \
  -n openshift-marketplace -o yaml | grep -A 5 "channels:"

# Verify MCE package is also present (required since ACM 2.x)
oc get packagemanifest multicluster-engine \
  -n openshift-marketplace

# CatalogSource pod healthy?
oc get pods -n openshift-marketplace | grep -i catalog
oc get catalogsource -n openshift-marketplace -o wide
```

If the catalog pod is failing, your registry may not have the new index image. Re-mirror and restart the CatalogSource pod:

```bash
oc delete pod -n openshift-marketplace \
  -l olm.catalogSource=<your-catalogsource-name>
```

### 5c. ImageContentSourcePolicy / ImageDigestMirrorSet not covering new images

```bash
# Check ICSP / IDMS for ACM image mappings
oc get imagecontentsourcepolicy 2>/dev/null || \
  oc get imagedigestmirrorset 2>/dev/null

# Pull diagnostics on a failing pod
oc describe pod <failing-pod> -n open-cluster-management \
  | grep -E "image|mirror|registry|pull" -i
```

---

## Step 6 — Resource Constraints

If hub nodes are under pressure, component pods may not schedule.

```bash
# Node pressure
oc get nodes -o wide
oc describe nodes | grep -A 5 "Conditions:\|Allocatable:\|Allocated"

# Pending pods — why aren't they scheduling?
oc get pods -A | grep Pending \
  | grep -E "open-cluster-management|multicluster-engine"

oc describe pod <pending-pod> -n open-cluster-management \
  | grep -A 10 "Events:"
```

Common scheduling blockers: insufficient CPU/memory, taint mismatches, node selector constraints. If you're using infrastructure nodes for ACM components, verify the tolerations on the MCH spec:

```bash
oc get mch multiclusterhub -n open-cluster-management \
  -o jsonpath='{.spec.nodeSelector}  {.spec.tolerations}{"\n"}'
```

---

## Step 7 — Force Reconciliation

If the operator appears healthy but MCH is not progressing, nudging the operator can help.

```bash
# Restart the hub operator to force a fresh reconciliation cycle
oc rollout restart deploy/multiclusterhub-operator \
  -n open-cluster-management

oc rollout status deploy/multiclusterhub-operator \
  -n open-cluster-management

# Watch MCH status after restart
watch -n 15 "oc get mch -n open-cluster-management && echo && \
  oc get mch multiclusterhub -n open-cluster-management \
  -o jsonpath='{range .status.components[*]}{.name}: {.status}{\"\\n\"}{end}' \
  | grep -v Available"
```

---

## Step 8 — Validation

After the upgrade completes:

```bash
# MCH should show Running
oc get mch -n open-cluster-management

# currentVersion should match desiredVersion
oc get mch multiclusterhub -n open-cluster-management \
  -o jsonpath='current: {.status.currentVersion}  desired: {.status.desiredVersion}{"\n"}'

# MCE compliance — mceVersionCompliance isCompliant should be true
oc get mch multiclusterhub -n open-cluster-management \
  -o jsonpath='{range .status.conditions[*]}{.type}: {.status}{"\n"}{end}' \
  | grep -i "mce\|compli"

# All hub components Available
oc get mch multiclusterhub -n open-cluster-management \
  -o jsonpath='{range .status.components[*]}{.name}: {.status}{"\n"}{end}'

# CSV at expected version
oc get csv -n open-cluster-management | grep advanced-cluster-management

# All hub pods healthy
oc get pods -n open-cluster-management | grep -v "Running\|Completed"
oc get pods -n open-cluster-management-hub | grep -v "Running\|Completed"
oc get pods -n multicluster-engine | grep -v "Running\|Completed"
```

After hub is confirmed `Running`, managed clusters showing `Unknown` should self-recover within a few minutes. See [managed-cluster-lease-not-updated.md](./managed-cluster-lease-not-updated.md) if they do not.

---

## Diagnostic Decision Tree

```
MCH stuck in Updating/Pending
│
├── Check: Is CSV installed?
│   ├── No / Installing → Check OLM InstallPlan approval (Step 2a)
│   │                     Check CatalogSource health (Step 5b)
│   └── Yes (Succeeded) → proceed
│
├── Check: status.components — which component is not Available?
│   ├── MCE → Check MCE status separately (Step 4c)
│   ├── webhook → Check webhook pods (Step 4d)
│   └── Any → Check pod health in that component's namespace (Step 4a/4b)
│
├── Disconnected environment?
│   └── Yes → Check mce-subscription-spec annotation (Step 5a)
│             Check mirror catalog coverage (Step 5b)
│
├── Operator logs showing errors? (Step 3)
│   ├── Image pull → Mirror/ICSP issue (Step 4b, 5c)
│   ├── Webhook → Fail-open workaround (Step 4d)
│   └── CRD conflict → CRD check (Step 4e)
│
└── No obvious error → Force reconciliation (Step 7)
```

---

## Quick Reference — Key Commands

```bash
# One-liner status summary
oc get mch multiclusterhub -n open-cluster-management \
  -o jsonpath='Status: {.status.phase}  Current: {.status.currentVersion}  Desired: {.status.desiredVersion}{"\n"}'

# Unhealthy components only
oc get mch multiclusterhub -n open-cluster-management \
  -o jsonpath='{range .status.components[*]}{.name}: {.status} — {.reason}{"\n"}{end}' \
  | grep -v ": Available"

# All non-running pods across hub namespaces
oc get pods -n open-cluster-management,open-cluster-management-hub,multicluster-engine \
  | grep -v "Running\|Completed\|NAME"
```

---

## Reference Documentation

- [ACM 2.15 — Upgrading your hub cluster](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html/install/installing#upgrading-hub)
- [ACM 2.15 — Upgrading in disconnected environments](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html/install/installing#upgrading-disconnected)
- [ACM 2.15 — MCH advanced configuration](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.15/html/install/installing#advanced-config-hub)
- [ACM Support Matrix](https://access.redhat.com/articles/7133095)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

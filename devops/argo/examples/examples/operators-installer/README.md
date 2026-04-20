# Declarative OpenShift Operator Management with ArgoCD and operators-installer

This example demonstrates how to manage OpenShift operator installations declaratively via
ArgoCD, with strict version control over which CSV is installed. Operator versions are
pinned in Git, and the only way to upgrade is to change the `csv:` value and merge a PR.

**Upstream chart:** [redhat-cop/helm-charts — operators-installer](https://github.com/redhat-cop/helm-charts/tree/main/charts/operators-installer)

---

## How It Works

The `operators-installer` chart wraps OLM's `Subscription` and `InstallPlan` APIs. Setting
`installPlanApproval: Manual` with an explicit `csv:` value means OLM will never
auto-upgrade. A post-install Job (run by the chart) approves only the InstallPlan that
matches the pinned CSV. ArgoCD drift detection ensures the cluster stays synchronized with
Git.

```
Git (csv: v1.12.1)
       │
       ▼
ArgoCD Application  ──source 0──▶  operators-installer chart (from Helm repo)
                    ──source 1──▶  catalog/<operator>/values.yaml (from this repo)
                                              │
                                              ▼
                                   OLM Subscription (Manual)
                                              │
                                   InstallPlan approval Job
                                              │
                                              ▼
                                   Operator installed at v1.12.1
```

When you change `csv:` in Git and merge, ArgoCD detects the Application is out-of-sync,
re-syncs, and the chart approves the InstallPlan for exactly the new version.

---

## Directory Structure

```
argo/examples/examples/operators-installer/
├── README.md                                      # this file
├── argocd/
│   ├── operators-root-app.yaml                    # bootstrap: oc apply once
│   └── argocd-cm-subscription-health.yaml         # ArgoCD Subscription health check patch
├── charts/
│   └── operators-app-of-apps/                     # App-of-Apps Helm chart
│       ├── Chart.yaml
│       ├── templates/
│       │   └── operator-application.yaml          # generates one Application per operator
│       └── values.yaml                            # operator list + destination namespaces
└── catalog/
    ├── openshift-gitops/
    │   └── values.yaml   # automated upgrade chain example
    ├── advanced-cluster-management/
    │   └── values.yaml   # staged upgrade chain example
    └── cert-manager/
        └── values.yaml   # direct install example
```

---

## Prerequisites

- OCP 4.16–4.18 with Red Hat OpenShift GitOps installed (OLM v0, Subscription-based)
- ArgoCD (OpenShift GitOps) with cluster-admin or a project granting:
  - permission to create `Namespace`, `OperatorGroup`, `Subscription` resources
  - permission to create `Job`, `ServiceAccount`, `ClusterRoleBinding` resources
  - permission to `get` and `patch` `InstallPlan` resources
- The `registry.redhat.io` pull secret must be available in each operator namespace
  (the approval Job image is pulled from there)

### Required: ArgoCD Subscription Health Check

Before bootstrapping, apply the ArgoCD Subscription health check patch. Without it,
ArgoCD will incorrectly mark operator Applications as `Progressing` whenever OLM creates
a pending InstallPlan for a newer version (even if you do not want to upgrade).

See [argocd/argocd-cm-subscription-health.yaml](argocd/argocd-cm-subscription-health.yaml)
for instructions — apply before bootstrapping the root app.

---

## Bootstrap

This is the **only `oc` command you run manually**. Everything else is managed by ArgoCD.

```bash
# 1. Clone the repo and update argocd/operators-root-app.yaml with your repo URL
# 2. Apply the Subscription health check (see Prerequisites above)
# 3. Apply the root app
oc apply -f argo/examples/examples/operators-installer/argocd/operators-root-app.yaml \
  -n openshift-gitops
```

After applying, confirm the `operators-root-app` syncs in the ArgoCD UI. It will
create one child Application per enabled operator in `charts/operators-app-of-apps/values.yaml`.

---

## Adding a New Operator

1. **Create the catalog entry:**

   ```bash
   mkdir -p catalog/<operator-name>
   # Copy an existing values.yaml and edit: channel, csv, namespace, operatorGroups
   cp catalog/cert-manager/values.yaml catalog/<operator-name>/values.yaml
   ```

2. **Register in the orchestrator:**

   Edit `charts/operators-app-of-apps/values.yaml` and add an entry:

   ```yaml
   operators:
     - name: <operator-name>
       enabled: true
       destinationNamespace: <operator-namespace>
   ```

3. **Commit and push via PR.** ArgoCD will create a new Application for the operator
   and the chart will approve the InstallPlan.

---

## Upgrade Workflow

OLM v0 defines a directed upgrade graph per channel. An operator may require stepping
through intermediate versions (e.g. `v2.10 → v2.11 → v2.12`) — jumping directly to the
target is only possible if OLM's channel graph has a direct edge. Two strategies handle this:

### Choosing a Strategy

```
Does each intermediate version need human validation
(smoke tests, schema migration sign-off, production gate)?
  │
  ├─ NO  → Automated chain: automaticIntermediateManualUpgrades: true
  │         Set csv to the final target. One PR, one ArgoCD sync.
  │         The chart discovers OLM's upgrade graph and approves each hop in sequence.
  │
  └─ YES → Staged chain: automaticIntermediateManualUpgrades: false
            Set csv to each intermediate version one PR at a time.
            Validate the cluster after each hop before opening the next PR.
            Git history becomes the audit log.
```

### Automated Chain

Set `csv` to the final destination. The chart steps through OLM's resolved upgrade graph
automatically in a single ArgoCD sync. Set generous timeouts — a 4-hop chain takes 4x
the time of a single install.

See [catalog/openshift-gitops/values.yaml](catalog/openshift-gitops/values.yaml) for
a full example.

**To upgrade:** change `csv:`, open PR, merge. Done.

### Staged Chain

Set `csv` to the **next hop only**, not the final target. The `upgradeChain:` comment
block (a convention in this example) documents the full required sequence and tracks
installation history. `automaticIntermediateManualUpgrades: false` ensures the chart
never auto-advances beyond the pinned version.

See [catalog/advanced-cluster-management/values.yaml](catalog/advanced-cluster-management/values.yaml)
for a full example.

**To advance one hop:**
1. Update `csv:` to the next version in the `upgradeChain` sequence
2. Update the `upgradeChain` comment: add the installation date and git SHA for the
   current entry, and mark the next as current
3. Open PR → get approval → merge
4. After ArgoCD syncs, validate the cluster (CRD health, operand status, smoke tests)
5. Repeat from step 1 for the next hop

The git log of `csv:` changes across PRs is the complete, auditable upgrade history.

### Finding Available CSVs

```bash
# List all CSVs in a channel
oc get packagemanifest <operator-name> -n openshift-marketplace \
  -o jsonpath='{.status.channels[?(@.name=="<channel>")].entries[*].name}' \
  | tr ' ' '\n'

# Show the full upgrade graph for a channel
oc get packagemanifest <operator-name> -n openshift-marketplace \
  -o jsonpath='{.status.channels[?(@.name=="<channel>")].entries[*]}' \
  | python3 -m json.tool
```

---

## OLM v0 Constraints (OCP 4.16–4.18)

### One Operator Per Namespace

When multiple operators share a namespace (including `openshift-operators`), OLM v0
**merges their pending InstallPlans** into a single object. This makes independent
version pinning impossible — approving one operator's plan inadvertently approves
another's.

**Solution:** Each managed operator gets a dedicated namespace. Every catalog entry in
this example uses a unique `operatorGroups[].name` with `createNamespace: true`. The
`openshift-operators` namespace is not used for any operator managed by this system.

### OLM v1 / ClusterExtension

OLM v1 (`ClusterExtension` API) is available as TechPreview in OCP 4.16–4.17 and more
stable in 4.18. The `operators-installer` chart targets OLM v0 (`Subscription`/`InstallPlan`)
and is **not compatible** with `ClusterExtension`. Most Red Hat operators on these OCP
versions still deploy via OLM v0.

Do not use this pattern to manage operators that have been migrated to OLM v1
`ClusterExtension` management. Mixing the two in the same namespace is not supported.

### Automatic Upgrades Still Happen for Unmanaged Operators

This system only controls operators whose `Subscription` is created by this chart.
Any operator installed via `Automatic` installPlanApproval (including any managed by
the default Red Hat-provided Subscriptions) is outside this system's control.

---

## Disconnected Environments

The approval Job image (`installPlanApproverAndVerifyJobsImage`) must be reachable from
the cluster. In disconnected environments:

**Option A — Local Python index:** Set `pythonIndexURL` and `pythonExtraIndexURL` to an
internal mirror serving `openshift-client` and `semver==2.13.0`.

**Option B — Pre-baked image:** Build a custom image on top of `ose-cli` that includes
`openshift-client` and `semver==2.13.0`, mirror it internally, set
`installPlanApproverAndVerifyJobsImage` to the internal reference, and set
`installRequiredPythonLibraries: false`.

---

## Troubleshooting

### Application is stuck in Progressing

1. Check if the Subscription health check is applied:
   ```bash
   oc get cm argocd-cm -n openshift-gitops \
     -o jsonpath='{.data.resource\.customizations\.health\.operators\.coreos\.com_Subscription}'
   ```
2. If empty, apply [argocd/argocd-cm-subscription-health.yaml](argocd/argocd-cm-subscription-health.yaml).

### InstallPlan approval Job fails

```bash
# Find the approval Job in the operator namespace
oc get jobs -n <operator-namespace>
oc logs job/<job-name> -n <operator-namespace>
```

Common causes:
- The `csv:` value does not exist in the channel (wrong name or not yet available)
- OLM requires an intermediate upgrade but `automaticIntermediateManualUpgrades` is `false`
- The approval Job image cannot be pulled (registry auth or disconnected environment)
- `installPlanApproverActiveDeadlineSeconds` too low for the cluster speed

### Operator is stuck at an intermediate version

If `automaticIntermediateManualUpgrades: true` and the chain has many hops, increase
both deadline fields significantly:

```yaml
installPlanApproverActiveDeadlineSeconds: 3600   # 1 hour
installPlanVerifierActiveDeadlineSeconds: 3600
```

### ArgoCD says the Application is OutOfSync after successful install

This typically means the Subscription's `status.currentCSV` does not match the `spec.startingCSV`
rendered by the chart. ArgoCD may be diffing live Subscription status fields. Add an
ignore-differences rule to the Application or use `RespectIgnoreDifferences=true` in
syncOptions (already set in this example's chart template).

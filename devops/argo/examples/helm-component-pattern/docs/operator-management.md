# Operator management

This document covers how to manage OLM operator installation and configuration in the fleet using the `components/` structure and the `operators-installer` Helm chart from [redhat-cop/helm-charts](https://github.com/redhat-cop/helm-charts/tree/main/charts/operators-installer).

---

## The operator + instance split

Complex operators have two distinct lifecycle concerns that should be managed separately:

1. **Operator installation** — installing the operator via OLM (Subscription, OperatorGroup, InstallPlan approval). This is idempotent, rarely changes, and requires cluster-admin access.
2. **Instance configuration** — creating the operator's primary CR (e.g. `NMState`, `HyperConverged`, `Logging`). This changes more often (topology tuning, resource limits) and may require waiting for the operator to be ready.

Mixing both in a single component chart creates ordering problems: the instance CR fails to apply because the operator's CRDs aren't registered yet. Splitting them into separate ArgoCD Applications with `syncWave` annotations solves this cleanly.

### Directory structure

```
components/
  nmstate/
    operator/         ← OLM installation via operators-installer
      Chart.yaml      ← declares operators-installer as a dependency
      values.yaml     ← static config (source, sourceNamespace, operatorGroups)
    instance/         ← NMState CR
      Chart.yaml
      values.yaml
      templates/
        nmstate.yaml  ← NMState CR; reads .Values.cluster.* for cluster identity
```

### App entries in groups/all/values.yaml

```yaml
component-all:
  apps:
    nmstate-operator:
      enabled: true
      path: components/nmstate/operator   # explicit path — not derived from app name
      syncWave: "0"                        # install operator first
      operators-installer:
        operators:
          - name: kubernetes-nmstate-operator
            source: redhat-operators
            sourceNamespace: openshift-marketplace
            namespace: openshift-nmstate
            channel: stable
            installPlanApproval: Automatic
            csv: ""
        operatorGroups:
          - name: openshift-nmstate
            createNamespace: true
            targetOwnNamespace: true

    nmstate-instance:
      enabled: true
      path: components/nmstate/instance
      syncWave: "5"                        # apply instance CR after operator CRDs register
      namespace: openshift-nmstate
```

The `path` field overrides the default `components/<appName>` path resolution in `hub-clusters`. Without it, the app named `nmstate-operator` would look for `components/nmstate-operator/` which doesn't exist.

The `syncWave` field sets `argocd.argoproj.io/sync-wave` on the generated Application. Wave `0` runs before wave `5` — the NMState CR won't be applied until the operator Application has synced and the CRDs are registered.

---

## operators-installer

[`redhat-cop/helm-charts/charts/operators-installer`](https://github.com/redhat-cop/helm-charts/tree/main/charts/operators-installer) is the recommended approach for OLM operator installation at fleet scale. It addresses problems that raw `Subscription` YAML does not:

| Concern | Raw Subscription YAML | operators-installer |
|---|---|---|
| InstallPlan approval (Manual) | Manual kubectl step or separate automation | Built-in approver Job — runs at install/upgrade, approves the correct InstallPlan version |
| Version pinning | Set `startingCSV` on Subscription — not enforced on upgrades | `csv` field checked by verifier Job; upgrade blocked if wrong version |
| Upgrade verification | None — you discover failures via degraded cluster operators | Verifier Job confirms expected CSV is running before Helm release completes |
| Incremental upgrades | Not supported — OLM may skip versions | `manual incremental upgrades` support (see chart changelog) |
| Helm release lifecycle | Subscription resource exists; Helm doesn't know if operator actually installed | Helm install/upgrade waits for operator to be ready via Jobs |
| Private registry | Requires manual configuration | `installPlanApproverAndVerifyJobsImagePullSecret` field |
| Disconnected environments | Requires mirrored images separately | `installRequiredPythonLibraries: false` + custom image path |

### How it works

operators-installer creates:
1. `Namespace` (if `createNamespace: true`)
2. `OperatorGroup`
3. `Subscription` (which triggers OLM to create an `InstallPlan`)
4. A **approver Job** (if `installPlanApproval: Manual`) — approves the specific `InstallPlan` matching `csv`
5. A **verifier Job** — waits for the CSV to reach `Succeeded` before the Helm release completes

When `approveManualInstallPlanViaHook: true` (the default), the approver Job runs as a Helm post-install/post-upgrade hook and is cleaned up after completion.

### Version pinning workflow

To pin a cluster to a specific operator version:

1. Set `installPlanApproval: Manual` so OLM does not auto-upgrade.
2. Set `csv: "kubernetes-nmstate-operator.4.16.2"` — the approver Job approves only this specific CSV.
3. To upgrade: update `csv` in the cluster's values file and merge a PR. The hub Action re-renders the hub Application; ArgoCD syncs; the approver Job approves the new InstallPlan.

**In cluster values:**
```yaml
# clusters/site-dc1/values.yaml
component-site-dc1:
  apps:
    nmstate-operator:
      # Replaces the full operators-installer block from component-all.
      # Repeat all required fields — the operators: list does not deep-merge.
      operators-installer:
        operators:
          - name: kubernetes-nmstate-operator
            source: redhat-operators
            sourceNamespace: openshift-marketplace
            namespace: openshift-nmstate
            channel: stable-4.16
            installPlanApproval: Manual
            csv: "kubernetes-nmstate-operator.4.16.2"
        operatorGroups:
          - name: openshift-nmstate
            createNamespace: true
            targetOwnNamespace: true
```

> **List merge limitation:** The `operators:` key is a YAML list. `mustMergeOverwrite` cannot merge list items — it replaces the entire list when any layer sets the key. When overriding at the cluster or group level, you must repeat the complete `operators:` and `operatorGroups:` blocks. See [architecture-opinions.md Opinion #5](./architecture-opinions.md) for the full explanation and the `extra*/concat` alternative for additive list use cases.

### Disconnected environments

In disconnected environments, the approver/verifier Jobs need:

```yaml
operators-installer:
  installRequiredPythonLibraries: false
  installPlanApproverAndVerifyJobsImage: "registry.internal.example.com/ose-cli-python:v4.16"
```

The custom image must include `oc`, `openshift-client` (Python), and `semver==2.13.0`. Mirror it to your local registry alongside the OCP release images.

---

## The `path` field

The `path` field on an app entry overrides the default path resolution in `hub-clusters`:

| Setting | Resolved path |
|---|---|
| No `path` field — `nmstate` | `components/nmstate` |
| `path: components/nmstate/operator` | `components/nmstate/operator` |
| `path: components/nmstate/instance` | `components/nmstate/instance` |
| `path: platform/logging/operator` | `platform/logging/operator` |

Use this for any case where the app name doesn't map 1:1 to the component directory — operator/instance splits, versioned component directories, or components shared across multiple repos.

---

## The `syncWave` field

`syncWave` sets `argocd.argoproj.io/sync-wave` on the generated Application. ArgoCD applies Applications in ascending wave order within a sync operation.

**Recommended wave assignments for operator + instance:**

| Wave | What runs |
|---|---|
| `"0"` | Operator installation (Subscription, OperatorGroup, InstallPlan approval) |
| `"5"` | Operator instance CR (NMState, HyperConverged, Logging, etc.) |
| `"10"` | Resources that depend on the operator's CRDs being available and the operator running |

ArgoCD waits for healthy status within each wave before advancing to the next. The gap between waves (`0` → `5`) gives the operator time to register its CRDs and reach a running state.

**On health check requirements:** For wave ordering to work correctly, the operator Application must reach `Healthy` status before wave `5` runs. ArgoCD determines Application health from the resources it manages — a `CSV` in `Succeeded` state will typically result in a Healthy Application. If the operator Application shows `Healthy: False` after the operator installs, check the CSV status and any failing resources.

---

## Flat vs split: when to use each

| Pattern | When to use |
|---|---|
| **Flat** (single app for the operator) | Simple operators with no custom CR, or where the operator manages itself after installation (cert-manager, sealed-secrets) |
| **Operator + instance split** | Operators that require a primary CR to activate (NMState, ODF, Logging, Virt, SR-IOV, etc.) |
| **Multi-instance** | Operators that manage multiple independent CRs (e.g. multiple `ClusterLogging` instances for different retention policies) |

---

*AI-assisted content. See [AI-DISCLOSURE.md](../../../../../AI-DISCLOSURE.md) for review status details.*

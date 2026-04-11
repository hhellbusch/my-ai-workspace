# Groups

Groups are the middle layers of the value cascade. They sit between app
defaults (lowest priority) and cluster-specific overrides (highest priority),
and they serve two purposes:

1. **Setting values** — Every group's `values.yaml` contributes keys to the
   merged `.Values` that Helm sees when rendering app charts.
2. **Controlling which apps deploy where** — Group labels on clusters drive
   the ApplicationSet `clusters` generator, determining which apps deploy to
   which clusters.

> **AI Disclosure:** This document was created with AI assistance.

---

## Table of Contents

- [How Groups Control App Deployment](#how-groups-control-app-deployment)
- [How Groups Set Values](#how-groups-set-values)
- [Group Types](#group-types)
- [What Each Group Sets (Reference)](#what-each-group-sets-reference)
- [The Value Cascade](#the-value-cascade)
- [Worked Example: Following a Value Through the Cascade](#worked-example-following-a-value-through-the-cascade)
- [Worked Example: Why Does This Cluster Get This App?](#worked-example-why-does-this-cluster-get-this-app)
- [Adding a New Group](#adding-a-new-group)
- [Array Handling](#array-handling)

---

## How Groups Control App Deployment

Groups do not directly control app deployment. Instead, they work through
a chain of labels:

```
┌─────────────────────────────────┐
│  clusters/<name>/cluster.yaml   │
│                                 │
│  groups:                        │
│    env: production              │
│    infra: baremetal             │
│                                 │
│  apps:                          │
│    enabled:                     │
│      cert-manager: true         │
│      baremetal-hosts: true      │
│                                 │
│  managedClusterLabels:          │
│    group.env: production        │  ─── these labels flow to ───┐
│    group.infra: baremetal       │                               │
│    app.enabled/cert-manager: "true"                             │
│    app.enabled/baremetal-hosts: "true"                          │
└─────────────────────────────────┘                               │
                                                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│  ManagedCluster labels (enforced by RHACM Policy from Git)          │
│                                                                     │
│  group.env: production                                              │
│  group.infra: baremetal                                             │
│  app.enabled/cert-manager: "true"                                   │
│  app.enabled/baremetal-hosts: "true"                                │
└─────────────────────────┬───────────────────────────────────────────┘
                          │
                          │  Labels propagate to ArgoCD cluster secret
                          ▼
┌─────────────────────────────────────────────────────────────────────┐
│  ApplicationSet generators evaluate cluster labels                  │
│                                                                     │
│  cert-manager (opt-in):                                             │
│    matchLabels:                                                     │
│      app.enabled/cert-manager: "true"    ← cluster HAS this → DEPLOY│
│                                                                     │
│  cluster-monitoring (opt-out):                                      │
│    matchExpressions:                                                │
│      app.disabled/cluster-monitoring     ← cluster LACKS this → DEPLOY│
│                DoesNotExist                                          │
│                                                                     │
│  baremetal-hosts (opt-in):                                          │
│    matchLabels:                                                     │
│      app.enabled/baremetal-hosts: "true" ← cluster HAS this → DEPLOY│
└─────────────────────────────────────────────────────────────────────┘
```

**Key point:** The `groups.env: production` field in `cluster.yaml` does two
things simultaneously:

1. It sets the `group.env: production` label, which causes ArgoCD to load
   `groups/env-production/values.yaml` into the Helm value cascade.
2. It allows ApplicationSets to filter on `group.env=production` if any
   app needs group-scoped deployment (e.g. "only deploy to production clusters").

### The Three App Deployment Models

| Model | How It Works | Label | Example |
|-------|-------------|-------|---------|
| **Opt-in** | Only deploys where explicitly enabled | `app.enabled/<app>: "true"` must be present | cert-manager, external-secrets, nvidia-gpu-operator |
| **Opt-out** | Deploys everywhere unless explicitly disabled | `app.disabled/<app>: "true"` must be absent | cluster-monitoring |
| **Group-scoped** | Deploys to clusters matching a group label | `group.<type>: <value>` | _(any app can be scoped this way)_ |

Each app's `applicationset.yaml` declares which model it uses. The deployment
model is independent of the group values — an opt-in app still receives all
group values when it is enabled.

---

## How Groups Set Values

When ArgoCD renders a Helm chart for a cluster, it loads multiple value files
in a specific order. Each file can set, override, or extend values from the
files loaded before it.

### What the Helm Template Sees

For the `cluster-monitoring` app on `example-prod-east-1`, ArgoCD loads:

```
1. apps/cluster-monitoring/values.yaml      ← app defaults
2. groups/all/values.yaml                   ← fleet baseline
3. groups/env-production/values.yaml        ← environment group
4. groups/ocp-4.15/values.yaml              ← OCP version group
5. groups/infra-baremetal/values.yaml       ← infrastructure group
6. groups/region-us-east/values.yaml        ← region group (if exists)
7. clusters/example-prod-east-1/values.yaml ← cluster override
```

Each file writes under the `cluster` key. Helm deep-merges maps across files,
so:

- File 2 sets `cluster.features.monitoring.retention: 7d`
- File 3 overrides it to `cluster.features.monitoring.retention: 30d`
- The chart template sees `30d` because file 3 has higher priority

### The `cluster.*` Namespace

All value files share a common `cluster` key. This convention makes cluster
metadata available to every app chart template:

```yaml
# Any app chart template can read:
{{ .Values.cluster.name }}                         # cluster identity
{{ .Values.cluster.environment }}                  # "production" or "non-production"
{{ .Values.cluster.ocp.version }}                  # "4.15"
{{ .Values.cluster.features.monitoring.enabled }}   # true or false
{{ .Values.cluster.features.monitoring.retention }} # "30d"
{{ .Values.cluster.storage.defaultStorageClass }}   # "ocs-storagecluster-ceph-rbd"
{{ .Values.cluster.networking.networkType }}         # "OVNKubernetes"
```

Groups do not need to know which apps will read their values. They set values
under `cluster.*`, and any app that needs that data reads it.

---

## Group Types

| Directory | Label Key | Purpose | When to Use |
|-----------|-----------|---------|-------------|
| `all/` | _(always applied)_ | Fleet-wide baseline defaults | Feature flags, common labels, default storage/networking |
| `env-*/` | `group.env` | Environment tier | Different retention, TLS issuers, alerting rules per environment |
| `ocp-*/` | `group.ocp-version` | OCP version | Version-specific chart versions, feature gates, known-issue workarounds |
| `infra-*/` | `group.infra` | Infrastructure type | Bare metal BMC defaults, vSphere storage, cloud-specific settings |
| `region-*/` | `group.region` | Geographic region | Regional endpoints, DNS zones, timezone-specific silences |
| `network-*/` | `group.network` | Network plugin | OVN-Kubernetes vs OpenShift SDN specific configs |
| `<custom>/` | `group.custom` | Anything else | Hardware tiers, customer groupings, special-purpose clusters |

---

## What Each Group Sets (Reference)

### `all/` — Fleet Baseline

Applied to every cluster. Establishes safe defaults.

| Key Path | Value | Purpose |
|----------|-------|---------|
| `cluster.features.certManager.enabled` | `false` | Cert-manager is opt-in |
| `cluster.features.certManager.issuer` | `letsencrypt-staging` | Safe default issuer |
| `cluster.features.certManager.email` | `platform-alerts@example.com` | ACME contact |
| `cluster.features.monitoring.enabled` | `true` | Monitoring is opt-out (on everywhere) |
| `cluster.features.monitoring.retention` | `7d` | Conservative baseline retention |
| `cluster.features.monitoring.alertmanager.enabled` | `true` | Alertmanager on everywhere |
| `cluster.features.logging.enabled` | `false` | Logging is opt-in |
| `cluster.features.logging.retentionDays` | `7` | Default log retention |
| `cluster.features.externalSecrets.enabled` | `false` | ESO is opt-in |
| `cluster.features.baremetalHosts.enabled` | `false` | Bare metal is opt-in |
| `cluster.features.gpu.enabled` | `false` | GPU operator is opt-in |
| `cluster.features.gpu.driver.version` | `550.90.07` | Default NVIDIA driver |
| `cluster.features.gpu.dcgmExporter.enabled` | `true` | DCGM metrics on if GPU enabled |
| `cluster.features.gpu.mig.enabled` | `false` | MIG off by default |
| `cluster.storage.defaultStorageClass` | `""` | Must be set by group or cluster |
| `cluster.networking.networkType` | `OVNKubernetes` | Default network plugin |
| `cluster.alerting.silences` | Watchdog silence | Universal silence for the Watchdog alert |
| `cluster.commonLabels.managed-by` | `fleet-gitops` | Common resource labels |

### `env-production/` — Production Environment

Overrides for production clusters. Prioritizes stability and compliance.

| Key Path | Overrides From | New Value | Why |
|----------|---------------|-----------|-----|
| `cluster.environment` | _(new)_ | `production` | Identifies environment in templates |
| `cluster.features.certManager.issuer` | `all/` | `letsencrypt-prod` | Production uses real ACME certificates |
| `cluster.features.monitoring.retention` | `all/` | `30d` | Longer retention for compliance |
| `cluster.features.logging.enabled` | `all/` | `false` | Logging opt-in in prod (per-cluster decision) |
| `cluster.features.logging.retentionDays` | `all/` | `30` | Longer retention when enabled |
| `cluster.resources.enforceResourceLimits` | _(new)_ | `true` | Production enforces limits |
| `cluster.alerting.silences` | `all/` | Watchdog + PrometheusOperatorSyncFailed | Production-specific known-issue silence |
| `cluster.commonLabels.sla` | _(new)_ | `tier-1` | SLA label for alerting routes |

### `env-non-production/` — Non-Production Environment

Overrides for dev/staging/test clusters. Prioritizes debugging and flexibility.

| Key Path | Overrides From | New Value | Why |
|----------|---------------|-----------|-----|
| `cluster.environment` | _(new)_ | `non-production` | Identifies environment |
| `cluster.features.certManager.issuer` | `all/` | `letsencrypt-staging` | Avoids rate limits |
| `cluster.features.monitoring.retention` | `all/` | `7d` | Less storage needed |
| `cluster.features.logging.enabled` | `all/` | `true` | Dev clusters get logging for debugging |
| `cluster.features.logging.retentionDays` | `all/` | `7` | Short retention for cost savings |
| `cluster.resources.enforceResourceLimits` | _(new)_ | `false` | Developers need flexibility |
| `cluster.storage.defaultStorageClass` | `all/` | `thin-csi` | vSphere thin provisioning default |
| `cluster.alerting.silences` | `all/` | Watchdog + KubePodNotReady + TargetDown | Silence noisy non-prod alerts |
| `cluster.commonLabels.sla` | _(new)_ | `best-effort` | No SLA commitment |

### `ocp-4.14/` — OpenShift 4.14

Version-specific configuration for OCP 4.14 clusters.

| Key Path | Purpose |
|----------|---------|
| `cluster.ocp.version` | `4.14` — identifies OCP version |
| `cluster.features.monitoring.prometheusOperatorVersion` | `0.68` — version-matched operator |
| `cluster.features.certManager.chartVersion` | `1.13.3` — compatible cert-manager |
| `cluster.workarounds.suppressDNSOperatorAlert` | `true` — BZ-2246001 workaround |
| `cluster.alerting.silences` | DNSOperatorDegraded silence — known 4.14 issue |

### `ocp-4.15/` — OpenShift 4.15

| Key Path | Purpose |
|----------|---------|
| `cluster.ocp.version` | `4.15` — identifies OCP version |
| `cluster.features.monitoring.prometheusOperatorVersion` | `0.71` — version-matched operator |
| `cluster.features.certManager.chartVersion` | `1.14.4` — compatible cert-manager |
| `cluster.featureGates.enhancedProxySupport` | `true` — 4.15 feature gate |
| `cluster.featureGates.cgroupsV2` | `true` — cgroups v2 graduated to stable |
| `cluster.alerting.silences` | PrometheusOperatorSyncFailed silence — known 4.15 issue |

### `infra-baremetal/` — Bare Metal Infrastructure

Overrides for bare metal clusters. Enables hardware management features.

| Key Path | Overrides From | New Value | Why |
|----------|---------------|-----------|-----|
| `cluster.ocp.infrastructure` | _(new)_ | `baremetal` | Identifies infra type |
| `cluster.features.externalSecrets.enabled` | `all/` | `true` | BMC credentials must come from Vault |
| `cluster.features.baremetalHosts.enabled` | `all/` | `true` | Enables BareMetalHost management |
| `cluster.baremetal.bmcDefaults.protocol` | _(new)_ | `idrac-virtualmedia+https` | Dell iDRAC default |
| `cluster.baremetal.bmcDefaults.disableCertificateVerification` | _(new)_ | `true` | Self-signed BMC certs |
| `cluster.baremetal.rootDeviceDefaults.deviceName` | _(new)_ | `/dev/sda` | Default boot disk |
| `cluster.baremetal.firmwareSettings.enabled` | _(new)_ | `false` | Firmware management off by default |
| `cluster.storage.defaultStorageClass` | `all/` | `ocs-storagecluster-ceph-rbd` | ODF/OCS on bare metal |
| `vault.server` | _(new)_ | `https://vault.example.com` | Vault endpoint for ESO |
| `vault.bmcSecretPath` | _(new)_ | `secret/fleet/bmc` | Vault path for BMC creds |

---

## The Value Cascade

Values merge from lowest to highest priority. Later files override earlier ones
for the same key path.

```
Priority 1 (lowest):  apps/<app>/values.yaml              App chart defaults
Priority 2:           groups/all/values.yaml              Fleet-wide baseline
Priority 3:           groups/env-<env>/values.yaml        Environment group
Priority 4:           groups/ocp-<version>/values.yaml    OCP version group
Priority 5:           groups/infra-<type>/values.yaml     Infrastructure type
                      groups/region-<region>/values.yaml  Region (if exists)
                      groups/<custom>/values.yaml         Custom group (if exists)
Priority 6 (highest): clusters/<name>/values.yaml         Cluster-specific
```

### Rules

- **Maps deep-merge.** If file 2 sets `cluster.features.monitoring.enabled: true`
  and file 3 sets `cluster.features.monitoring.retention: 30d`, the chart sees
  both — they do not overwrite each other.
- **Scalars override.** If file 2 sets `retention: 7d` and file 3 sets
  `retention: 30d`, the chart sees `30d`.
- **Arrays replace entirely.** If file 2 sets `silences: [A, B]` and file 3
  sets `silences: [C]`, the chart sees `[C]` only. Use the `extra*` + `concat`
  pattern to work around this (see [Array Handling](#array-handling)).

---

## Worked Example: Following a Value Through the Cascade

**Question:** What is `cluster.features.monitoring.retention` for cluster
`example-prod-east-1`?

Use the trace tool:

```bash
bash scripts/trace-value.sh example-prod-east-1 cluster.features.monitoring.retention
```

Output:

```
Cluster: example-prod-east-1
Groups:  env=production  ocp=4.15  infra=baremetal  region=us-east  custom=

Value trace: cluster.features.monitoring.retention  (cluster: example-prod-east-1)

  1 . groups/all                      = 7d  (overridden)
  2 . groups/env-production           ← 30d
  3 . groups/ocp-4.15                 (not set)
  4 . groups/infra-baremetal          (not set)
  5 . groups/region-us-east           (file does not exist)
  6 . clusters/example-prod-east-1    (not set)

  Resolved value: 30d
  Set by:         groups/env-production
```

**Reading the output:**
- `groups/all` sets it to `7d`, but this is overridden by a higher-priority file.
- `groups/env-production` sets it to `30d` — this is the winner (marked with `←`).
- `groups/ocp-4.15` and `groups/infra-baremetal` do not set this value.
- `groups/region-us-east` does not exist.
- The cluster file does not override it, so `30d` from the production group wins.

**If the cluster needed a different retention**, you would add to
`clusters/example-prod-east-1/values.yaml`:

```yaml
cluster:
  features:
    monitoring:
      retention: 60d    # cluster override wins over all groups
```

---

## Worked Example: Why Does This Cluster Get This App?

**Question:** Why does `example-prod-east-1` receive the `cert-manager` app?

Trace the chain:

1. **`cluster.yaml`** defines `apps.enabled.cert-manager: true`
2. This generates the label `app.enabled/cert-manager: "true"` in `managedClusterLabels`
3. The `aggregate-cluster-config.sh` script collects this into the label-sync chart
4. RHACM Policy enforces the label on the `ManagedCluster` resource
5. ArgoCD copies the label to its cluster secret
6. The `cert-manager` ApplicationSet has:
   ```yaml
   selector:
     matchLabels:
       app.enabled/cert-manager: "true"
   ```
7. The cluster matches → ArgoCD generates a `cert-manager-example-prod-east-1` Application

**Question:** Why does `example-prod-east-1` receive `cluster-monitoring`
even though it has no `app.enabled/cluster-monitoring` label?

Because `cluster-monitoring` uses the **opt-out** model:

```yaml
selector:
  matchExpressions:
    - key: app.disabled/cluster-monitoring
      operator: DoesNotExist
```

Since `example-prod-east-1` does NOT have an `app.disabled/cluster-monitoring`
label, the condition `DoesNotExist` is satisfied, and monitoring deploys.

**Question:** Why does `example-nonprod-dev-1` NOT receive `baremetal-hosts`?

1. `example-nonprod-dev-1/cluster.yaml` does not list `baremetal-hosts` in
   `apps.enabled`
2. Therefore no `app.enabled/baremetal-hosts: "true"` label exists
3. The `baremetal-hosts` ApplicationSet requires `app.enabled/baremetal-hosts: "true"`
4. The cluster does not match → no Application is generated

---

## Adding a New Group

### New value for an existing group type (e.g. adding OCP 4.16)

1. Create the directory:

   ```bash
   mkdir -p groups/ocp-4.16
   ```

2. Create `values.yaml` with the version-specific overrides:

   ```yaml
   cluster:
     ocp:
       version: "4.16"
     features:
       monitoring:
         prometheusOperatorVersion: "0.73"
       certManager:
         chartVersion: "1.15.1"
   ```

3. Update clusters that run 4.16 — edit `cluster.yaml`:

   ```yaml
   groups:
     ocpVersion: "4.16"
   managedClusterLabels:
     group.ocp-version: "4.16"
   ```

4. Run the aggregation script and commit.

### New group type (e.g. adding a "tier" dimension)

This requires updating multiple files. See
[GUIDELINES.md section 8.2](../GUIDELINES.md#82-adding-a-new-group-dimension).

---

## Array Handling

Helm replaces arrays wholesale across value files. This is a common source of
confusion.

### The Problem

```yaml
# groups/all/values.yaml
cluster:
  alerting:
    silences:
      - name: Watchdog       # fleet-wide

# groups/env-production/values.yaml
cluster:
  alerting:
    silences:
      - name: ProdSpecific   # Watchdog is GONE — array was replaced
```

### The Solution: `extra*` + `concat`

For arrays that need accumulation across cascade layers:

1. The primary key (`cluster.alerting.silences`) holds the base array from
   whichever cascade layer has highest priority.
2. A companion key (`extraSilences`) in the app's `values.yaml` holds
   cluster-specific additions.
3. The chart template concatenates both:

   ```yaml
   {{- $base := .Values.cluster.alerting.silences | default list }}
   {{- $extra := .Values.extraSilences | default list }}
   {{- $all := concat $base $extra }}
   ```

See `apps/cluster-monitoring/templates/_helpers.tpl` for the full
implementation. Run `scripts/lint-array-safety.sh` to check that all arrays
are properly guarded.

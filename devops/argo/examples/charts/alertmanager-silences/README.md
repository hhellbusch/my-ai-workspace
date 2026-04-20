# alertmanager-silences

A Helm chart for managing **permanent Alertmanager silences** across an OpenShift
cluster fleet via GitOps / ArgoCD.

## Why this chart instead of the Alertmanager silence API

| Approach | Persistence | GitOps | Audit trail | Removal |
|---|---|---|---|---|
| Alertmanager silence API | Ephemeral (max ~5 years) | No | No | Manual API call |
| `AlertmanagerConfig` CRD (this chart) | Until explicitly removed | Yes | Git history | PR + merge |

Silences are expressed as `muteTimeIntervals` spanning all time inside an
`AlertmanagerConfig` resource. The Prometheus Operator merges these into the
live Alertmanager config. Removing a silence is a PR that deletes the entry.

---

## Prerequisites

- OpenShift 4.10+ (Prometheus Operator `monitoring.coreos.com/v1alpha1` CRD)
- ArgoCD 2.6+ (for multi-source Application support)
- Cluster monitoring stack enabled (`openshift-monitoring`)

---

## How it works

1. The chart creates a single `AlertmanagerConfig` resource in the
   `openshift-monitoring` namespace.
2. Each silence in `values.silences` becomes a dedicated sub-route + a mute
   time interval that spans all time (`00:00–24:00`, every day, every year).
3. `values.inhibitRules` entries are emitted as `spec.inhibitRules` for
   cluster-wide alerts that carry no namespace label (see [Namespace caveat](#namespace-caveat)).
4. When all silence and inhibit lists are empty, the chart renders nothing
   (no `AlertmanagerConfig` is created).

---

## Quick start

### 1. Add silences to your group values file

Edit the appropriate file in `group-values/`:

```yaml
# group-values/all-clusters.yaml
silences:
  - name: watchdog
    comment: "Watchdog is a heartbeat alert; not actionable by on-call"
    matchers:
      - name: alertname
        value: Watchdog
```

### 2. Wire the chart into ArgoCD

Use the provided `example-application.yaml` as a starting point, or add the
chart to your existing infrastructure ApplicationSet. Point the ArgoCD
Application at:

- **Chart source**: `argo/examples/charts/alertmanager-silences`
- **Values source**: the appropriate `group-values/<tier>.yaml` file

### 3. Verify the silence is active

```bash
# Confirm the AlertmanagerConfig was created
oc get alertmanagerconfig -n openshift-monitoring

# Inspect the merged Alertmanager config (base64-decode the secret)
oc get secret alertmanager-main -n openshift-monitoring \
  -o jsonpath='{.data.alertmanager\.yaml}' | base64 -d

# Check Alertmanager UI — the silence should appear under "Muted" routes
# Port-forward if not exposed:
oc port-forward -n openshift-monitoring svc/alertmanager-main 9093:9093
# Open http://localhost:9093
```

---

## Silence schema reference

```yaml
silences:
  - name: <string>           # Unique name; used as the mute interval name — no spaces
    comment: <string>        # REQUIRED — reason for the silence (shows in git log)
    matchers:
      - name: <label-name>   # Alertmanager label key
        value: <label-value> # Exact value (default matchType "=")
        matchType: "="       # Optional: "=", "!=", "=~" (regex), "!~" (neg-regex)
```

---

## Inhibit rules schema reference

Use `inhibitRules` for alerts that carry no namespace label (cluster-scoped
alerts such as `etcdHighNumberOfFailedGRPCRequests`). The namespace-scoped
`AlertmanagerConfig` route won't match those alerts, but inhibit rules are
applied globally.

```yaml
inhibitRules:
  - sourceMatch:
      - name: alertname
        value: SourceAlert
    targetMatch:
      - name: alertname
        value: TargetToSuppress
    equal:         # Optional: only inhibit when these labels match between source and target
      - cluster
```

---

## Namespace caveat

The Prometheus Operator automatically appends a `namespace="<config-namespace>"`
matcher to every route inside an `AlertmanagerConfig`. This means:

- **Works**: alerts that carry `namespace="openshift-monitoring"` (e.g. `Watchdog`,
  most cluster-operator alerts, etcd alerts).
- **Does not work via `silences`**: alerts with no namespace label or a different
  namespace label. Use `inhibitRules` for those.

To find the namespace label of an alert before silencing it:

```bash
# List all firing alerts and their labels
oc exec -n openshift-monitoring \
  $(oc get pod -n openshift-monitoring -l app.kubernetes.io/name=alertmanager -o name | head -1) \
  -- amtool alert --alertmanager.url=http://localhost:9093
```

---

## Cluster opt-in via groups (mustMergeOverwrite)

This chart is designed to work with a cascading values system. Because Helm
**replaces** arrays (not appends), each group values file must be
**self-contained** — it should include both the inherited silences and any
environment-specific additions.

```
group-values/
├── all-clusters.yaml        # Base silences every cluster gets
├── production.yaml          # production silences (includes all-clusters entries + prod-specific)
└── non-production.yaml      # dev/staging silences (includes all-clusters entries + nonprod-specific)
```

If your groups system uses a tool that performs deep array merging
(e.g. Helmfile with `mergeValues`, or a custom mustMergeOverwrite pre-processor),
you can instead keep `all-clusters.yaml` as the true base and let each tier file
contain only its additions.

---

## Removing a silence

1. Delete the entry from the relevant `group-values/*.yaml` file.
2. Open a PR, get review, merge.
3. ArgoCD syncs → Prometheus Operator reconciles the `AlertmanagerConfig` →
   the alert begins firing again within one Alertmanager evaluation cycle
   (default 30s).

No manual API cleanup, no tracking expiry times.

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*

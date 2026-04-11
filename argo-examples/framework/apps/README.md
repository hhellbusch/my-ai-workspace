# Apps

Each subdirectory is a deployable application managed by the framework.
An "app" is a Helm chart that wraps one or more Kubernetes resources deployed
to spoke clusters via a hub ArgoCD ApplicationSet.

## Directory Layout per App

```
apps/<app-name>/
├── Chart.yaml             # Helm chart metadata
├── values.yaml            # App defaults (LOWEST priority in cascade)
└── templates/
    ├── _helpers.tpl        # Shared helpers including mustMergeOverwrite utilities
    └── *.yaml              # Kubernetes resources (uses .Values.cluster.* for config)
```

The ApplicationSet for each app lives in `hub/applicationsets/<app-name>.yaml`,
not in the app directory. This is because the hub app-of-apps syncs
`hub/applicationsets/` to discover all ApplicationSets automatically. Keeping
the chart and the ApplicationSet separate follows the separation of concerns:
the chart defines _what_ to deploy, the ApplicationSet defines _where_.

## Deployment Patterns

### Direct Deployment (default)

Most apps use direct deployment: the ApplicationSet points the generated
Application at the spoke cluster, and the chart renders resources directly
onto the spoke. The ApplicationSet `destination.server` is `{{server}}`
(the spoke) and the namespace is the app's target namespace.

**Examples:** cluster-monitoring, cluster-logging, external-secrets,
baremetal-hosts, nvidia-gpu-operator.

### Hub-Side Application (nested pattern)

Some apps require a two-stage deployment: the ApplicationSet creates an
Application on the **hub** that in turn targets the spoke. This is used when
the app needs to manage an operator subscription or ArgoCD Application
resource on the hub before resources appear on the spoke.

In this pattern, `destination.namespace` is `openshift-gitops` (the hub
ArgoCD namespace), and the chart's templates create a child Application
pointing at the spoke.

**Example:** cert-manager — creates a hub-side Application that installs
the cert-manager operator on spoke clusters.

## App Opt-In / Opt-Out Models

Three patterns are supported — choose one per app in the ApplicationSet:

| Model        | Description                                           | Label Required             |
|--------------|-------------------------------------------------------|----------------------------|
| `opt-in`     | App deploys only where explicitly enabled             | `app.enabled/<app>: "true"` |
| `opt-out`    | App deploys everywhere unless disabled                | `app.disabled/<app>: "true"` |
| `group-scoped` | App deploys to a specific group of clusters         | `group.<type>: <value>`    |

## Accessing Cluster Values

All app chart templates have access to `cluster.*` values — the shared
cluster identity namespace resolved through the cascade:

```yaml
# In any template:
{{ .Values.cluster.name }}                    # cluster name
{{ .Values.cluster.networking.ingressDomain }} # ingress domain
{{ .Values.cluster.storage.defaultStorageClass }} # storage class
{{ .Values.cluster.features.certManager.issuer }} # feature-specific config
```

## mustMergeOverwrite Pattern

Helm deep-merges maps across value files automatically. For arrays, use the
`mustMergeOverwrite` helper defined in `_helpers.tpl` to explicitly merge
arrays from group and cluster value files:

```yaml
{{/* In a template — merge group-level silences with cluster additions */}}
{{- $groupSilences := .Values.groupSilences | default list }}
{{- $clusterSilences := .Values.cluster.alerting.extraSilences | default list }}
{{- $allSilences := concat $groupSilences $clusterSilences }}
```

See `cluster-monitoring/templates/_helpers.tpl` for the full pattern.

## Adding a New App

**Preferred:** Use the scaffolding tool:

```bash
scripts/create-app.sh my-new-app --model opt-in
```

This creates the chart under `apps/my-new-app/` and the ApplicationSet at
`hub/applicationsets/my-new-app.yaml`.

**Manual process:**

1. Create `apps/<app-name>/` with `Chart.yaml`, `values.yaml`, and `templates/`
2. Add a `cluster.features.<appName>.enabled: false` default in `groups/all/values.yaml`
3. Create `hub/applicationsets/<app-name>.yaml` — copy an existing one and update the app name, namespace, and opt-in/out model
4. Gate template rendering on the feature flag
5. Add the app to the relevant cluster `cluster.yaml` files
6. Run the aggregation script and commit

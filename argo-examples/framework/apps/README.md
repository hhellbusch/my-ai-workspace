# Apps

Each subdirectory is a deployable application managed by the framework.
An "app" is a Helm chart that wraps one or more Kubernetes resources deployed
to spoke clusters via a hub ArgoCD ApplicationSet.

## Directory Layout per App

```
apps/<app-name>/
├── applicationset.yaml    # Hub ApplicationSet — controls which clusters get this app
├── Chart.yaml             # Helm chart metadata
├── values.yaml            # App defaults (LOWEST priority in cascade)
└── templates/
    ├── _helpers.tpl        # Shared helpers including mustMergeOverwrite utilities
    └── *.yaml              # Kubernetes resources (uses .Values.cluster.* for config)
```

## App Opt-In / Opt-Out Models

Three patterns are supported — choose one per app in `applicationset.yaml`:

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

1. Copy an existing app directory: `cp -r apps/cert-manager apps/my-new-app`
2. Update `Chart.yaml` with the new app name and description
3. Update `values.yaml` with the app's defaults
4. Write templates using `.Values.cluster.*` for cluster-aware configuration
5. Copy `applicationset.yaml` and update the app name, namespace, and opt-in/out model
6. Commit — the hub App-of-Apps picks up the new ApplicationSet automatically

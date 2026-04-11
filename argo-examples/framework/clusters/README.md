# Clusters

Each subdirectory represents one managed OpenShift cluster. These directories
are the **single source of truth** for cluster identity, group membership,
and value overrides.

## How Labels Flow (GitOps)

```
clusters/<name>/cluster.yaml
       │
       │ aggregate-cluster-config.sh (CI or manual)
       ▼
hub/rhacm/cluster-labels/values.yaml  (aggregated label list)
       │
       │ ArgoCD syncs the cluster-label-sync Helm chart
       ▼
RHACM Policy  (one per cluster, enforces labels)
       │
       │ RHACM evaluates + enforces
       ▼
ManagedCluster resource  (labels applied)
       │
       │ RHACM GitOps addon copies labels
       ▼
ArgoCD cluster secret  (labels available to ApplicationSets)
```

No manual `oc label` commands needed. Edit `cluster.yaml`, commit, and the
pipeline handles the rest.

## Onboarding a New Cluster

### Automated (recommended)

Run the **Onboard New Cluster** workflow from GitHub Actions UI. It generates
all files, runs integrations, and opens a PR.

### Manual

1. Copy the template:
   ```bash
   cp -r clusters/_template clusters/my-new-cluster
   ```

2. Edit `cluster.yaml`:
   - Set cluster identity (name, server URL)
   - Set group memberships (`groups.env`, `groups.ocpVersion`, etc.)
   - Set app opt-in/out labels (`managedClusterLabels`)
   - **Ensure** `managedClusterLabels` matches the `groups` and `apps` sections

3. Edit `values.yaml`:
   - Set cluster-specific values that override all group values
   - Always populate the `cluster.*` section — it feeds every app chart

4. Regenerate the label aggregation:
   ```bash
   bash pipelines/github-actions/aggregate-cluster-config.sh argo-examples/framework
   ```

5. Commit and push — the promotion pipeline handles deployment

## Cluster Label Schema

| Label                         | Values                            | Purpose                                      |
|-------------------------------|-----------------------------------|----------------------------------------------|
| `group.env`                   | `production`, `non-production`    | Environment group → value file selection     |
| `group.ocp-version`           | `4.14`, `4.15`, `4.16`            | OCP version group → version-specific configs |
| `group.region`                | `us-east`, `us-west`, `eu-west`   | Regional group → region-specific configs     |
| `group.network`               | `ovn-kubernetes`, `sdn`           | Network type group                           |
| `group.custom`                | `<any>`                           | Additional grouping dimension                |
| `app.enabled/<app>`           | `"true"`                          | Opt-in: enable app on this cluster           |
| `app.disabled/<app>`          | `"true"`                          | Opt-out: disable app on this cluster         |

## File Roles

| File           | Purpose                                                                     |
|----------------|-----------------------------------------------------------------------------|
| `cluster.yaml` | Cluster identity + intended labels (enforced by RHACM Policy via GitOps)   |
| `values.yaml`  | **Highest priority** value overrides in the cascade                        |

## CI Validation

The validate-pr pipeline checks that:
- `cluster.yaml` has all required fields
- `cluster.name` matches the directory name
- `managedClusterLabels` are consistent with `groups` and `apps` sections
- Referenced group directories exist

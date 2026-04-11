# Groups

Groups provide the middle layers of the value cascade — between app defaults
(lowest priority) and cluster-specific values (highest priority).

## Group Types

| Directory Prefix  | Label Key             | Purpose                                    |
|-------------------|-----------------------|--------------------------------------------|
| `all/`            | _(always applied)_    | Fleet-wide baseline — every cluster gets this |
| `env-*/`          | `group.env`           | Environment tier (production, non-production) |
| `ocp-*/`          | `group.ocp-version`   | OCP version-specific configurations        |
| `region-*/`       | `group.region`        | Regional configurations                    |
| `network-*/`      | `group.network`       | Network type configurations                |
| `custom-*/`       | `group.custom`        | Arbitrary additional grouping              |

## Adding a New Group

1. Create the directory: `mkdir -p groups/<type>-<value>/`
2. Add a `values.yaml` with the group's overrides
3. Apply the label to each cluster that should be in this group:
   ```bash
   oc label managedcluster <cluster-name> group.<type>=<value>
   ```

## Value Cascade

Values merge in this order (higher number wins):

```
1. App defaults     apps/<app>/values.yaml
2. All clusters     groups/all/values.yaml
3. Env group        groups/env-<value>/values.yaml
4. OCP version      groups/ocp-<value>/values.yaml
5. Region           groups/region-<value>/values.yaml
6. Custom           groups/custom-<value>/values.yaml (via group.custom label)
7. Cluster          clusters/<name>/values.yaml  ← HIGHEST PRIORITY
```

For map keys, Helm deep-merges automatically. For arrays, Helm replaces the
entire array — define the full array in the highest-priority file where you
want to control the final value.

## The `cluster.*` Key

Every group file can set values under the `cluster` key. This shared namespace
makes cluster metadata (set by group or cluster-level files) available to
every app chart template as `.Values.cluster.*`.

For example, `groups/env-production/values.yaml` might set:
```yaml
cluster:
  features:
    monitoring:
      enabled: true
      retention: 30d
```

And `clusters/prod-east-1/values.yaml` overrides just the retention:
```yaml
cluster:
  features:
    monitoring:
      retention: 15d    # cluster wins
```

Result for prod-east-1: `monitoring.enabled = true`, `monitoring.retention = 15d`.

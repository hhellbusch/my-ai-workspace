# Scripts

## fleet-diff.sh — Desired-State-to-Desired-State Diff

Compares the fully-rendered Kubernetes manifests between two Git references
across every app and cluster combination. Shows exactly what would change on
each cluster if the target ref were deployed.

### The Problem

You have a change on `main` and want to know: "if I promote this to
production, what will actually change on each cluster?" The challenge is that
the final desired state for any cluster is the result of rendering a Helm
chart with a cascade of 6+ value files (app defaults, group values, cluster
overrides). A simple `git diff` of the YAML files does not tell you the
rendered outcome.

### The Approach

```
             ref A (e.g. release/production)        ref B (e.g. main)
                    │                                       │
                    ▼                                       ▼
        ┌─── git archive ───┐                  ┌─── git archive ───┐
        │   full tree at A   │                  │   full tree at B   │
        └────────┬───────────┘                  └────────┬───────────┘
                 │                                       │
    for each app × cluster:                 for each app × cluster:
                 │                                       │
         helm template                           helm template
         with full cascade                       with full cascade
         (app → all → env →                      (app → all → env →
          ocp → infra → cluster)                  ocp → infra → cluster)
                 │                                       │
                 ▼                                       ▼
         rendered-a.yaml                         rendered-b.yaml
                 │                                       │
                 └──────────── diff -u ──────────────────┘
                                   │
                                   ▼
                           per-combo diff
```

Both sides are checked out from Git and rendered independently with the
**complete value cascade** — the same order that ArgoCD uses in production.
The diff shows the actual Kubernetes resource changes, not just value file
edits.

### Usage

```bash
# What changes if I promote main to production?
./fleet-diff.sh release/production main

# What did the last staging promotion change?
./fleet-diff.sh release/staging~1 release/staging

# Focus on one app
./fleet-diff.sh release/production main --app nvidia-gpu-operator

# Focus on one cluster
./fleet-diff.sh release/production main --cluster example-prod-east-1

# Just the summary (no diff content)
./fleet-diff.sh release/production main --summary

# Save full output to a file
./fleet-diff.sh release/production main --output /tmp/my-diff.txt
```

### Output Example

```
Fleet Diff: release/production (a1b2c3d4) → main (e5f6g7h8)
═══════════════════════════════════════════════════════════
  Changed:   3
  Unchanged: 9
  Total:     12 (6 apps × 2 clusters)
═══════════════════════════════════════════════════════════

Changed combinations:
  CHANGED  cluster-monitoring/example-prod-east-1
  CHANGED  nvidia-gpu-operator/example-prod-east-1
  CHANGED  baremetal-hosts/example-prod-east-1

━━━ cluster-monitoring/example-prod-east-1 ━━━━━━━━━━━━━━━
--- a/cluster-monitoring/example-prod-east-1 (release/production)
+++ b/cluster-monitoring/example-prod-east-1 (main)
@@ -12,7 +12,7 @@
     prometheusK8s:
-      retention: 15d
+      retention: 30d
```

### How It Handles Edge Cases

| Case | Behavior |
|------|----------|
| App exists at ref B but not ref A | Shows as a full addition |
| App exists at ref A but not ref B | Shows as a full removal |
| Cluster added at ref B | Shows all apps for that cluster as additions |
| Value file missing in a group dir | Silently skipped (matches `ignoreMissingValueFiles`) |
| Helm template fails | Renders placeholder text, noted in output |
| Refs resolve to the same commit | Exits immediately with "No diff" |

### In CI

The `fleet-diff.yaml` GitHub Actions workflow runs `fleet-diff.sh` automatically
on PRs and posts the results as a PR comment. It can also be triggered manually
via workflow dispatch to compare any two refs.

### Requirements

- `git` (any version)
- `helm` v3.10+
- `yq` (optional but recommended — enables group discovery from `cluster.yaml`)
- `colordiff` (optional — colorizes terminal output)

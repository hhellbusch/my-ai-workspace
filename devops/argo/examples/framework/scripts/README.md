# Scripts & CLI Tools

Developer and operator tools for the fleet management framework. All scripts
work locally and in CI without requiring access to a live cluster or ArgoCD
instance.

---

## fleet-diff.sh — Desired-State Diff Between Git Refs

Compares the fully-rendered Kubernetes manifests between two Git references
across every app × cluster combination.

```bash
# What changes if I promote main to production?
./fleet-diff.sh release/production main

# Focus on one app
./fleet-diff.sh release/production main --app cluster-monitoring

# Focus on one cluster
./fleet-diff.sh release/production main --cluster example-prod-east-1

# Summary only (no diff content)
./fleet-diff.sh release/production main --summary

# Save to file
./fleet-diff.sh release/production main --output /tmp/my-diff.txt
```

Both sides are checked out from Git and rendered independently through the
complete value cascade. The diff shows rendered Kubernetes resource changes,
not just value file edits.

**Requires:** git, helm (v3.10+). **Optional:** yq (for group discovery),
colordiff (for colorized output).

---

## trace-value.sh — Value Provenance Trace

Traces a specific value path through the cascade for a given cluster,
showing exactly which file sets (or overrides) the final value.

```bash
# Which file controls monitoring retention for prod-east-1?
./trace-value.sh example-prod-east-1 cluster.features.monitoring.enabled

# Where does the storage class come from?
./trace-value.sh example-prod-east-1 cluster.storage.defaultStorageClass

# Trace with app-level defaults included
./trace-value.sh example-prod-east-1 cluster.features.gpu.driver.version --app nvidia-gpu-operator

# Trace across all apps
./trace-value.sh example-prod-east-1 cluster.features.certManager.issuer --all-apps

# Machine-readable output
./trace-value.sh example-prod-east-1 cluster.features.monitoring.retention --raw
```

### Example Output

```
Cluster: example-prod-east-1
Groups:  env=production  ocp=4.15  infra=baremetal  region=us-east  custom=

Value trace: cluster.features.monitoring.enabled  (cluster: example-prod-east-1)

  1 . groups/all                      = true  (overridden)
  2 . groups/env-production           ← true
  3 . groups/ocp-4.15                 (not set)
  4 . groups/infra-baremetal          (not set)
  5 . groups/region-us-east           (file does not exist)
  6 . clusters/example-prod-east-1    (not set)

  Resolved value: true
  Set by:         groups/env-production
```

**Requires:** yq (v4+).

---

## lint-array-safety.sh — Array Merge Safety Linter

Scans app charts for arrays defined in `values.yaml` and verifies they use
the `extra*` + `concat` pattern to safely merge values across cascade layers.

```bash
# Lint all apps
./lint-array-safety.sh

# Lint a specific app
./lint-array-safety.sh --app cluster-logging

# Show suggested fixes
./lint-array-safety.sh --fix-suggestions

# CI mode (one violation per line, no formatting)
./lint-array-safety.sh --ci
```

### What It Checks

For each array in an app's `values.yaml`:

1. **Companion key exists:** A corresponding `extra<Name>: []` key is defined
   in `values.yaml` (e.g. `silences: []` needs `extraSilences: []`).
2. **Template uses concat:** The chart's templates reference the extra key
   and use `concat` to merge both arrays.

Arrays that are only ever set at one cascade level (e.g. cluster-specific
worker inventories) are allowlisted.

**Requires:** yq (v4+). **Exit code:** 0 = no violations, 1 = violations found.

---

## create-app.sh — App Scaffolding

Generates a new fleet app with all framework conventions and invariants
pre-satisfied. No more "copy an existing app and hope you got everything right."

```bash
# Create an opt-in app (default)
./create-app.sh my-new-app

# Create an opt-out app
./create-app.sh my-new-app --model opt-out

# Specify namespace and description
./create-app.sh my-new-app --namespace my-ns --description "Deploys custom widgets"

# Preview without writing files
./create-app.sh my-new-app --dry-run
```

### What It Creates

```
apps/my-new-app/
├── Chart.yaml             # Name matches directory, standard metadata
├── values.yaml            # cluster.features.myNewApp.enabled gate + schema stubs
├── applicationset.yaml    # Correct opt-in/out selector, full cascade valueFiles
└── templates/
    ├── _helpers.tpl       # Fleet labels, mustMergeOverwrite helper
    └── my-new-app.yaml    # Feature-flag-gated placeholder template
```

It also inserts `cluster.features.<camelCaseName>.enabled: false` into
`groups/all/values.yaml` under the features block.

### What It Guarantees

- Chart name matches directory name
- Feature flag gate wraps all template rendering
- ApplicationSet uses correct label selector model
- Value cascade order matches the framework specification
- `ignoreMissingValueFiles: true` is set
- All standard fleet labels are included

**Requires:** bash. **Optional:** yq (not required for scaffolding).

---

## CI Integration

All scripts can be used in CI pipelines:

```yaml
# Example: GitHub Actions step
- name: Lint array safety
  run: |
    bash scripts/lint-array-safety.sh --ci
    if [ $? -ne 0 ]; then
      echo "::error::Array safety violations found"
      exit 1
    fi

- name: Fleet diff
  run: |
    bash scripts/fleet-diff.sh origin/${{ github.base_ref }} ${{ github.sha }} \
      --output /tmp/fleet-diff.txt

- name: Trace value for debugging
  run: |
    bash scripts/trace-value.sh example-prod-east-1 cluster.features.monitoring.retention --raw
```

The `fleet-diff.yaml` GitHub Actions workflow already integrates `fleet-diff.sh`
with automatic PR comments and artifact uploads.

# PR: Add `upgradeChain` support to `operators-installer` (v3.5.0)

## Summary

This PR adds a new `upgradeChain` parameter to the `operators-installer` Helm chart that enables
strict, ordered control over multi-hop operator upgrades. It complements the existing
`automaticIntermediateManualUpgrades` mechanism and is the recommended approach for operators
that do not follow semantic versioning.

---

## Problem

The existing `installplan-incremental-approver.py` script relies on `semver.VersionInfo.parse()`
to compare CSV names and determine upgrade ordering. This breaks for operators whose CSV names
embed build timestamps or OCP minor versions rather than standard semver strings. Examples:

```
kubernetes-nmstate-operator.4.18.0-202602172216
kubernetes-nmstate-operator.4.18.0-202603041813
```

The timestamp suffix (`202602172216`) is technically a valid semver pre-release identifier, but
pre-release version ordering in semver is lexicographic — not chronological — making automated
incremental approval unreliable or incorrect for these operators.

Additionally, even for semver-compliant operators, some upgrade paths carry risk between minor
versions (e.g. ACM 2.10 → 2.11 → 2.12) where each hop involves CRD schema changes, Hub
controller behavior differences, or managed cluster impacts that require human validation before
the next hop is authorized. The existing mechanisms provide no way to enforce that each hop was
deliberately reviewed before the next one is permitted.

---

## Solution

### New parameter: `operators[].upgradeChain`

A user-defined ordered list of CSV names representing the complete intended upgrade sequence for
an operator. The chart uses list-position comparison — not version string parsing — to validate
hop ordering.

```yaml
operators:
  - name: advanced-cluster-management
    csv: advanced-cluster-management.v2.11.3   # current target
    installPlanApproval: Manual
    upgradeChain:
      - advanced-cluster-management.v2.10.7    # initial install (completed)
      - advanced-cluster-management.v2.11.3    # current hop
      - advanced-cluster-management.v2.12.0    # next planned hop (not yet applied)
```

### New script: `installplan-chain-approver.py`

Validates the upgrade sequence before approving any InstallPlan:

1. Locates the target CSV in the `UPGRADE_CHAIN` list
2. Reads the currently installed CSV from the Subscription status
3. Confirms the target is **exactly one position ahead** of the installed version
4. Rejects with a descriptive error if any version would be skipped or if the target is behind
   the installed version
5. Approves the InstallPlan only if the chain order is valid

**Example rejection output** (attempting to skip a hop):

```
ERROR: Chain order violation detected.
  Currently installed: advanced-cluster-management.v2.10.7 (chain index 0)
  Target CSV:          advanced-cluster-management.v2.12.0 (chain index 2)
  Expected next hop:   advanced-cluster-management.v2.11.3 (chain index 1)

You must upgrade one step at a time. Update csv: to the next entry in
upgradeChain before advancing further.
```

### Approver script selection logic (Job template)

The Job template now selects the appropriate approval script based on configuration:

| Configuration | Script selected |
|---|---|
| `upgradeChain` set | `installplan-chain-approver.py` |
| `automaticIntermediateManualUpgrades: true` (no chain) | `installplan-incremental-approver.py` |
| Neither | `installplan-approver.py` (default) |

`upgradeChain` takes precedence if both are set.

### Improved non-semver error handling in `installplan_utils.py`

`get_csv_semver()` now raises a `RuntimeError` with an actionable message when a CSV name cannot
be parsed as semver, explicitly directing users to the `upgradeChain` approach:

```
RuntimeError: Could not parse 'kubernetes-nmstate-operator.4.18.0-202602172216' as a semver
version. This operator does not follow standard semver naming. Use upgradeChain instead of
automaticIntermediateManualUpgrades for this operator.
```

### Warning added to `installplan-incremental-approver.py`

A prominent comment at the top of the incremental approver warns that it is not safe for
non-semver operators and directs users to `upgradeChain`.

---

## Files Changed

| File | Change |
|---|---|
| `_scripts/installplan-chain-approver.py` | **New** — chain validation and approval script |
| `_scripts/installplan_utils.py` | Improved non-semver error handling in `get_csv_semver()` |
| `_scripts/installplan-incremental-approver.py` | Added non-semver warning comment |
| `templates/ConfigMap_operators-installer-approver-scripts.yaml` | Include new chain approver script |
| `templates/Job_installplan-approver.yaml` | Conditional script selection; `UPGRADE_CHAIN` env var |
| `values.yaml` | Document `upgradeChain` parameter |
| `README.md` | New "Upgrade Chains" and "Non-Semver Operators" sections |
| `ci/test-install-operator-with-upgrade-chain-values.yaml` | **New** — CI test values for `upgradeChain` |
| `Chart.yaml` | Version bump `3.4.0` → `3.5.0` |

---

## Use Cases

### 1. Non-semver operators (primary motivation)

Operators like `kubernetes-nmstate-operator` whose CSV names contain build timestamps are not
safe to use with `automaticIntermediateManualUpgrades`. The chain approver handles them correctly
because it never parses version strings — it only compares list positions.

```yaml
operators:
  - name: kubernetes-nmstate-operator
    csv: kubernetes-nmstate-operator.4.18.0-202603041813
    upgradeChain:
      - kubernetes-nmstate-operator.4.18.0-202602172216
      - kubernetes-nmstate-operator.4.18.0-202603041813
```

### 2. Operators requiring human validation between minor versions

Operators like ACM or OpenShift Data Foundation where each minor version hop involves
infrastructure changes that must be validated before the next hop is authorized. The upgrade
chain is the audit trail — each entry represents a hop that was reviewed and merged as a
separate PR.

### 3. Disconnected / air-gapped environments

Since the chain approver does not need to enumerate OLM's upgrade graph (only the user-defined
list), it works correctly in environments where the catalog may not expose the full upgrade path.

---

## Validation

This feature was tested end-to-end in a live OCP 4.18.28 SNO environment:

1. Installed `kubernetes-nmstate-operator.4.18.0-202602172216` using the chain approver
2. OLM automatically created a pending `Manual` InstallPlan for `4.18.0-202603041813`
3. Confirmed the InstallPlan remained **unapproved** while `csv` in Git pointed to `202602172216`
4. Updated `csv` to `4.18.0-202603041813` (one hop forward in the chain)
5. Chain approver validated: `202602172216 (index 0) → 202603041813 (index 1)` ✅
6. InstallPlan approved, CSV reached `Succeeded`, operator upgraded successfully

Attempted skip-hop scenario (not committed, verified by code review of the rejection logic):
setting `csv` to a version two positions ahead in the chain produces a clear rejection error
and exits non-zero, causing the Job to fail and ArgoCD to surface the violation.

---

## Backwards Compatibility

- No existing parameters are changed or removed
- `upgradeChain` is optional; omitting it preserves existing behavior exactly
- `automaticIntermediateManualUpgrades` continues to work as before when `upgradeChain` is not set
- Chart version bumped to `3.5.0` following semver conventions for new functionality

---

## Notes for Reviewers

- The `UPGRADE_CHAIN` environment variable passed to the Job pod is a comma-separated list of
  CSV names. Helm renders this before YAML parsing so quoting is not a concern.
- The chain approver reads `installedCSV` from the Subscription status (not from running pods),
  making it reliable even during the window between InstallPlan approval and operator pod restart.
- `upgradeChain` and `automaticIntermediateManualUpgrades: true` are mutually exclusive by
  design. Setting both is valid YAML but the chain approver takes precedence, and the
  `INCREMENTAL_INSTALL_*` env vars are not injected when `upgradeChain` is present.

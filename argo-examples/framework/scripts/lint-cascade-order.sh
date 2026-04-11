#!/usr/bin/env bash
# lint-cascade-order.sh
#
# Validates that all ApplicationSets in hub/applicationsets/ use the same
# canonical valueFiles cascade order. Prevents S-2 class drift where some
# ApplicationSets miss group layers.
#
# The canonical order is defined once in this script. All ApplicationSets
# must include exactly these entries (ignoring the app-specific path line).
#
# Usage:
#   ./lint-cascade-order.sh
#
# Exit codes:
#   0 — all ApplicationSets match the canonical cascade
#   1 — one or more deviations found

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APPSETS_DIR="$FRAMEWORK_DIR/hub/applicationsets"

# ─── Canonical cascade order ──────────────────────────────────────────────
# These are the valueFiles entries every ApplicationSet must include, in order.
# The first entry (values.yaml) is the app-local defaults.
# All $cluster-values/ entries use label placeholders that are identical
# across all ApplicationSets.
CANONICAL_CASCADE=(
  'values.yaml'
  '$cluster-values/groups/all/values.yaml'
  '$cluster-values/groups/env-{{metadata.labels.group.env}}/values.yaml'
  '$cluster-values/groups/ocp-{{metadata.labels.group.ocp-version}}/values.yaml'
  '$cluster-values/groups/infra-{{metadata.labels.group.infra}}/values.yaml'
  '$cluster-values/groups/region-{{metadata.labels.group.region}}/values.yaml'
  '$cluster-values/groups/{{metadata.labels.group.custom}}/values.yaml'
  '$cluster-values/clusters/{{name}}/values.yaml'
)

errors=0

for appset_file in "$APPSETS_DIR"/*.yaml; do
  basename=$(basename "$appset_file")

  # Skip non-ApplicationSet files
  if ! grep -q 'kind: ApplicationSet' "$appset_file" 2>/dev/null; then
    continue
  fi

  # Extract valueFiles entries (lines starting with '- ' under the valueFiles block)
  # Uses awk to capture only lines within the first valueFiles block
  actual_cascade=()
  in_valuefiles=false
  while IFS= read -r line; do
    trimmed=$(echo "$line" | sed 's/^[[:space:]]*//')
    if echo "$trimmed" | grep -q '^valueFiles:'; then
      in_valuefiles=true
      continue
    fi
    if [[ "$in_valuefiles" == true ]]; then
      if echo "$trimmed" | grep -q '^- '; then
        value=$(echo "$trimmed" | sed 's/^- //' | sed 's/#.*//' | sed 's/[[:space:]]*$//')
        actual_cascade+=("$value")
      elif echo "$trimmed" | grep -q '^#'; then
        continue
      else
        break
      fi
    fi
  done < "$appset_file"

  if [[ ${#actual_cascade[@]} -eq 0 ]]; then
    echo "WARN: $basename — no valueFiles block found (skipping)"
    continue
  fi

  # Compare against canonical
  mismatch=false
  if [[ ${#actual_cascade[@]} -ne ${#CANONICAL_CASCADE[@]} ]]; then
    mismatch=true
  else
    for i in "${!CANONICAL_CASCADE[@]}"; do
      if [[ "${actual_cascade[$i]}" != "${CANONICAL_CASCADE[$i]}" ]]; then
        mismatch=true
        break
      fi
    done
  fi

  if [[ "$mismatch" == true ]]; then
    echo "FAIL: $basename — valueFiles cascade does not match canonical order"
    echo "  Expected (${#CANONICAL_CASCADE[@]} entries):"
    for entry in "${CANONICAL_CASCADE[@]}"; do
      echo "    - $entry"
    done
    echo "  Actual (${#actual_cascade[@]} entries):"
    for entry in "${actual_cascade[@]}"; do
      echo "    - $entry"
    done
    echo ""
    errors=$((errors + 1))
  else
    echo "  OK: $basename"
  fi
done

echo ""
if [[ $errors -gt 0 ]]; then
  echo "FAILED: $errors ApplicationSet(s) deviate from the canonical cascade order."
  echo "Update the valueFiles list to match the canonical order defined in this script."
  exit 1
else
  echo "PASSED: All ApplicationSets use the canonical cascade order."
  exit 0
fi

#!/usr/bin/env bash
# lint-array-safety.sh
#
# Scans all app charts for arrays defined in values.yaml and verifies that
# the corresponding templates use the extra*/concat pattern to safely merge
# array values across cascade layers.
#
# Background: Helm replaces arrays wholesale when merging value files. If
# an app's values.yaml defines an array (e.g. silences: []) and a group
# also defines that array, Helm uses whichever file is loaded last and
# discards the other. The framework convention is:
#
#   1. The primary array key (e.g. cluster.alerting.silences) holds the
#      group-level or base array.
#   2. A companion extraSilences (or extra<Name>) key holds cluster-level
#      additions.
#   3. The template concatenates both using {{ concat $primary $extra }}.
#
# This linter catches violations of that pattern.
#
# Usage:
#   ./lint-array-safety.sh [--app <name>] [--fix-suggestions] [--ci]
#
# Exit codes:
#   0 — All arrays are properly guarded
#   1 — Violations found
#
# Requires: yq (v4+)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APPS_DIR="$FRAMEWORK_DIR/apps"

FILTER_APP=""
FIX_SUGGESTIONS=false
CI_MODE=false

# ─── Usage ────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Lint app charts for safe array handling across the value cascade.

Options:
  --app <name>         Only lint a specific app
  --fix-suggestions    Show suggested code for fixing violations
  --ci                 Machine-readable output (one violation per line)
  -h, --help           Show this help

Exit codes:
  0 — No violations found
  1 — Violations found (arrays without extra*/concat safety)
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app)              FILTER_APP="$2"; shift 2 ;;
    --fix-suggestions)  FIX_SUGGESTIONS=true; shift ;;
    --ci)               CI_MODE=true; shift ;;
    -h|--help)          usage ;;
    *)                  echo "Unknown option: $1" >&2; usage ;;
  esac
done

if ! command -v yq &>/dev/null; then
  echo "Error: yq (v4+) is required." >&2
  exit 1
fi

# ─── Helpers ──────────────────────────────────────────────────────────────

BOLD="\033[1m"
DIM="\033[2m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

if [[ ! -t 1 ]] || [[ "$CI_MODE" == true ]]; then
  BOLD="" DIM="" GREEN="" YELLOW="" RED="" RESET=""
fi

violations=0
checked=0
safe=0

# Known arrays that are safe to leave unguarded:
#   - extra* keys: these ARE the companion keys (they shouldn't need their own companion)
#   - cluster.baremetal.workers: cluster-only inventory, never set at group level
#   - resources.*: Kubernetes resource limits, always set at one level
SAFE_ARRAY_ALLOWLIST=(
  ".cluster.commonLabels"
  ".resources"
  ".certManagerChartVersion"
  ".cluster.baremetal.workers"
)

# Keys that start with "extra" are companion keys themselves — skip them
is_extra_key() {
  local path="$1"
  local last_segment="${path##*.}"
  [[ "$last_segment" == extra* ]]
}

is_allowlisted() {
  local path="$1"
  for allowed in "${SAFE_ARRAY_ALLOWLIST[@]}"; do
    [[ "$path" == "$allowed"* ]] && return 0
  done
  return 1
}

# Recursively find all array (sequence) paths in a YAML file
find_arrays_in_yaml() {
  local file="$1"
  # yq outputs paths to all sequence nodes
  yq '.. | select(tag == "!!seq") | path | "." + join(".")' "$file" 2>/dev/null | sort -u
}

# Derive the expected "extra" key name from an array path
# .cluster.alerting.silences → extraSilences
# .items → extraItems
derive_extra_key() {
  local path="$1"
  local last_segment="${path##*.}"
  # Capitalize first letter
  local capitalized
  capitalized="$(echo "${last_segment:0:1}" | tr '[:lower:]' '[:upper:]')${last_segment:1}"
  echo "extra${capitalized}"
}

# Check if any template file in the app uses concat with the array key
check_template_uses_concat() {
  local app_dir="$1"
  local array_key="$2"
  local extra_key="$3"

  # Look for concat usage referencing either the array path or extra key
  local templates_dir="$app_dir/templates"
  [[ ! -d "$templates_dir" ]] && return 1

  # Check for concat/mustAppend/list patterns with the extra key
  if grep -rq "concat\|mustAppend\|$extra_key" "$templates_dir/" 2>/dev/null; then
    # More specific: check that the extra key is actually referenced
    if grep -rq "$extra_key\|extra${array_key##*.}" "$templates_dir/" 2>/dev/null; then
      return 0
    fi
  fi

  return 1
}

# Check if the values.yaml also defines a companion extra* key
check_values_has_extra_key() {
  local file="$1"
  local extra_key="$2"

  yq ".$extra_key" "$file" 2>/dev/null | grep -qv "^null$"
}

# ─── Main ─────────────────────────────────────────────────────────────────

if [[ "$CI_MODE" != true ]]; then
  echo -e "${BOLD}Array Safety Linter${RESET}"
  echo -e "${DIM}Checking that arrays in values.yaml have extra*/concat guards...${RESET}"
  echo ""
fi

for app_dir in "$APPS_DIR"/*/; do
  [[ ! -f "$app_dir/Chart.yaml" ]] && continue
  app_name=$(basename "$app_dir")

  if [[ -n "$FILTER_APP" && "$app_name" != "$FILTER_APP" ]]; then
    continue
  fi

  values_file="$app_dir/values.yaml"
  [[ ! -f "$values_file" ]] && continue

  # Find all arrays in the values file
  arrays=$(find_arrays_in_yaml "$values_file")

  if [[ -z "$arrays" ]]; then
    continue
  fi

  app_violations=0
  app_checked=0

  while IFS= read -r array_path; do
    [[ -z "$array_path" ]] && continue

    # Skip allowlisted paths
    if is_allowlisted "$array_path"; then
      continue
    fi

    # Skip extra* companion keys (they are the solution, not the problem)
    if is_extra_key "$array_path"; then
      continue
    fi

    # Skip arrays nested inside other arrays (list-of-objects sub-fields)
    if echo "$array_path" | grep -qE '\.[0-9]+\.'; then
      continue
    fi

    app_checked=$((app_checked + 1))
    checked=$((checked + 1))

    extra_key=$(derive_extra_key "$array_path")

    # Check 1: Does values.yaml have a companion extra* key?
    has_extra_key=false
    if check_values_has_extra_key "$values_file" "$extra_key"; then
      has_extra_key=true
    fi

    # Check 2: Do templates use concat with the extra key?
    has_concat=false
    if check_template_uses_concat "$app_dir" "$array_path" "$extra_key"; then
      has_concat=true
    fi

    if [[ "$has_extra_key" == true && "$has_concat" == true ]]; then
      safe=$((safe + 1))
      continue
    fi

    # Violation found
    violations=$((violations + 1))
    app_violations=$((app_violations + 1))

    if [[ "$CI_MODE" == true ]]; then
      echo "VIOLATION: $app_name: $array_path missing ${extra_key} + concat guard"
    else
      if [[ $app_violations -eq 1 ]]; then
        echo -e "${BOLD}$app_name${RESET}"
      fi
      echo -e "  ${RED}UNSAFE${RESET} $array_path"
      if [[ "$has_extra_key" == false ]]; then
        echo -e "    ${DIM}Missing companion key: ${extra_key}: [] in values.yaml${RESET}"
      fi
      if [[ "$has_concat" == false ]]; then
        echo -e "    ${DIM}Missing concat/merge in templates referencing $extra_key${RESET}"
      fi

      if [[ "$FIX_SUGGESTIONS" == true ]]; then
        last_segment="${array_path##*.}"
        echo ""
        echo -e "    ${YELLOW}Suggested fix for values.yaml:${RESET}"
        echo -e "    ${DIM}Add at the top level:${RESET}"
        echo "      $extra_key: []"
        echo ""
        echo -e "    ${YELLOW}Suggested fix for templates:${RESET}"
        echo "      {{- \$base := $array_path | default list }}"
        echo "      {{- \$extra := .Values.$extra_key | default list }}"
        echo "      {{- \$merged := concat \$base \$extra }}"
        echo ""
      fi
    fi
  done <<< "$arrays"

  if [[ $app_violations -gt 0 && "$CI_MODE" != true ]]; then
    echo ""
  fi
done

# ─── Summary ──────────────────────────────────────────────────────────────

if [[ "$CI_MODE" != true ]]; then
  echo -e "${BOLD}Summary${RESET}"
  echo -e "  Arrays checked: $checked"
  echo -e "  Safe:           ${GREEN}$safe${RESET}"
  if [[ $violations -gt 0 ]]; then
    echo -e "  ${RED}Violations:     $violations${RESET}"
  else
    echo -e "  Violations:     ${GREEN}0${RESET}"
  fi
fi

if [[ $violations -gt 0 ]]; then
  if [[ "$CI_MODE" != true ]]; then
    echo ""
    echo -e "${RED}Arrays without extra*/concat guards risk being silently overwritten"
    echo -e "when group and cluster value files both define the same array.${RESET}"
    if [[ "$FIX_SUGGESTIONS" != true ]]; then
      echo -e "${DIM}Run with --fix-suggestions to see how to fix each violation.${RESET}"
    fi
  fi
  exit 1
fi

exit 0

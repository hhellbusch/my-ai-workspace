#!/usr/bin/env bash
# trace-value.sh
#
# Traces a value through the cascade for a given cluster, showing exactly
# which file in the hierarchy sets (or overrides) the value. Answers the
# question: "Why does cluster X have this value, and where did it come from?"
#
# Usage:
#   ./trace-value.sh <cluster-name> <value-path>
#
# Examples:
#   ./trace-value.sh example-prod-east-1 cluster.features.monitoring.enabled
#   ./trace-value.sh example-prod-east-1 cluster.features.gpu.driver.version
#   ./trace-value.sh example-nonprod-dev-1 cluster.storage.defaultStorageClass
#   ./trace-value.sh example-prod-east-1 vault.server
#
# Requires: yq (v4+)

set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ─── Usage ────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $(basename "$0") <cluster-name> <value-path> [options]

Trace a value through the cascade hierarchy for a specific cluster.
Shows which file sets each layer's contribution to the final resolved value.

Arguments:
  cluster-name         Name of the cluster directory (e.g. example-prod-east-1)
  value-path           Dot-separated path to the value (e.g. cluster.features.monitoring.enabled)

Options:
  --all-apps           Show the value as seen by every app (includes app defaults)
  --app <name>         Show the value as seen by a specific app (includes its defaults)
  --raw                Print raw YAML values without formatting
  -h, --help           Show this help

Examples:
  $(basename "$0") example-prod-east-1 cluster.features.monitoring.enabled
  $(basename "$0") example-prod-east-1 cluster.storage.defaultStorageClass
  $(basename "$0") example-prod-east-1 vault.server --app external-secrets
  $(basename "$0") example-prod-east-1 cluster.features.gpu --raw
EOF
  exit 0
}

# ─── Parse arguments ──────────────────────────────────────────────────────
CLUSTER=""
VALUE_PATH=""
FILTER_APP=""
ALL_APPS=false
RAW=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all-apps)  ALL_APPS=true; shift ;;
    --app)       FILTER_APP="$2"; shift 2 ;;
    --raw)       RAW=true; shift ;;
    -h|--help)   usage ;;
    -*)          echo "Unknown option: $1" >&2; usage ;;
    *)
      if [[ -z "$CLUSTER" ]]; then
        CLUSTER="$1"
      elif [[ -z "$VALUE_PATH" ]]; then
        VALUE_PATH="$1"
      else
        echo "Unexpected argument: $1" >&2; usage
      fi
      shift
      ;;
  esac
done

if [[ -z "$CLUSTER" || -z "$VALUE_PATH" ]]; then
  echo "Error: Both cluster-name and value-path are required." >&2
  usage
fi

# ─── Validate ─────────────────────────────────────────────────────────────

if ! command -v yq &>/dev/null; then
  echo "Error: yq (v4+) is required. Install from https://github.com/mikefarah/yq" >&2
  exit 1
fi

CLUSTER_DIR="$FRAMEWORK_DIR/clusters/$CLUSTER"
if [[ ! -d "$CLUSTER_DIR" ]]; then
  echo "Error: Cluster directory not found: clusters/$CLUSTER" >&2
  echo "Available clusters:" >&2
  ls "$FRAMEWORK_DIR/clusters/" | grep -v '^_template$' | grep -v '^README' | sed 's/^/  /' >&2
  exit 1
fi

# ─── Convert dot path to yq path ─────────────────────────────────────────
# cluster.features.monitoring.enabled → .cluster.features.monitoring.enabled
yq_path=".${VALUE_PATH}"

# ─── Discover group memberships ──────────────────────────────────────────
CLUSTER_YAML="$CLUSTER_DIR/cluster.yaml"

env_group=""
ocp_group=""
infra_group=""
region_group=""
custom_group=""

if [[ -f "$CLUSTER_YAML" ]]; then
  env_group=$(yq '.cluster.groups.env // ""' "$CLUSTER_YAML" 2>/dev/null || echo "")
  ocp_group=$(yq '.cluster.groups.ocpVersion // ""' "$CLUSTER_YAML" 2>/dev/null || echo "")
  infra_group=$(yq '.cluster.groups.infra // ""' "$CLUSTER_YAML" 2>/dev/null || echo "")
  region_group=$(yq '.cluster.groups.region // ""' "$CLUSTER_YAML" 2>/dev/null || echo "")
  custom_group=$(yq '.cluster.groups.custom // ""' "$CLUSTER_YAML" 2>/dev/null || echo "")
fi

# ─── Build the cascade list ──────────────────────────────────────────────
# Each entry: "label|relative_path|absolute_path"
# Order matches the ApplicationSet valueFiles order (lowest → highest priority)

declare -a cascade=()

# Groups and cluster (always present in the trace)
cascade+=("groups/all|$FRAMEWORK_DIR/groups/all/values.yaml")
[[ -n "$env_group" ]]    && cascade+=("groups/env-$env_group|$FRAMEWORK_DIR/groups/env-$env_group/values.yaml")
[[ -n "$ocp_group" ]]    && cascade+=("groups/ocp-$ocp_group|$FRAMEWORK_DIR/groups/ocp-$ocp_group/values.yaml")
[[ -n "$infra_group" ]]  && cascade+=("groups/infra-$infra_group|$FRAMEWORK_DIR/groups/infra-$infra_group/values.yaml")
[[ -n "$region_group" ]] && cascade+=("groups/region-$region_group|$FRAMEWORK_DIR/groups/region-$region_group/values.yaml")
[[ -n "$custom_group" ]] && cascade+=("groups/$custom_group|$FRAMEWORK_DIR/groups/$custom_group/values.yaml")
cascade+=("clusters/$CLUSTER|$CLUSTER_DIR/values.yaml")

# ─── Read a value from a YAML file, returning "" if not present ──────────
read_value() {
  local file="$1"
  local path="$2"
  if [[ -f "$file" ]]; then
    local result
    result=$(yq "$path" "$file" 2>/dev/null)
    if [[ "$result" == "null" || -z "$result" ]]; then
      echo ""
    else
      echo "$result"
    fi
  else
    echo ""
  fi
}

# ─── Format output ───────────────────────────────────────────────────────
BOLD="\033[1m"
DIM="\033[2m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RED="\033[31m"
RESET="\033[0m"

# Disable colors if not a terminal or --raw
if [[ ! -t 1 ]] || [[ "$RAW" == true ]]; then
  BOLD="" DIM="" GREEN="" YELLOW="" CYAN="" RED="" RESET=""
fi

print_layer() {
  local priority="$1"
  local label="$2"
  local file="$3"
  local value="$4"
  local is_winner="$5"

  if [[ "$RAW" == true ]]; then
    if [[ -n "$value" ]]; then
      echo "$priority|$label|$value"
    else
      echo "$priority|$label|(not set)"
    fi
    return
  fi

  local priority_pad
  priority_pad=$(printf "%-2s" "$priority")

  if [[ -z "$value" ]]; then
    if [[ ! -f "$file" ]]; then
      printf "  ${DIM}%s. %-30s  (file does not exist)${RESET}\n" "$priority_pad" "$label"
    else
      printf "  ${DIM}%s. %-30s  (not set)${RESET}\n" "$priority_pad" "$label"
    fi
  elif [[ "$is_winner" == true ]]; then
    printf "  ${GREEN}${BOLD}%s. %-30s  ← %s${RESET}\n" "$priority_pad" "$label" "$value"
  else
    printf "  ${YELLOW}%s. %-30s  = %s${RESET}  ${DIM}(overridden)${RESET}\n" "$priority_pad" "$label" "$value"
  fi
}

# ─── Trace helper for a single cascade (with optional app prefix) ────────
trace_cascade() {
  local app_name="$1"
  local app_dir="$2"

  local full_cascade=()
  local priority=1

  # App defaults (if showing app context)
  if [[ -n "$app_dir" && -f "$app_dir/values.yaml" ]]; then
    full_cascade+=("$priority|apps/$app_name (defaults)|$app_dir/values.yaml")
    priority=$((priority + 1))
  fi

  # Group and cluster layers
  for entry in "${cascade[@]}"; do
    local label="${entry%%|*}"
    local file="${entry#*|}"
    full_cascade+=("$priority|$label|$file")
    priority=$((priority + 1))
  done

  # Walk the cascade, track the winning layer
  local winning_value=""
  local winning_label=""
  local winning_priority=""

  declare -a layer_values=()

  for entry in "${full_cascade[@]}"; do
    local p="${entry%%|*}"
    local rest="${entry#*|}"
    local label="${rest%%|*}"
    local file="${rest#*|}"

    local value
    value=$(read_value "$file" "$yq_path")
    layer_values+=("$p|$label|$file|$value")

    if [[ -n "$value" ]]; then
      winning_value="$value"
      winning_label="$label"
      winning_priority="$p"
    fi
  done

  # Print header
  if [[ "$RAW" != true ]]; then
    if [[ -n "$app_name" ]]; then
      echo -e "\n${BOLD}Value trace: ${CYAN}$VALUE_PATH${RESET}  ${DIM}(app: $app_name, cluster: $CLUSTER)${RESET}"
    else
      echo -e "\n${BOLD}Value trace: ${CYAN}$VALUE_PATH${RESET}  ${DIM}(cluster: $CLUSTER)${RESET}"
    fi
    echo ""
  fi

  # Print each layer
  for entry in "${layer_values[@]}"; do
    local p="${entry%%|*}"
    local rest="${entry#*|}"
    local label="${rest%%|*}"
    local rest2="${rest#*|}"
    local file="${rest2%%|*}"
    local value="${rest2#*|}"

    local is_winner=false
    if [[ "$p" == "$winning_priority" && -n "$value" ]]; then
      is_winner=true
    fi

    print_layer "$p" "$label" "$file" "$value" "$is_winner"
  done

  # Final resolved value
  if [[ "$RAW" != true ]]; then
    echo ""
    if [[ -n "$winning_value" ]]; then
      echo -e "  ${BOLD}Resolved value:${RESET} ${GREEN}$winning_value${RESET}"
      echo -e "  ${BOLD}Set by:${RESET}         $winning_label"
    else
      echo -e "  ${RED}${BOLD}Value not set at any layer.${RESET}"
    fi
  fi
}

# ─── Main ─────────────────────────────────────────────────────────────────

echo -e "${BOLD}Cluster:${RESET} $CLUSTER"
echo -e "${BOLD}Groups:${RESET}  env=$env_group  ocp=$ocp_group  infra=$infra_group  region=$region_group  custom=$custom_group"

if [[ -n "$FILTER_APP" ]]; then
  app_dir="$FRAMEWORK_DIR/apps/$FILTER_APP"
  if [[ ! -d "$app_dir" ]]; then
    echo "Error: App not found: apps/$FILTER_APP" >&2
    exit 1
  fi
  trace_cascade "$FILTER_APP" "$app_dir"

elif [[ "$ALL_APPS" == true ]]; then
  for app_dir in "$FRAMEWORK_DIR"/apps/*/; do
    [[ ! -f "$app_dir/Chart.yaml" ]] && continue
    app_name=$(basename "$app_dir")
    trace_cascade "$app_name" "$app_dir"
  done

else
  # No app context — trace just the group/cluster cascade
  trace_cascade "" ""
fi

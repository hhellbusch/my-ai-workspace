#!/usr/bin/env bash
# fleet-diff.sh
#
# Compares fully-rendered desired state between two Git references across the
# entire fleet (every app × cluster combination). Shows exactly what would
# change on each cluster if the target ref were deployed.
#
# This is a desired-state-to-desired-state diff — it does not require access
# to a live cluster or ArgoCD instance. Both sides are rendered from Git.
#
# Usage:
#   ./fleet-diff.sh <ref-a> <ref-b> [options]
#
# Examples:
#   # What changes between main and release/production?
#   ./fleet-diff.sh release/production main
#
#   # What does a specific PR introduce vs the staging branch?
#   ./fleet-diff.sh release/staging feature/add-gpu-operator
#
#   # Compare two tags
#   ./fleet-diff.sh v1.2.0 v1.3.0
#
#   # Only diff a specific app
#   ./fleet-diff.sh release/production main --app cert-manager
#
#   # Only diff a specific cluster
#   ./fleet-diff.sh release/production main --cluster example-prod-east-1
#
#   # Output as a single file (useful for piping or saving)
#   ./fleet-diff.sh release/production main --output /tmp/fleet-diff.txt
#
#   # Machine-readable summary (changed app×cluster combos)
#   ./fleet-diff.sh release/production main --summary
#
# Requires: git, helm (v3.10+)
# Optional: colordiff (for colorized terminal output)

set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────────────
FRAMEWORK_REL_PATH="argo-examples/framework"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Detect the repo root and framework path
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
FRAMEWORK_PATH="$REPO_ROOT/$FRAMEWORK_REL_PATH"
WORK_DIR=$(mktemp -d -t fleet-diff-XXXXXX)

# ─── Defaults ─────────────────────────────────────────────────────────────
REF_A=""
REF_B=""
FILTER_APP=""
FILTER_CLUSTER=""
OUTPUT_FILE=""
SUMMARY_ONLY=false
QUIET=false
CONTEXT_LINES=3

# ─── Cleanup ──────────────────────────────────────────────────────────────
cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

# ─── Usage ────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $(basename "$0") <ref-a> <ref-b> [options]

Compare fully-rendered fleet desired state between two Git references.
ref-a is the "before" (base), ref-b is the "after" (incoming changes).

Arguments:
  ref-a                Base reference (branch, tag, or commit)
  ref-b                Target reference to compare against ref-a

Options:
  --app <name>         Only diff a specific app
  --cluster <name>     Only diff a specific cluster
  --output <file>      Write full diff output to a file
  --summary            Print only a summary of what changed (no diff content)
  --context <n>        Number of context lines in diff (default: 3)
  --quiet              Suppress progress messages
  -h, --help           Show this help

Examples:
  $(basename "$0") release/production main
  $(basename "$0") release/staging feature/enable-gpu --app nvidia-gpu-operator
  $(basename "$0") v1.2.0 v1.3.0 --cluster example-prod-east-1
  $(basename "$0") release/production main --summary
EOF
  exit 0
}

# ─── Parse arguments ──────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --app)       FILTER_APP="$2"; shift 2 ;;
    --cluster)   FILTER_CLUSTER="$2"; shift 2 ;;
    --output)    OUTPUT_FILE="$2"; shift 2 ;;
    --summary)   SUMMARY_ONLY=true; shift ;;
    --context)   CONTEXT_LINES="$2"; shift 2 ;;
    --quiet)     QUIET=true; shift ;;
    -h|--help)   usage ;;
    -*)          echo "Unknown option: $1" >&2; usage ;;
    *)
      if [[ -z "$REF_A" ]]; then
        REF_A="$1"
      elif [[ -z "$REF_B" ]]; then
        REF_B="$1"
      else
        echo "Unexpected argument: $1" >&2; usage
      fi
      shift
      ;;
  esac
done

if [[ -z "$REF_A" || -z "$REF_B" ]]; then
  echo "Error: Both ref-a and ref-b are required." >&2
  usage
fi

# ─── Helpers ──────────────────────────────────────────────────────────────
log() {
  if [[ "$QUIET" != true ]]; then
    echo "  $*" >&2
  fi
}

header() {
  if [[ "$QUIET" != true ]]; then
    echo "" >&2
    echo "── $* ──" >&2
  fi
}

# Resolve a ref to a full commit SHA (validates it exists)
resolve_ref() {
  local ref="$1"
  git -C "$REPO_ROOT" rev-parse --verify "$ref" 2>/dev/null \
    || git -C "$REPO_ROOT" rev-parse --verify "origin/$ref" 2>/dev/null \
    || { echo "Error: Cannot resolve git ref: $ref" >&2; exit 1; }
}

# Export the framework directory from a git ref into a target directory
export_ref() {
  local ref="$1"
  local target_dir="$2"
  local label="$3"
  mkdir -p "$target_dir"
  if ! git -C "$REPO_ROOT" archive "$ref" -- "$FRAMEWORK_REL_PATH" \
    | tar -x -C "$target_dir" 2>/dev/null; then
    echo "Error: framework path '$FRAMEWORK_REL_PATH' does not exist at ref $label ($ref)." >&2
    echo "This ref may predate the framework, or the path is wrong." >&2
    exit 2
  fi
}

# Render a single app × cluster combination. Mimics the ApplicationSet valueFiles cascade.
render_app_cluster() {
  local framework_dir="$1"
  local app_name="$2"
  local cluster_name="$3"

  local app_dir="$framework_dir/$FRAMEWORK_REL_PATH/apps/$app_name"
  local groups_dir="$framework_dir/$FRAMEWORK_REL_PATH/groups"
  local cluster_dir="$framework_dir/$FRAMEWORK_REL_PATH/clusters/$cluster_name"

  # The chart must exist
  if [[ ! -f "$app_dir/Chart.yaml" ]]; then
    echo "# Chart not found: $app_name"
    return
  fi

  # Build the value file cascade in priority order.
  # Missing files are silently skipped (matches ignoreMissingValueFiles behavior).
  local value_args=()

  # Priority 1: App defaults
  [[ -f "$app_dir/values.yaml" ]] && value_args+=(--values "$app_dir/values.yaml")

  # Priority 2: All clusters
  [[ -f "$groups_dir/all/values.yaml" ]] && value_args+=(--values "$groups_dir/all/values.yaml")

  # Priority 3-5: Group value files
  # We read the cluster.yaml to discover group memberships, then look up files.
  if [[ -f "$cluster_dir/cluster.yaml" ]] && command -v yq &>/dev/null; then
    local env_group ocp_group region_group infra_group custom_group
    env_group=$(yq '.cluster.groups.env // ""' "$cluster_dir/cluster.yaml" 2>/dev/null || echo "")
    ocp_group=$(yq '.cluster.groups.ocpVersion // ""' "$cluster_dir/cluster.yaml" 2>/dev/null || echo "")
    region_group=$(yq '.cluster.groups.region // ""' "$cluster_dir/cluster.yaml" 2>/dev/null || echo "")
    infra_group=$(yq '.cluster.groups.infra // ""' "$cluster_dir/cluster.yaml" 2>/dev/null || echo "")
    custom_group=$(yq '.cluster.groups.custom // ""' "$cluster_dir/cluster.yaml" 2>/dev/null || echo "")

    [[ -n "$env_group" && -f "$groups_dir/env-$env_group/values.yaml" ]] \
      && value_args+=(--values "$groups_dir/env-$env_group/values.yaml")
    [[ -n "$ocp_group" && -f "$groups_dir/ocp-$ocp_group/values.yaml" ]] \
      && value_args+=(--values "$groups_dir/ocp-$ocp_group/values.yaml")
    [[ -n "$infra_group" && -f "$groups_dir/infra-$infra_group/values.yaml" ]] \
      && value_args+=(--values "$groups_dir/infra-$infra_group/values.yaml")
    [[ -n "$region_group" && -f "$groups_dir/region-$region_group/values.yaml" ]] \
      && value_args+=(--values "$groups_dir/region-$region_group/values.yaml")
    [[ -n "$custom_group" && -f "$groups_dir/$custom_group/values.yaml" ]] \
      && value_args+=(--values "$groups_dir/$custom_group/values.yaml")
  else
    # Fallback: try common group patterns without yq
    for group_dir in "$groups_dir"/env-*/  "$groups_dir"/ocp-*/ \
                     "$groups_dir"/infra-*/ "$groups_dir"/region-*/; do
      [[ -f "$group_dir/values.yaml" ]] && value_args+=(--values "$group_dir/values.yaml")
    done
  fi

  # Priority 6 (highest): Cluster-specific
  [[ -f "$cluster_dir/values.yaml" ]] && value_args+=(--values "$cluster_dir/values.yaml")

  # Render
  helm template "$app_name" "$app_dir" "${value_args[@]}" 2>/dev/null \
    || echo "# TEMPLATE RENDER FAILED for $app_name on $cluster_name"
}

# ─── Main ─────────────────────────────────────────────────────────────────

# Resolve refs
SHA_A=$(resolve_ref "$REF_A")
SHA_B=$(resolve_ref "$REF_B")
SHORT_A=$(echo "$SHA_A" | cut -c1-8)
SHORT_B=$(echo "$SHA_B" | cut -c1-8)

header "Fleet Diff: $REF_A ($SHORT_A) → $REF_B ($SHORT_B)"

if [[ "$SHA_A" == "$SHA_B" ]]; then
  echo "Both refs resolve to the same commit ($SHORT_A). No diff." >&2
  exit 0
fi

# Export both refs
log "Exporting $REF_A ($SHORT_A)..."
export_ref "$SHA_A" "$WORK_DIR/a" "$REF_A"

log "Exporting $REF_B ($SHORT_B)..."
export_ref "$SHA_B" "$WORK_DIR/b" "$REF_B"

# Discover apps and clusters from BOTH refs (a cluster or app might exist
# in one ref but not the other — that is a meaningful diff).
discover_names() {
  local dir_type="$1"  # "apps" or "clusters"
  {
    ls "$WORK_DIR/a/$FRAMEWORK_REL_PATH/$dir_type/" 2>/dev/null || true
    ls "$WORK_DIR/b/$FRAMEWORK_REL_PATH/$dir_type/" 2>/dev/null || true
  } | grep -v '^_template$' | grep -v '^README.md$' | sort -u
}

ALL_APPS=$(discover_names "apps")
ALL_CLUSTERS=$(discover_names "clusters")

# Apply filters
if [[ -n "$FILTER_APP" ]]; then
  ALL_APPS=$(echo "$ALL_APPS" | grep "^${FILTER_APP}$" || { echo "Error: app '$FILTER_APP' not found" >&2; exit 1; })
fi
if [[ -n "$FILTER_CLUSTER" ]]; then
  ALL_CLUSTERS=$(echo "$ALL_CLUSTERS" | grep "^${FILTER_CLUSTER}$" || { echo "Error: cluster '$FILTER_CLUSTER' not found" >&2; exit 1; })
fi

APP_COUNT=$(echo "$ALL_APPS" | wc -w)
CLUSTER_COUNT=$(echo "$ALL_CLUSTERS" | wc -w)
TOTAL=$((APP_COUNT * CLUSTER_COUNT))

log "Apps: $APP_COUNT, Clusters: $CLUSTER_COUNT, Combinations: $TOTAL"

# Render and diff
mkdir -p "$WORK_DIR/rendered/a" "$WORK_DIR/rendered/b" "$WORK_DIR/diffs"

changed_count=0
unchanged_count=0
failed_count=0
diff_output=""
summary_lines=""

for app in $ALL_APPS; do
  for cluster in $ALL_CLUSTERS; do
    combo="${app}/${cluster}"
    rendered_a="$WORK_DIR/rendered/a/${app}__${cluster}.yaml"
    rendered_b="$WORK_DIR/rendered/b/${app}__${cluster}.yaml"
    diff_file="$WORK_DIR/diffs/${app}__${cluster}.diff"

    # Render at ref A
    if [[ -d "$WORK_DIR/a/$FRAMEWORK_REL_PATH/apps/$app" && \
          -d "$WORK_DIR/a/$FRAMEWORK_REL_PATH/clusters/$cluster" ]]; then
      render_app_cluster "$WORK_DIR/a" "$app" "$cluster" > "$rendered_a"
    else
      echo "# (does not exist at $REF_A)" > "$rendered_a"
    fi

    # Render at ref B
    if [[ -d "$WORK_DIR/b/$FRAMEWORK_REL_PATH/apps/$app" && \
          -d "$WORK_DIR/b/$FRAMEWORK_REL_PATH/clusters/$cluster" ]]; then
      render_app_cluster "$WORK_DIR/b" "$app" "$cluster" > "$rendered_b"
    else
      echo "# (does not exist at $REF_B)" > "$rendered_b"
    fi

    # Diff
    if diff -u -U "$CONTEXT_LINES" \
        --label "a/$combo ($REF_A)" "$rendered_a" \
        --label "b/$combo ($REF_B)" "$rendered_b" \
        > "$diff_file" 2>/dev/null; then
      unchanged_count=$((unchanged_count + 1))
    else
      # diff returns 1 when files differ (not an error)
      if [[ -s "$diff_file" ]]; then
        changed_count=$((changed_count + 1))
        summary_lines="${summary_lines}  CHANGED  ${combo}\n"
        diff_output="${diff_output}\n━━━ ${combo} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        diff_output="${diff_output}$(cat "$diff_file")\n"
      else
        failed_count=$((failed_count + 1))
        summary_lines="${summary_lines}  FAILED   ${combo}\n"
      fi
    fi
  done
done

# ─── Output ───────────────────────────────────────────────────────────────

report=""
report+="Fleet Diff: $REF_A ($SHORT_A) → $REF_B ($SHORT_B)\n"
report+="═══════════════════════════════════════════════════════\n"
report+="  Changed:   $changed_count\n"
report+="  Unchanged: $unchanged_count\n"
if [[ $failed_count -gt 0 ]]; then
  report+="  Failed:    $failed_count\n"
fi
report+="  Total:     $TOTAL ($APP_COUNT apps × $CLUSTER_COUNT clusters)\n"
report+="═══════════════════════════════════════════════════════\n"

if [[ $changed_count -gt 0 ]]; then
  report+="\nChanged combinations:\n"
  report+="$summary_lines"
fi

if [[ "$SUMMARY_ONLY" == true ]]; then
  echo -e "$report"
else
  full_report="${report}${diff_output}"

  if [[ -n "$OUTPUT_FILE" ]]; then
    echo -e "$full_report" > "$OUTPUT_FILE"
    echo "Full diff written to: $OUTPUT_FILE" >&2
    # Still print summary to terminal
    echo -e "$report"
  else
    # Print everything to stdout (pipe through colordiff if available)
    if command -v colordiff &>/dev/null && [[ -t 1 ]]; then
      echo -e "$full_report" | colordiff
    else
      echo -e "$full_report"
    fi
  fi
fi

# Exit code: 0 = no changes, 1 = changes detected
[[ $changed_count -eq 0 ]]

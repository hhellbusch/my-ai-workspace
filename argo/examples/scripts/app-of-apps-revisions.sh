#!/usr/bin/env bash
# App-of-apps-of-apps: get targetRevision for both level-2 apps (from root) and
# level-3 / final apps (from each level-2 app's manifests at its targetRevision).
#
# Requires: yq (mikefarah/yq), argocd CLI, GITOPS_NAME (project), ROOT_APP_ID (project/root-app-name), NEW_REV (revision for root).
# Usage: source or run; then use APP_REVISION_MAP (level 2) and FINAL_APP_REVISION_MAP (level 3).

set -euo pipefail

# --- Config (set these or pass in) ---
: "${GITOPS_NAME:=}"
: "${ROOT_APP_ID:=}"
: "${NEW_REV:=HEAD}"
: "${ARGOCD_OPTS:=--grpc-web}"

# Parse YAML (stdin or "$1") and output "name revision" lines for each Application.
# Uses yq eval (not eval-all) so each doc is scoped correctly.
_parse_app_revisions() {
  local yaml="${1:-}"
  if [[ -z "$yaml" ]]; then
    return 0
  fi
  echo "$yaml" | yq eval \
    'select(.kind == "Application") | .metadata.name + " " + (.spec.source.targetRevision // .spec.sources[0].targetRevision // "HEAD")' \
    - | grep -v '^---$' || true
}

# Build associative array from "name revision" lines. Usage: _fill_map VAR_NAME < <( _parse_app_revisions "$yaml" )
_fill_map() {
  local -n _map="$1"
  while IFS= read -r line; do
    local app="${line%% *}"
    local rev="${line#* }"
    [[ -n "$app" ]] && _map["$app"]="$rev"
  done
}

# --- Level 2: from root app manifests (use existing ROOT_APPS if set) ---
if [[ -z "${ROOT_APPS:-}" ]]; then
  ROOT_APPS=$(argocd app manifests "${ROOT_APP_ID}" --revision "${NEW_REV}" ${ARGOCD_OPTS} 2>/dev/null || true)
fi
declare -A APP_REVISION_MAP
while IFS= read -r line; do
  app="${line%% *}"
  rev="${line#* }"
  [[ -n "$app" ]] && APP_REVISION_MAP["$app"]="$rev"
done < <( _parse_app_revisions "$ROOT_APPS" )

# --- Level 3 (final): from each level-2 app's manifests at its targetRevision ---
declare -A FINAL_APP_REVISION_MAP
for level2_app in "${!APP_REVISION_MAP[@]}"; do
  level2_rev="${APP_REVISION_MAP[$level2_app]}"
  full_id="${GITOPS_NAME}/${level2_app}"
  child_yaml=$(argocd app manifests "$full_id" --revision "$level2_rev" ${ARGOCD_OPTS} 2>/dev/null || true)
  while IFS= read -r line; do
    app="${line%% *}"
    rev="${line#* }"
    [[ -n "$app" ]] && FINAL_APP_REVISION_MAP["$app"]="$rev"
  done < <( _parse_app_revisions "$child_yaml" )
done

# --- Optional: print both maps ---
_print_maps() {
  echo "Level 2 (from root):"
  for app in $(echo "${!APP_REVISION_MAP[@]}" | tr ' ' '\n' | sort); do
    echo "  $app -> ${APP_REVISION_MAP[$app]}"
  done
  echo "Final (level 3):"
  for app in $(echo "${!FINAL_APP_REVISION_MAP[@]}" | tr ' ' '\n' | sort); do
    echo "  $app -> ${FINAL_APP_REVISION_MAP[$app]}"
  done
}

# Uncomment to auto-print when sourced/run:
# _print_maps

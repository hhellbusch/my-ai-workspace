#!/usr/bin/env bash
# Test the app-of-apps-of-apps revision pattern using local YAML files (no argocd).
# Simulates: root → app-a, app-b, ... ; app-a → frontend, backend ; app-b → api-gateway.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

_parse_app_revisions() {
  local yaml="${1:-}"
  [[ -z "$yaml" ]] && return 0
  echo "$yaml" | yq eval \
    'select(.kind == "Application") | .metadata.name + " " + (.spec.source.targetRevision // .spec.sources[0].targetRevision // "HEAD")' \
    - | grep -v '^---$' || true
}

# Level 2 from "root"
ROOT_APPS=$(cat test-root-apps.yaml)
declare -A APP_REVISION_MAP
while IFS= read -r line; do
  app="${line%% *}"
  rev="${line#* }"
  [[ -n "$app" ]] && APP_REVISION_MAP["$app"]="$rev"
done < <( _parse_app_revisions "$ROOT_APPS" )

# Level 3: for each level-2 app, load "manifests" from test file (in real use: argocd app manifests ...)
declare -A FINAL_APP_REVISION_MAP
for level2_app in "${!APP_REVISION_MAP[@]}"; do
  level2_rev="${APP_REVISION_MAP[$level2_app]}"
  # Simulate argocd app manifests: use local file if it exists
  child_file="test-level3-${level2_app}.yaml"
  if [[ -f "$child_file" ]]; then
    child_yaml=$(cat "$child_file")
  else
    child_yaml=""
  fi
  while IFS= read -r line; do
    app="${line%% *}"
    rev="${line#* }"
    [[ -n "$app" ]] && FINAL_APP_REVISION_MAP["$app"]="$rev"
  done < <( _parse_app_revisions "$child_yaml" )
done

echo "Level 2 (from root):"
for app in $(echo "${!APP_REVISION_MAP[@]}" | tr ' ' '\n' | sort); do
  echo "  $app -> ${APP_REVISION_MAP[$app]}"
done
echo "Final (level 3):"
for app in $(echo "${!FINAL_APP_REVISION_MAP[@]}" | tr ' ' '\n' | sort); do
  echo "  $app -> ${FINAL_APP_REVISION_MAP[$app]}"
done

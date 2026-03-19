#!/usr/bin/env bash
set -e
ROOT_APPS=$(cat test-root-apps.yaml)
declare -A APP_REVISION_MAP

# Option A: yq eval (not eval-all) + grep to strip ---
while IFS= read -r line; do
  app="${line%% *}"
  rev="${line#* }"
  [[ -n "$app" ]] && APP_REVISION_MAP["$app"]="$rev"
done < <(echo "$ROOT_APPS" | yq eval 'select(.kind == "Application") | .metadata.name + " " + (.spec.source.targetRevision // .spec.sources[0].targetRevision // "HEAD")' - | grep -v '^---$')

echo "Option A (eval + grep):"
for app in $(echo "${!APP_REVISION_MAP[@]}" | tr ' ' '\n' | sort); do
  echo "  $app -> ${APP_REVISION_MAP[$app]}"
done

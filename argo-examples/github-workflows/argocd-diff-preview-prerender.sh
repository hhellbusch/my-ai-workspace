#!/usr/bin/env bash
# Pre-render level-2 Application YAMLs so argocd-diff-preview (Docker image) can
# discover and diff them. Use with dag-andersen/argocd-diff-preview for app-of-apps.
#
# Usage:
#   ./argocd-diff-preview-prerender.sh <branch-dir> [environment]
#
# Example (in CI before running the Docker image):
#   ./argocd-diff-preview-prerender.sh main production
#   ./argocd-diff-preview-prerender.sh pull-request production
#   docker run ... -v $(pwd)/main:/base-branch -v $(pwd)/pull-request:/target-branch ...
#
# Writes: <branch-dir>/rendered-apps.yaml (Application manifests for level-2 apps)

set -euo pipefail

BRANCH_DIR="${1:?Usage: $0 <branch-dir> [environment]}"
ENVIRONMENT="${2:-production}"
# Chart path relative to branch dir (e.g. charts/argocd-apps or argo-examples/charts/argocd-apps)
CHART_PATH="${CHART_PATH:-charts/argocd-apps}"
OUTPUT_FILE="${BRANCH_DIR}/rendered-apps.yaml"

if [[ ! -d "$BRANCH_DIR" ]]; then
  echo "Error: Directory not found: $BRANCH_DIR" >&2
  exit 1
fi

if [[ ! -f "${BRANCH_DIR}/${CHART_PATH}/Chart.yaml" ]]; then
  echo "Error: Chart not found: ${BRANCH_DIR}/${CHART_PATH}" >&2
  exit 1
fi

VALUES_BASE="${BRANCH_DIR}/${CHART_PATH}/values.yaml"
VALUES_ENV="${BRANCH_DIR}/${CHART_PATH}/values-${ENVIRONMENT}.yaml"

if [[ ! -f "$VALUES_BASE" ]]; then
  echo "Error: Values not found: $VALUES_BASE" >&2
  exit 1
fi

HELM_EXTRA=()
[[ -f "$VALUES_ENV" ]] && HELM_EXTRA=(--values "$VALUES_ENV")

helm template argocd-apps "${BRANCH_DIR}/${CHART_PATH}" \
  --values "$VALUES_BASE" \
  --namespace argocd \
  "${HELM_EXTRA[@]}" \
  > "$OUTPUT_FILE"

echo "Wrote ${OUTPUT_FILE} (level-2 Application manifests for argocd-diff-preview)."

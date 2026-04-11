#!/usr/bin/env bash
# create-app.sh
#
# Scaffolds a new fleet app with the correct directory structure and all
# architectural invariants pre-satisfied:
#
#   - Chart.yaml with name matching directory
#   - values.yaml with cluster.features.<name>.enabled gate and schema stubs
#   - _helpers.tpl with standard fleet labels and merge utilities
#   - applicationset.yaml with opt-in or opt-out selector
#   - Feature flag default in groups/all/values.yaml
#
# Usage:
#   ./create-app.sh <app-name> [options]
#
# Examples:
#   ./create-app.sh my-new-app
#   ./create-app.sh my-new-app --model opt-out
#   ./create-app.sh my-new-app --namespace my-ns --description "Deploys custom widgets"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APPS_DIR="$FRAMEWORK_DIR/apps"
GROUPS_ALL="$FRAMEWORK_DIR/groups/all/values.yaml"

# ─── Defaults ─────────────────────────────────────────────────────────────
APP_NAME=""
MODEL="opt-in"
NAMESPACE=""
DESCRIPTION=""
DRY_RUN=false

# ─── Usage ────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $(basename "$0") <app-name> [options]

Scaffold a new fleet application with all framework conventions.

Arguments:
  app-name             Lowercase kebab-case name (e.g. my-new-app)

Options:
  --model <type>       Deployment model: opt-in (default) or opt-out
  --namespace <ns>     Target namespace on spoke clusters (default: app name)
  --description <text> Short description for Chart.yaml
  --dry-run            Show what would be created without writing files
  -h, --help           Show this help

Examples:
  $(basename "$0") external-dns
  $(basename "$0") gpu-burn --model opt-in --namespace gpu-test
  $(basename "$0") cluster-autoscaler --model opt-out --description "Manages cluster auto-scaling"
EOF
  exit 0
}

# ─── Parse arguments ──────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)       MODEL="$2"; shift 2 ;;
    --namespace)   NAMESPACE="$2"; shift 2 ;;
    --description) DESCRIPTION="$2"; shift 2 ;;
    --dry-run)     DRY_RUN=true; shift ;;
    -h|--help)     usage ;;
    -*)            echo "Unknown option: $1" >&2; usage ;;
    *)
      if [[ -z "$APP_NAME" ]]; then
        APP_NAME="$1"
      else
        echo "Unexpected argument: $1" >&2; usage
      fi
      shift
      ;;
  esac
done

if [[ -z "$APP_NAME" ]]; then
  echo "Error: app-name is required." >&2
  usage
fi

# Validate app name (lowercase kebab-case)
if ! echo "$APP_NAME" | grep -qE '^[a-z][a-z0-9-]*[a-z0-9]$'; then
  echo "Error: App name must be lowercase kebab-case (e.g. my-new-app)." >&2
  exit 1
fi

if [[ "$MODEL" != "opt-in" && "$MODEL" != "opt-out" ]]; then
  echo "Error: --model must be 'opt-in' or 'opt-out'." >&2
  exit 1
fi

# Derive feature key: my-new-app → myNewApp
feature_key() {
  local name="$1"
  local result=""
  local capitalize=false
  for (( i=0; i<${#name}; i++ )); do
    local char="${name:$i:1}"
    if [[ "$char" == "-" ]]; then
      capitalize=true
    elif [[ "$capitalize" == true ]]; then
      result+="$(echo "$char" | tr '[:lower:]' '[:upper:]')"
      capitalize=false
    else
      result+="$char"
    fi
  done
  echo "$result"
}

FEATURE_KEY=$(feature_key "$APP_NAME")
NAMESPACE="${NAMESPACE:-$APP_NAME}"
DESCRIPTION="${DESCRIPTION:-Deploys $APP_NAME to managed OpenShift clusters via the fleet framework.}"
APP_DIR="$APPS_DIR/$APP_NAME"

# ─── Validate ─────────────────────────────────────────────────────────────
if [[ -d "$APP_DIR" ]]; then
  echo "Error: App directory already exists: apps/$APP_NAME/" >&2
  exit 1
fi

# ─── Generate file contents ──────────────────────────────────────────────

gen_chart_yaml() {
  cat <<EOF
apiVersion: v2
name: $APP_NAME
description: >
  $DESCRIPTION
type: application
version: 1.0.0
appVersion: "1.0.0"
keywords:
  - fleet
  - $APP_NAME
maintainers:
  - name: Platform Team
    email: platform-team@example.com
EOF
}

gen_values_yaml() {
  cat <<EOF
# apps/$APP_NAME/values.yaml
#
# App defaults — LOWEST priority in the value cascade.
# These apply when no group or cluster file overrides a key.

cluster:
  name: ""
  environment: ""
  networking:
    ingressDomain: ""
  storage:
    defaultStorageClass: ""
  features:
    $FEATURE_KEY:
      enabled: false
      # Add feature-specific configuration below.
      # These keys are accessible in templates as .Values.cluster.features.$FEATURE_KEY.*
EOF
}

gen_helpers_tpl() {
  cat <<'HELPERSEOF'
{{/*
APPNAME_HELPERS_TPL
*/}}

{{/*
Returns the cluster name from cluster values.
*/}}
{{- define "APPNAME.clusterName" -}}
{{- .Values.cluster.name | default "unknown" }}
{{- end }}

{{/*
Common labels applied to all resources in this chart.
*/}}
{{- define "APPNAME.labels" -}}
app.kubernetes.io/name: APPNAME
app.kubernetes.io/instance: {{ include "APPNAME.clusterName" . }}
app.kubernetes.io/managed-by: argocd
fleet.cluster: {{ include "APPNAME.clusterName" . }}
fleet.env: {{ .Values.cluster.environment | default "unknown" }}
{{- with .Values.cluster.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
mustMergeOverwrite helper — explicit map merge where the second map wins.

Usage:
  {{- $base := dict "key1" "val1" }}
  {{- $override := dict "key1" "new-val" "key2" "val2" }}
  {{- $merged := include "fleet.mergeOverwrite" (list $base $override) | fromYaml }}
*/}}
{{- define "fleet.mergeOverwrite" -}}
{{- $base := index . 0 }}
{{- $override := index . 1 }}
{{- mustMergeOverwrite $base $override | toYaml }}
{{- end }}
HELPERSEOF
}

gen_template_yaml() {
  cat <<'TEMPLATEEOF'
{{/*
APPNAME — main template

All resources are gated on the feature flag:
  .Values.cluster.features.FEATUREKEY.enabled

This ensures the app produces no resources on clusters where it is not enabled.
*/}}
{{- if .Values.cluster.features.FEATUREKEY.enabled }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: APPNAME-config
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "APPNAME.labels" . | nindent 4 }}
data:
  cluster-name: {{ include "APPNAME.clusterName" . }}
  # TODO: Replace this placeholder with actual resources for APPNAME.
  # This ConfigMap demonstrates the correct pattern:
  #   - Feature flag gate wrapping all resources
  #   - Standard fleet labels
  #   - Access to .Values.cluster.* for cluster metadata
{{- end }}
TEMPLATEEOF
}

gen_applicationset_yaml_optin() {
  cat <<EOF
---
# $APP_NAME ApplicationSet
#
# MODEL: OPT-IN
# Clusters must have label: app.enabled/$APP_NAME: "true"
#
# Value cascade (lowest → highest priority):
#   1. apps/$APP_NAME/values.yaml       (app defaults)
#   2. groups/all/values.yaml           (fleet-wide baseline)
#   3. groups/env-<env>/values.yaml     (environment group)
#   4. groups/ocp-<version>/values.yaml (OCP version group)
#   5. groups/region-<region>/values.yaml (region group, optional)
#   6. clusters/<name>/values.yaml      (cluster-specific, HIGHEST)
#
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: $APP_NAME
  namespace: openshift-gitops
  labels:
    component: fleet-management
    app: $APP_NAME
spec:
  generators:
    - clusters:
        selector:
          matchLabels:
            app.enabled/$APP_NAME: "true"

  template:
    metadata:
      name: "$APP_NAME-{{name}}"
      namespace: openshift-gitops
      labels:
        component: fleet-management
        app: $APP_NAME
        cluster: "{{name}}"
        env: "{{metadata.labels.group.env}}"
      annotations:
        fleet.cluster-name: "{{name}}"
        fleet.app: $APP_NAME
      finalizers:
        - resources-finalizer.argocd.argoproj.io

    spec:
      project: default

      sources:
        - repoURL: https://github.com/YOUR-ORG/YOUR-REPO.git
          targetRevision: main
          path: argo-examples/framework/apps/$APP_NAME
          helm:
            ignoreMissingValueFiles: true
            valueFiles:
              - values.yaml
              - \$cluster-values/groups/all/values.yaml
              - \$cluster-values/groups/env-{{metadata.labels.group.env}}/values.yaml
              - \$cluster-values/groups/ocp-{{metadata.labels.group.ocp-version}}/values.yaml
              - \$cluster-values/groups/infra-{{metadata.labels.group.infra}}/values.yaml
              - \$cluster-values/groups/region-{{metadata.labels.group.region}}/values.yaml
              - \$cluster-values/groups/{{metadata.labels.group.custom}}/values.yaml
              - \$cluster-values/clusters/{{name}}/values.yaml

        - repoURL: https://github.com/YOUR-ORG/YOUR-REPO.git
          targetRevision: main
          path: argo-examples/framework
          ref: cluster-values

      destination:
        server: "{{server}}"
        namespace: $NAMESPACE

      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
          - ServerSideApply=true
        retry:
          limit: 3
          backoff:
            duration: 10s
            factor: 2
            maxDuration: 3m
EOF
}

gen_applicationset_yaml_optout() {
  cat <<EOF
---
# $APP_NAME ApplicationSet
#
# MODEL: OPT-OUT
# Deploys to all clusters UNLESS label: app.disabled/$APP_NAME: "true"
#
# Value cascade (lowest → highest priority):
#   1. apps/$APP_NAME/values.yaml       (app defaults)
#   2. groups/all/values.yaml           (fleet-wide baseline)
#   3. groups/env-<env>/values.yaml     (environment group)
#   4. groups/ocp-<version>/values.yaml (OCP version group)
#   5. groups/region-<region>/values.yaml (region group, optional)
#   6. clusters/<name>/values.yaml      (cluster-specific, HIGHEST)
#
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: $APP_NAME
  namespace: openshift-gitops
  labels:
    component: fleet-management
    app: $APP_NAME
spec:
  generators:
    - clusters:
        selector:
          matchExpressions:
            - key: app.disabled/$APP_NAME
              operator: DoesNotExist

  template:
    metadata:
      name: "$APP_NAME-{{name}}"
      namespace: openshift-gitops
      labels:
        component: fleet-management
        app: $APP_NAME
        cluster: "{{name}}"
        env: "{{metadata.labels.group.env}}"
      annotations:
        fleet.cluster-name: "{{name}}"
        fleet.app: $APP_NAME
      finalizers:
        - resources-finalizer.argocd.argoproj.io

    spec:
      project: default

      sources:
        - repoURL: https://github.com/YOUR-ORG/YOUR-REPO.git
          targetRevision: main
          path: argo-examples/framework/apps/$APP_NAME
          helm:
            ignoreMissingValueFiles: true
            valueFiles:
              - values.yaml
              - \$cluster-values/groups/all/values.yaml
              - \$cluster-values/groups/env-{{metadata.labels.group.env}}/values.yaml
              - \$cluster-values/groups/ocp-{{metadata.labels.group.ocp-version}}/values.yaml
              - \$cluster-values/groups/infra-{{metadata.labels.group.infra}}/values.yaml
              - \$cluster-values/groups/region-{{metadata.labels.group.region}}/values.yaml
              - \$cluster-values/groups/{{metadata.labels.group.custom}}/values.yaml
              - \$cluster-values/clusters/{{name}}/values.yaml

        - repoURL: https://github.com/YOUR-ORG/YOUR-REPO.git
          targetRevision: main
          path: argo-examples/framework
          ref: cluster-values

      destination:
        server: "{{server}}"
        namespace: $NAMESPACE

      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
          - ServerSideApply=true
        retry:
          limit: 3
          backoff:
            duration: 10s
            factor: 2
            maxDuration: 3m
EOF
}

# ─── Write files ──────────────────────────────────────────────────────────

write_file() {
  local path="$1"
  local content="$2"
  local relative="${path#$FRAMEWORK_DIR/}"

  if [[ "$DRY_RUN" == true ]]; then
    echo "  [dry-run] Would create: $relative"
    return
  fi

  mkdir -p "$(dirname "$path")"
  echo "$content" > "$path"
  echo "  Created: $relative"
}

echo ""
echo "Creating fleet app: $APP_NAME"
echo "  Model:       $MODEL"
echo "  Feature key: cluster.features.$FEATURE_KEY.enabled"
echo "  Namespace:   $NAMESPACE"
echo ""

# Chart.yaml
write_file "$APP_DIR/Chart.yaml" "$(gen_chart_yaml)"

# values.yaml
write_file "$APP_DIR/values.yaml" "$(gen_values_yaml)"

# _helpers.tpl (replace APPNAME and FEATUREKEY placeholders)
helpers_content=$(gen_helpers_tpl | sed "s/APPNAME/$APP_NAME/g")
write_file "$APP_DIR/templates/_helpers.tpl" "$helpers_content"

# Main template
template_content=$(gen_template_yaml | sed "s/APPNAME/$APP_NAME/g" | sed "s/FEATUREKEY/$FEATURE_KEY/g")
write_file "$APP_DIR/templates/$APP_NAME.yaml" "$template_content"

# ApplicationSet
if [[ "$MODEL" == "opt-in" ]]; then
  write_file "$APP_DIR/applicationset.yaml" "$(gen_applicationset_yaml_optin)"
else
  write_file "$APP_DIR/applicationset.yaml" "$(gen_applicationset_yaml_optout)"
fi

# ─── Update groups/all/values.yaml with feature flag ─────────────────────

if [[ "$DRY_RUN" == true ]]; then
  echo ""
  echo "  [dry-run] Would add to groups/all/values.yaml:"
  echo "    cluster.features.$FEATURE_KEY.enabled: false"
else
  # Check if the feature key already exists
  if ! grep -q "    $FEATURE_KEY:" "$GROUPS_ALL" 2>/dev/null; then
    INSERT_MARKER="  # ── Default storage"
    if grep -q "$INSERT_MARKER" "$GROUPS_ALL"; then
      TMPFILE=$(mktemp)
      awk -v marker="$INSERT_MARKER" -v fkey="$FEATURE_KEY" \
        '{
          if (index($0, marker) > 0) {
            printf "    %s:\n", fkey
            printf "      enabled: false\n"
            printf "\n"
          }
          print
        }' "$GROUPS_ALL" > "$TMPFILE"
      mv "$TMPFILE" "$GROUPS_ALL" 2>/dev/null || cp "$TMPFILE" "$GROUPS_ALL"
    else
      cat >> "$GROUPS_ALL" <<FEATUREEOF

# $APP_NAME feature flag (added by create-app.sh)
# NOTE: This was appended at end of file. Move it under cluster.features.
    $FEATURE_KEY:
      enabled: false
FEATUREEOF
    fi
    echo ""
    echo "  Added feature flag to groups/all/values.yaml:"
    echo "    cluster.features.$FEATURE_KEY.enabled: false"
  else
    echo ""
    echo "  Feature key '$FEATURE_KEY' already exists in groups/all/values.yaml (skipped)"
  fi
fi

# ─── Summary ──────────────────────────────────────────────────────────────
echo ""
echo "Next steps:"
echo "  1. Edit apps/$APP_NAME/templates/$APP_NAME.yaml — replace placeholder with real resources"
echo "  2. Update apps/$APP_NAME/values.yaml — add app-specific configuration keys"
if [[ "$MODEL" == "opt-in" ]]; then
  echo "  3. Enable on a cluster: add 'app.enabled/$APP_NAME: \"true\"' to cluster.yaml managedClusterLabels"
else
  echo "  3. App deploys everywhere by default. To exclude: add 'app.disabled/$APP_NAME: \"true\"' to cluster.yaml"
fi
echo "  4. Run the aggregation script and commit"
echo "  5. Verify: helm lint apps/$APP_NAME/"
echo ""

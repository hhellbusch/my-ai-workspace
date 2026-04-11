{{/*
fleet-library — shared helpers for all fleet app charts.

These helpers use .Chart.Name to derive the app name automatically,
so they work with any app chart that declares this library as a dependency.
*/}}

{{/*
Returns the cluster name from the shared cluster values namespace.
*/}}
{{- define "fleet-library.clusterName" -}}
{{- .Values.cluster.name | default "unknown" }}
{{- end }}

{{/*
Common fleet labels applied to all resources.
Uses .Chart.Name as the app identifier — this matches the app directory name
by convention (enforced by Chart.yaml name matching the directory).
*/}}
{{- define "fleet-library.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ include "fleet-library.clusterName" . }}
app.kubernetes.io/managed-by: argocd
fleet.cluster: {{ include "fleet-library.clusterName" . }}
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
  {{- $merged := include "fleet-library.mergeOverwrite" (list $base $override) | fromYaml }}
*/}}
{{- define "fleet-library.mergeOverwrite" -}}
{{- $base := index . 0 }}
{{- $override := index . 1 }}
{{- mustMergeOverwrite $base $override | toYaml }}
{{- end }}

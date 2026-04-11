{{/*
_helpers.tpl — cert-manager

Shared template helpers for the cert-manager app chart.
Includes the mustMergeOverwrite utilities used across all fleet app charts.
*/}}

{{/*
Expand the name of the chart.
*/}}
{{- define "cert-manager.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Returns the cluster name from cluster values.
Falls back to "unknown" if not set (prevents empty label values).
*/}}
{{- define "cert-manager.clusterName" -}}
{{- .Values.cluster.name | default "unknown" }}
{{- end }}

{{/*
Returns the resolved ClusterIssuer name based on cluster values.

Priority: cluster.features.certManager.issuer (resolved via cascade)
*/}}
{{- define "cert-manager.issuerName" -}}
{{- $issuer := .Values.cluster.features.certManager.issuer | default "letsencrypt-staging" }}
{{- printf "cluster-issuer-%s" $issuer }}
{{- end }}

{{/*
mustMergeOverwrite helper — explicit map merge where the second map wins.

Usage in templates:
  {{- $base := dict "key1" "val1" "key2" "val2" }}
  {{- $override := dict "key2" "new-val" "key3" "val3" }}
  {{- $merged := include "fleet.mergeOverwrite" (list $base $override) | fromYaml }}

This is equivalent to mustMergeOverwrite($base, $override) — override wins.
Helm's mustMergeOverwrite modifies the first argument in place and returns it.
*/}}
{{- define "fleet.mergeOverwrite" -}}
{{- $base := index . 0 }}
{{- $override := index . 1 }}
{{- mustMergeOverwrite $base $override | toYaml }}
{{- end }}

{{/*
Resolves the cert-manager feature config by merging cluster values over app defaults.

This demonstrates the explicit mustMergeOverwrite pattern for cases where you
need programmatic control over the merge order, rather than relying solely on
Helm's automatic value file merging.

Returns a map with the resolved certManager config.
*/}}
{{- define "cert-manager.resolvedConfig" -}}
{{- $appDefaults := dict
    "enabled" false
    "issuer" "letsencrypt-staging"
    "email" ""
    "acme" (dict "dnsProvider" "")
    "additionalIssuers" (list)
-}}
{{- $clusterConfig := .Values.cluster.features.certManager | default dict }}
{{- $resolved := mustMergeOverwrite (deepCopy $appDefaults) $clusterConfig }}
{{- $resolved | toYaml }}
{{- end }}

{{/*
Common labels applied to all resources in this chart.
Reads from cluster.commonLabels (merged across group and cluster value files).
*/}}
{{- define "cert-manager.labels" -}}
app.kubernetes.io/name: cert-manager
app.kubernetes.io/instance: {{ include "cert-manager.clusterName" . }}
app.kubernetes.io/managed-by: argocd
fleet.cluster: {{ include "cert-manager.clusterName" . }}
fleet.env: {{ .Values.cluster.environment | default "unknown" }}
{{- with .Values.cluster.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
_helpers.tpl — cluster-logging
*/}}

{{- define "cluster-logging.clusterName" -}}
{{- .Values.cluster.name | default "unknown" }}
{{- end }}

{{- define "cluster-logging.labels" -}}
app.kubernetes.io/name: cluster-logging
app.kubernetes.io/instance: {{ include "cluster-logging.clusterName" . }}
app.kubernetes.io/managed-by: argocd
fleet.cluster: {{ include "cluster-logging.clusterName" . }}
fleet.env: {{ .Values.cluster.environment | default "unknown" }}
{{- with .Values.cluster.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
resolvedStorageClass — cluster storage class with component fallback.
*/}}
{{- define "cluster-logging.storageClass" -}}
{{- $explicit := .Values.loki.storageClass | default "" }}
{{- $clusterDefault := .Values.cluster.storage.defaultStorageClass | default "" }}
{{- $explicit | default $clusterDefault }}
{{- end }}

{{/*
resolvedRetentionDays — logging retention resolved from cascade.
*/}}
{{- define "cluster-logging.retentionDays" -}}
{{- .Values.cluster.features.logging.retentionDays | default .Values.cluster.features.logging.retentionDays | default 7 }}
{{- end }}

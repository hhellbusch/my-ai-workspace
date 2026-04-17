{{/*
_helpers.tpl — cluster-logging
*/}}

{{- define "cluster-logging.clusterName" -}}
{{- include "fleet-library.clusterName" . }}
{{- end }}

{{- define "cluster-logging.labels" -}}
{{- include "fleet-library.labels" . }}
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
{{- .Values.cluster.features.logging.retentionDays | default 7 }}
{{- end }}

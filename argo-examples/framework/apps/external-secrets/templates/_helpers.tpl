{{- define "external-secrets.clusterName" -}}
{{- include "fleet-library.clusterName" . }}
{{- end }}

{{- define "external-secrets.labels" -}}
{{- include "fleet-library.labels" . }}
{{- end }}

{{/*
Vault secret path for this cluster.
Convention: <vault.path>/<cluster-name>/
*/}}
{{- define "external-secrets.vaultPath" -}}
{{- printf "%s/%s" .Values.vault.path (include "external-secrets.clusterName" .) }}
{{- end }}

{{/*
Vault Kubernetes auth role — defaults to cluster name if not explicitly set.
*/}}
{{- define "external-secrets.vaultRole" -}}
{{- .Values.vault.kubernetesAuth.role | default (include "external-secrets.clusterName" .) }}
{{- end }}

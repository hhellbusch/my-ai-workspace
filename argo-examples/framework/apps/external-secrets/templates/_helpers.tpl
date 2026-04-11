{{- define "external-secrets.clusterName" -}}
{{- .Values.cluster.name | default "unknown" }}
{{- end }}

{{- define "external-secrets.labels" -}}
app.kubernetes.io/name: external-secrets
app.kubernetes.io/instance: {{ include "external-secrets.clusterName" . }}
app.kubernetes.io/managed-by: argocd
fleet.cluster: {{ include "external-secrets.clusterName" . }}
fleet.env: {{ .Values.cluster.environment | default "unknown" }}
{{- with .Values.cluster.commonLabels }}
{{ toYaml . }}
{{- end }}
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

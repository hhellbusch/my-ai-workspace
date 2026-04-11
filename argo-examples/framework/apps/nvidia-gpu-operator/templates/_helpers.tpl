{{- define "nvidia-gpu-operator.clusterName" -}}
{{- .Values.cluster.name | default "unknown" }}
{{- end }}

{{- define "nvidia-gpu-operator.labels" -}}
app.kubernetes.io/name: nvidia-gpu-operator
app.kubernetes.io/instance: {{ include "nvidia-gpu-operator.clusterName" . }}
app.kubernetes.io/managed-by: argocd
fleet.cluster: {{ include "nvidia-gpu-operator.clusterName" . }}
fleet.env: {{ .Values.cluster.environment | default "unknown" }}
{{- with .Values.cluster.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Resolves the GPU operator InstallPlan approval mode.
Production: Manual (controlled rollouts). Non-production: Automatic.
*/}}
{{- define "nvidia-gpu-operator.installPlanApproval" -}}
{{- if .Values.gpuOperator.installPlanApproval }}
{{- .Values.gpuOperator.installPlanApproval }}
{{- else if eq (.Values.cluster.environment | default "") "production" }}
{{- "Manual" }}
{{- else }}
{{- "Automatic" }}
{{- end }}
{{- end }}

{{/*
Resolves the full GPU driver config by merging cluster overrides over defaults.
*/}}
{{- define "nvidia-gpu-operator.resolvedDriverConfig" -}}
{{- $defaults := .Values.clusterPolicy.driver }}
{{- $clusterOverrides := .Values.cluster.features.gpu.driver | default dict }}
{{- mustMergeOverwrite (deepCopy $defaults) $clusterOverrides | toYaml }}
{{- end }}

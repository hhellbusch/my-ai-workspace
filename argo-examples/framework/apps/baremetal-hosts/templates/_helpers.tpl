{{- define "baremetal-hosts.clusterName" -}}
{{- .Values.cluster.name | default "unknown" }}
{{- end }}

{{- define "baremetal-hosts.labels" -}}
app.kubernetes.io/name: baremetal-hosts
app.kubernetes.io/instance: {{ include "baremetal-hosts.clusterName" . }}
app.kubernetes.io/managed-by: argocd
fleet.cluster: {{ include "baremetal-hosts.clusterName" . }}
fleet.env: {{ .Values.cluster.environment | default "unknown" }}
{{- with .Values.cluster.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Resolves the BMC address for a host. Prepends the iDRAC protocol prefix
if the address doesn't already contain a scheme.
*/}}
{{- define "baremetal-hosts.bmcAddress" -}}
{{- $host := index . 0 }}
{{- $ctx := index . 1 }}
{{- $address := $host.bmc.address | default "" }}
{{- if and $address (not (contains "://" $address)) }}
{{- $protocol := $ctx.Values.cluster.baremetal.bmcDefaults.protocol | default "idrac-virtualmedia+https" }}
{{- printf "%s://%s/redfish/v1/Systems/System.Embedded.1" $protocol $address }}
{{- else }}
{{- $address }}
{{- end }}
{{- end }}

{{/*
Returns the Vault path for a host's BMC credentials.
Convention: <bmcSecretPath>/<cluster-name>/<host-name>
*/}}
{{- define "baremetal-hosts.vaultBmcPath" -}}
{{- $hostName := index . 0 }}
{{- $ctx := index . 1 }}
{{- printf "%s/%s/%s" $ctx.Values.vault.bmcSecretPath (include "baremetal-hosts.clusterName" $ctx) $hostName }}
{{- end }}

{{/*
Returns the root device hints for a host, falling back to cluster defaults.
*/}}
{{- define "baremetal-hosts.rootDeviceHints" -}}
{{- $host := index . 0 }}
{{- $ctx := index . 1 }}
{{- $hostHints := $host.rootDeviceHints | default dict }}
{{- $defaults := $ctx.Values.cluster.baremetal.rootDeviceDefaults | default dict }}
{{- mustMergeOverwrite (deepCopy $defaults) $hostHints | toYaml }}
{{- end }}

{{/*
Returns node labels for a host based on its role.
GPU nodes get nvidia.com labels. Infra nodes get the infra role label.
*/}}
{{- define "baremetal-hosts.nodeLabels" -}}
{{- $host := . }}
{{- $labels := dict }}
{{- if $host.labels }}
  {{- $labels = mustMergeOverwrite $labels $host.labels }}
{{- end }}
{{- if eq ($host.role | default "worker") "gpu" }}
  {{- $_ := set $labels "nvidia.com/gpu.present" "true" }}
  {{- $_ := set $labels "node-role.kubernetes.io/gpu" "" }}
  {{- $_ := set $labels "node-role.kubernetes.io/worker" "" }}
{{- else if eq ($host.role | default "worker") "infra" }}
  {{- $_ := set $labels "node-role.kubernetes.io/infra" "" }}
{{- else }}
  {{- $_ := set $labels "node-role.kubernetes.io/worker" "" }}
{{- end }}
{{- $labels | toYaml }}
{{- end }}

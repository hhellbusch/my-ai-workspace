{{/*
_helpers.tpl — cluster-monitoring

Shared helpers and the mustMergeOverwrite-based silence resolution strategy.

KEY PROBLEM: Helm replaces arrays entirely when merging value files.
If groups/env-production/values.yaml defines:
  cluster.alerting.silences: [watchdog, prodSilence]

And clusters/prod-east-1/values.yaml defines:
  cluster.alerting.silences: [clusterSpecificSilence]

Helm uses ONLY the cluster file's array — the group silences are lost.

SOLUTION: Use a two-layer approach:
  1. Groups define silences in cluster.alerting.silences (Helm's cascade picks
     the highest-priority file's array — the cluster file wins if set).
  2. Clusters define ADDITIONAL silences in .Values.extraSilences (a separate key).
  3. This template concatenates both lists, giving us:
       group silences (from cluster.alerting.silences) + cluster extras (extraSilences)

This avoids duplication while preserving the group baseline.

For the case where a cluster needs to REPLACE group silences entirely,
it sets cluster.alerting.silences in its values.yaml and leaves extraSilences empty.
*/}}

{{/*
Returns the cluster name.
*/}}
{{- define "cluster-monitoring.clusterName" -}}
{{- include "fleet-library.clusterName" . }}
{{- end }}

{{/*
resolvedSilences — concatenates group-level and cluster-extra silences.

The group silences live in .Values.cluster.alerting.silences (resolved by the
highest-priority group or cluster value file that defines the array).
Cluster-specific ADDITIONAL silences live in .Values.extraSilences.

By keeping additional silences in a separate key, we avoid the Helm array
replacement problem: the cluster's values.yaml can add silences via
.extraSilences without needing to repeat the full group silence list.
*/}}
{{- define "cluster-monitoring.resolvedSilences" -}}
{{- $groupSilences := .Values.cluster.alerting.silences | default list }}
{{- $clusterExtraSilences := .Values.extraSilences | default list }}
{{- $allSilences := concat $groupSilences $clusterExtraSilences }}
{{- $allSilences | toYaml }}
{{- end }}

{{/*
resolvedRetention — picks the monitoring retention from cluster values,
falling back to the prometheus chart-level value.

Demonstrates mustMergeOverwrite for a scalar: cluster values win.
*/}}
{{- define "cluster-monitoring.resolvedRetention" -}}
{{- $clusterRetention := .Values.cluster.features.monitoring.retention | default "" }}
{{- $appDefault := .Values.prometheus.retention | default "7d" }}
{{- $clusterRetention | default $appDefault }}
{{- end }}

{{/*
resolvedStorageClass — resolves storage class with fallback chain:
  1. Explicit storageClass in chart values (component-level)
  2. cluster.storage.defaultStorageClass (cluster-level default)
  3. "" (empty — uses cluster default)
*/}}
{{- define "cluster-monitoring.storageClass" -}}
{{- $component := index . 0 }}
{{- $ctx := index . 1 }}
{{- $explicit := $component | default "" }}
{{- $clusterDefault := $ctx.Values.cluster.storage.defaultStorageClass | default "" }}
{{- $explicit | default $clusterDefault }}
{{- end }}

{{/*
mustMergeOverwrite example — explicitly merging two config maps.

Usage:
  {{- $merged := include "cluster-monitoring.mergeConfig" (list $base $override) | fromYaml }}
*/}}
{{- define "cluster-monitoring.mergeConfig" -}}
{{- $base := index . 0 }}
{{- $override := index . 1 }}
{{- mustMergeOverwrite $base $override | toYaml }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "cluster-monitoring.labels" -}}
{{- include "fleet-library.labels" . }}
{{- end }}

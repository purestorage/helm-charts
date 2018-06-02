{{/* Create a chart_labels for each resources
*/}}
{{- define "pure_k8s_plugin.labels" -}}
generator: helm
heritage: {{ .Release.Service | quote }}
date: {{ now | htmlDate }}
chart: {{ .Chart.Name }}-{{ .Chart.Version }}
release: {{ .Release.Name | quote }}
{{- end -}}

{{/* Define the flexpath to install pureflex
*/}}
{{ define "pure_k8s_plugin.flexpath" -}}
{{ if eq .Values.orchestrator.name "k8s" -}}
{{ .Values.orchestrator.k8s.flexPath }}
{{ else if eq .Values.orchestrator.name "openshift" -}}
{{ .Values.orchestrator.openshift.flexPath }}
{{- end -}}
{{- end -}}

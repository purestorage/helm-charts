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

{{/* Define the apiversion of clusterrolebinding
*/}}
{{ define "pure_k8s_plugin.clusterrolebiding_apiversion" -}}
{{ if eq .Values.orchestrator.name "k8s" -}}rbac.authorization.k8s.io/v1beta1{{ else -}}v1{{- end -}}
{{- end -}}

{{/* Create a chart_labels for each resources
*/}}
{{- define "pure_k8s_plugin.labels" -}}
generator: helm
chart: {{ .Chart.Name }}
release: {{ .Release.Name | quote }}
{{- end -}}

{{/* Define the flexpath to install pureflex
*/}}
{{ define "pure_k8s_plugin.flexpath" -}}
{{ if has .Values.image.tag (list "1.0" "1.1" "1.2" "1.2.1" "1.2.2" "1.2.4" "1.2.5") -}}
{{ if eq .Values.orchestrator.name "k8s" -}}
{{ .Values.orchestrator.k8s.flexBaseDir }}
{{ else if eq .Values.orchestrator.name "openshift" -}}
{{ .Values.orchestrator.openshift.flexBaseDir }}
{{- end -}}
{{ else -}}
{{ if eq .Values.orchestrator.name "k8s" -}}
{{ .Values.orchestrator.k8s.flexPath }}
{{ else if eq .Values.orchestrator.name "openshift" -}}
{{ .Values.orchestrator.openshift.flexPath }}
{{- end -}}
{{- end -}}
{{- end -}}

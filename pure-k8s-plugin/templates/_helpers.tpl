{{/* Create a chart_labels for each resources
*/}}
{{- define "chart_labels" -}}
generator: helm
heritage: {{ .Release.Service | quote }}
date: {{ now | htmlDate }}
chart: {{ .Chart.Name }}-{{ .Chart.Version }}
release: {{ .Release.Name | quote }}
{{- end -}}

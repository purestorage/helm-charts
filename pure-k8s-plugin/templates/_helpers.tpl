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
{{ if .Values.flexPath -}}
{{ .Values.flexPath }}
{{ else if eq .Values.orchestrator.name "k8s" -}}
{{ .Values.orchestrator.k8s.flexPath }}
{{ else if eq .Values.orchestrator.name "openshift" -}}
{{ .Values.orchestrator.openshift.flexPath }}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for deployment.
*/}}
{{- define "deployment.apiVersion" -}}
{{- if semverCompare ">=1.16-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "apps/v1" -}}
{{- else -}}
{{- print "apps/v1beta1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for daemonset.
*/}}
{{- define "daemonset.apiVersion" -}}
{{- if semverCompare ">=1.16-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "apps/v1" -}}
{{- else -}}
{{- print "apps/v1beta1" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for RBAC APIs.
*/}}
{{- define "rbac.apiVersion" -}}
{{- if semverCompare "^1.8-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "rbac.authorization.k8s.io/v1" -}}
{{- else -}}
{{- print "rbac.authorization.k8s.io/v1beta1" -}}
{{- end -}}
{{- end -}}


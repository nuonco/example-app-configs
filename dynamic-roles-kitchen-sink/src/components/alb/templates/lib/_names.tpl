{{- define "common.name" -}}

{{- if .Values.name }}
{{- .Values.name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-public" .Values.install_name }}
{{- end }}

{{- end }}

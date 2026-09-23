apiVersion: v1
kind: ConfigMap
metadata:
  name: health-kinds-marker
  namespace: {{ .Values.namespace }}
data:
  install: {{ .Values.install_name | quote }}

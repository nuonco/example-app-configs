apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: health-kinds-selfsigned
  namespace: {{ .Values.namespace }}
spec:
  selfSigned: {}

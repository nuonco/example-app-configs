apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: health-kinds-cert
  namespace: {{ .Values.namespace }}
spec:
  secretName: health-kinds-cert-tls
  commonName: health-kinds.{{ .Values.namespace }}.svc
  dnsNames:
    - health-kinds.{{ .Values.namespace }}.svc
  issuerRef:
    name: health-kinds-selfsigned
    kind: Issuer

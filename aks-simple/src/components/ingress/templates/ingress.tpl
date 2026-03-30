---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "common.name" . }}
  namespace: {{ .Values.namespace }}
  labels:
    app.nuon.co/install: {{ .Values.install_name }}
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
spec:
  rules:
    - host: {{ .Values.domain }}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: {{ .Values.service_name }}
                port:
                  number: {{ .Values.service_port | default "3000" }}

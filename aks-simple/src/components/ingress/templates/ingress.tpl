---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "common.name" . }}
  namespace: {{ .Values.namespace }}
  labels:
    app.nuon.co/install: {{ .Values.install_name }}
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    external-dns.alpha.kubernetes.io/hostname: {{ .Values.domain }}
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - {{ .Values.domain }}
      secretName: {{ .Values.domain }}-tls
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

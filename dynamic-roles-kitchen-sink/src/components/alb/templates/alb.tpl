---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "common.name" . }}
  namespace: {{ .Values.namespace }}
  labels:
    app.nuon.co/install: {{ .Values.install_name }}
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":{{ .Values.https_port | default "443" }}}]'
    alb.ingress.kubernetes.io/aws-load-balancer-ssl-ports: https
    alb.ingress.kubernetes.io/healthcheck-path: {{ .Values.healthcheck_path | default "/livez" | quote }}
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: '5'
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: '2'
    alb.ingress.kubernetes.io/unhealthy-threshold-count: '2'
    alb.ingress.kubernetes.io/healthy-threshold-count: '2'
    alb.ingress.kubernetes.io/certificate-arn: {{ .Values.domain_certificate }}
    external-dns.alpha.kubernetes.io/hostname: {{ .Values.domain }}
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: {{ .Values.service_name }}
                port:
                  number: {{ .Values.service_port | default "3000" }}

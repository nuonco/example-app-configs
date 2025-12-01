{{- range .Values.nodepools }}
---
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: "{{ .name }}"
spec:
  amiSelectorTerms:
  - alias: "al2023@v20250801"
  instanceProfile: "{{ $.Values.karpenter.instance_profile }}"
  securityGroupSelectorTerms:
  - tags:
      "{{ $.Values.karpenter.discovery_key }}": "{{ $.Values.karpenter.discovery_value }}"
  subnetSelectorTerms:
  - tags:
      "{{ $.Values.karpenter.discovery_key }}": "{{ $.Values.karpenter.discovery_value }}"
      "kubernetes.io/cluster/{{$.Values.cluster_name}}": shared
      {{- /* specific to nuon's public cloudformation template */}}
      "network.nuon.co/domain": internal
  tags:
    "{{ $.Values.karpenter.discovery_key }}": "{{ $.Values.karpenter.discovery_value }}"
{{- end }}

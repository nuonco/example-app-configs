{{- range .Values.nodepools }}
---
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  annotations:
  labels:
    pool.nuon.co: "{{ .name }}"
  name: "{{ .name }}"
spec:
  disruption:
    {{/* allows up to 10% of notes to rotate during the 4 hours between (1000 UTC to 1400 UTC); and only one at a time otherwise. */}}
    budgets:
    - nodes: "10%"
    - nodes: "1"
      duration: 20h
      reasons:
      - Underutilized
      - Empty
      - Drifted
      schedule: 0 14 * * *  # https://crontab.guru/#0_8_*_*_*
    consolidateAfter: 5m
    consolidationPolicy: WhenEmptyOrUnderutilized
  limits:
    cpu: {{ .limits.cpu }}
    memory: {{ .limits.memory }}
  template:
    metadata:
      labels:
        pool.nuon.co: "{{ .name }}"
    spec:
      expireAfter: {{ .expireAfter }}
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: {{ .name }}
      requirements:
      - key: karpenter.sh/capacity-type
        operator: In
        values:
        - on-demand
      - key: node.kubernetes.io/instance-type
        operator: In
        values: {{ .instance_types }}
      - key: topology.kubernetes.io/zone
        operator: In
        values:
        - {{ $.Values.region }}a
        - {{ $.Values.region }}b
        - {{ $.Values.region }}c
      - key: pool.nuon.co
        operator: Exists
      - key: pool.nuon.co
        operator: In
        values:
        - "{{ .name }}"
      taints:
      - effect: NoSchedule
        key: pool.nuon.co
        value: {{ .name }}
{{- end}}

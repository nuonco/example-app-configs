---
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-kv-sync
  namespace: {{ .Values.namespace }}
spec:
  provider: azure
  secretObjects:
  - secretName: https-cert
    type: Opaque
    data:
    - objectName: https-cert
      key: https-cert
  parameters:
    useVMManagedIdentity: "true"
    keyvaultName: {{. Values.key_vault_name }}
    objects: |
      array:
        - |
          objectName: https-cert
          objectType: secret
  tenantId: {{ .Values.tenant_id }}

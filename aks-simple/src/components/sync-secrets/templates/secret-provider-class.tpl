---
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-kv-sync
  namespace: default
spec:
  provider: azure
  secretObjects:
  - secretName: https-cert
    type: Opaque
    data:
    - objectName: https-cert
      key: username
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"
    userAssignedIdentityID: "<client-id>"
    keyvaultName: "<your-key-vault-name>"
    objects: |
      array:
        - |
          objectName: foo
          objectType: secret
  tenantId: "<tenant-id>"

param nuonInstallID string
param location string = resourceGroup().location
param versioning string = 'false'

var accountName = 'st${uniqueString(resourceGroup().id, nuonInstallID)}'
var tags = {
  'install.nuon.co-id': nuonInstallID
  'nuon.co-stack': 'storage'
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: accountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  tags: tags
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    isVersioningEnabled: versioning == 'true'
  }
}

output name string = storageAccount.name
output id string = storageAccount.id
output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob

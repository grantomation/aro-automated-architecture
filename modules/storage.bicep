param location string
param storageAccountName string
param blobContainerName string
param fileName string
param azCliVersion string
param aadObjectId string
var blobDataContributorRole = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

resource storageAccount_resource 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_RAGRS'
  }
  kind: 'StorageV2'
  properties: {
    dnsEndpointType: 'Standard'
    defaultToOAuthAuthentication: false
    publicNetworkAccess: 'Enabled'
    allowCrossTenantReplication: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      requireInfrastructureEncryption: false
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource storageAccountBlob 'Microsoft.Storage/storageAccounts/blobServices@2022-05-01' = {
  parent: storageAccount_resource
  name: 'default'
  properties: {
    changeFeed: {
      enabled: false
    }
    restorePolicy: {
      enabled: false
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: true
      days: 7
    }
    isVersioningEnabled: false
  }
}

resource data_contributor_role 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, aadObjectId, deployment().name)
  properties: {
    principalId: aadObjectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', blobDataContributorRole)
  }
  dependsOn: [
    storageAccount_resource
  ]
}

resource storageAccountBlob_resource 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  parent: storageAccountBlob
  name: blobContainerName
  properties: {
    immutableStorageWithVersioning: {
      enabled: false
    }
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'Blob'
  }
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'deployscript-upload-aro-cse'
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: azCliVersion
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'AZURE_STORAGE_ACCOUNT'
        value: storageAccount_resource.name
      }
      {
        name: 'AZURE_STORAGE_KEY'
        secureValue: storageAccount_resource.listKeys().keys[0].value
      }
      {
        name: 'CONTENT'
        value: loadTextContent('../config_jumpbox/openshift.ps1')
      }
    ]
    scriptContent: 'echo "$CONTENT" > ${fileName} && az storage blob upload -f ${fileName} -c ${blobContainerName} -n ${fileName}'
  }
  dependsOn: [
    storageAccountBlob_resource
  ]
}

output blobEndpoint string = storageAccount_resource.properties.primaryEndpoints.blob
output blobContainerName string = blobContainerName
output fileName string = fileName

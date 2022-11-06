param location string
param aciName string
param aciSku string
param aciGroupName string
param loginServer string
param acrUserName string
param containerBuildName string
var aciImage = '${loginServer}/${containerBuildName}'
param identityId string
@secure()
param acrToken string
param aciSubnetName string
param hubVnetName string
param keyVaultUri string
param identityClientId string

resource aro_config_container 'Microsoft.ContainerInstance/containerGroups@2021-10-01' = {
  name: aciName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {
      }
    }
  }
  properties: {
    sku: aciSku
    containers: [
      {
        name: aciGroupName
        properties: {
          image: aciImage
          command: [
            '/data/openshift_config.sh'
          ]
          ports: [
            {
              protocol: 'TCP'
              port: 80
            }
          ]
          environmentVariables: [
            {
              name: 'IDENTITY_ID'
              secureValue: identityClientId
            }
            {
              name: 'KV_URI'
              secureValue: keyVaultUri
            }
          ]
          resources: {
            requests: {
              memoryInGB: 1
              cpu: 1
            }
          }
        }
      }
    ]
    initContainers: []
    imageRegistryCredentials: [
      {
        server: loginServer
        username: acrUserName
        password: acrToken
      }
    ]
    restartPolicy: 'OnFailure'
    ipAddress: {
      ports: [
        {
          protocol: 'TCP'
          port: 80
        }
      ]
      type: 'Private'
    }
    osType: 'Linux'
    subnetIds: [
      {
        id: resourceId('Microsoft.Network/VirtualNetworks/subnets', hubVnetName, aciSubnetName)
      }
    ]
  }
}

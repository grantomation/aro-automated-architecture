@description('Location of the resource')
param location string
param hubVnetName string
param hubVnetAddressPrefix string
param tags object

param azFwSubnetName string = 'AzureFirewallSubnet'
param azFwSubnetCidr string
param bastionSubnetName string = 'AzureBastionSubnet'
param bastionSubnetCidr string
param jumpboxSubnetName string
param jumpboxSubnetCidr string

resource utils_vnet 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: hubVnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVnetAddressPrefix
      ]
    }
    dhcpOptions: {
      dnsServers: []
    }
    subnets: [
      {
        name: azFwSubnetName
        properties: {
          addressPrefix: azFwSubnetCidr
        }
      }
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionSubnetCidr
        }
      }
      {
        name: jumpboxSubnetName
        properties: {
          addressPrefix: jumpboxSubnetCidr
        }
      }
    ]
  }
}

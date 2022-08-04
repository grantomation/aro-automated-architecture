param location string
param jumpbox_vm_name string
param hubVnetName string
param jumpboxSubnetName string
param jumpbox_vm_size string
param jumpbox_image_publisher string
param jumpbox_image_offer string
param jumpbox_image_sku string
param jumpbox_image_version string
param adminUsername string

@secure()
param adminPassword string

param clusterName string
param spoke_rg string

var nsg_name = '${jumpbox_vm_name}NSG'
var nsg_ip_config_name = 'ipconfig${jumpbox_vm_name}'
var nic_name = '${jumpbox_vm_name}NIC'

resource networkSecurityGroup_resource 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: nsg_name
  location: location
  properties: {
    securityRules: []
  }
}

resource networkInterface_resource 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: nic_name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: nsg_ip_config_name
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', hubVnetName, jumpboxSubnetName)
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    networkSecurityGroup: {
      id: networkSecurityGroup_resource.id
    }
  }
}

resource jumpbox_resource 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: jumpbox_vm_name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: jumpbox_vm_size
    }
    storageProfile: {
      imageReference: {
        publisher: jumpbox_image_publisher
        offer: jumpbox_image_offer
        sku: jumpbox_image_sku
        version: jumpbox_image_version
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    osProfile: {
      computerName: jumpbox_vm_name
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface_resource.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}

resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = {
  parent: jumpbox_resource
  name: 'CustomScriptExtension'
  location: location
  properties: {
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    settings: {
    }
    protectedSettings: {
      fileUris: [
        'https://raw.githubusercontent.com/grantomation/aro-cse/master/openshift.ps1'
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File openshift.ps1 -clusterName ${clusterName} -clusterRG ${spoke_rg}'
    }
  }
}

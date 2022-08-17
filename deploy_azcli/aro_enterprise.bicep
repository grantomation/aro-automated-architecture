targetScope = 'subscription'

@description('The Application ID of an Azure Active Directory client application')
param aadClientId string

@description('The secret of an Azure Active Directory client application')

@secure()
param aadClientSecret string

@description('The ObjectID of the Azure Active Directory Service Principal')
param aadObjectId string

@description('The ObjectID of the Azure Red Hat OpenShift RP Service Principal')
param rpObjectId string

@description('Location for your infrastructure')
param location string

@description('Name of the RG containing Utilities (hub)')
param spoke_rg string

@description('Name of the RG containing ARO cluster (spoke)')
param hub_rg string

@description('Name of vnet to store utilities')
param hubVnetName string

@description('Prefix of vnet to store utilities')
param hubVnetAddressPrefix string

@description('Prefix of Azure Firewall Subnet')
param azFwSubnetCidr string

@description('Prefix of Azure Bastion Subnet')
param bastionSubnetCidr string

@description('Name of Jumpbox Subnet')
param jumpboxSubnetName string

@description('Prefix of Jumpbox Subnet')
param jumpboxSubnetCidr string

@description('Tags for resource')
param tags object

@description('Name of ARO vNet')
param spokeVnetName string

@description('ARO vNet Address Space')
param spokeVnetCidr string

@description('Subnet name for control plane nodes')
param controlPlaneVnetName string

@description('Subnet cidr for control plane nodes subnet')
param controlPlaneSubnetCidr string

@description('Subnet name for compute/worker nodes')
param computeVnetName string

@description('Subnet cidr for dompute/worker node subnet')
param computeSubnetCidr string

@description('Pull secret from cloud.redhat.com. The json should be input as a string')
@secure()
param pullSecret string

@description('Api Server Visibility')
@allowed([
  'Private'
  'Public'
])
param apiServerVisibility string

@description('Ingress Visibility')
@allowed([
  'Private'
  'Public'
])
param ingressVisibility string

@description('Enable FIPS Modules [Enabled | Disabled]')
param fipsValidatedModules string

@description('Enable Encryption at host for controlPlane and compute nodes [Enabled | Disabled]')
param encryptionAtHost string

@description('Unique name for the ARO cluster')
param clusterName string

@description('Domain Prefix for ARO cluster')
param domain string

@description('Number of Compute Nodes')
@minValue(3)
param computeNodeCount int

@description('Compute Node Disk Size in GB')
@minValue(128)
param computeVmDiskSize int

@description('Control Plane Node VM Type')
param controlPlaneVmSize string

@description('Compute Node VM Type')
param computeVmSize string

@metadata({ decription: 'Cidr for Service network' })
param serviceCidr string

@description('Cidr for Pod network')
param podCidr string

@description('Name for the public IP of the bastion service')
param bastion_ip_name string

@description('Name for the bastion service')
param bastion_service_name string

@description('Name for the jumpbox vm')
param jumpbox_vm_name string
param jumpbox_vm_size string
param jumpbox_image_publisher string
param jumpbox_image_offer string
param jumpbox_image_sku string
param jumpbox_image_version string
param adminUsername string

@secure()
param adminPassword string

@description('Name for firewall public ip')
param fw_pip_name string

@description('FW PIP Sku Type')
param fw_pip_sku_type string

@description('FW PIP Sku tier name')
param fw_pip_tier_name string

@description('Name for firewall')
param azfw_name string = 'aro-fw'

@description('Firewall Sku name')
param azfw_sku_name string

@description('Firewall SKU')
param azfw_sku_tier string

@description('Firewall Threat Intel Mode')
param azfw_threat_intel_mode string

@description('Firewall enable dns')
param azfw_enable_dns string

@description('Firewall Private IP - first address of subnet')
param fwPrivateIP string

@description('Name of Route Table')
param routeTableName string

@description('Address prefix for route table')
param routeTableAddressPrefix string

@description('Next hop type')
param routeTableNextHopType string

resource spoke 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: spoke_rg
  location: location
}

resource hub 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: hub_rg
  location: location
}

module hub_networking '../modules/hub_network.bicep' = {
  name: 'hub-vnet'
  scope: resourceGroup(hub.name)
  params:{
    location: location
    hubVnetName: hubVnetName
    hubVnetAddressPrefix: hubVnetAddressPrefix
    tags: tags
    azFwSubnetCidr: azFwSubnetCidr
    bastionSubnetCidr: bastionSubnetCidr
    jumpboxSubnetName: jumpboxSubnetName
    jumpboxSubnetCidr: jumpboxSubnetCidr
  }
}

module spoke_networking '../modules/spoke_network.bicep' = {
  name: 'spoke-vnet'
  scope: resourceGroup(spoke_rg)
  params:{
    location: location
    spokeVnetName: spokeVnetName
    spokeVnetCidr: spokeVnetCidr
    controlPlaneSubnetCidr: controlPlaneSubnetCidr
    computeSubnetCidr: computeSubnetCidr
    controlPlaneVnetName: controlPlaneVnetName
    computeVnetName: computeVnetName
    tags: tags
    routeTableName: routeTableName
    spoke_rg: spoke_rg
  }
  dependsOn: [
    routing_table
  ]
}

module hub_peering '../modules/peering.bicep' = {
  name: 'hub-spoke-peering'
  scope: resourceGroup(hub.name)
  dependsOn: [
   hub_networking
   spoke_networking    
  ]
  params: {
    localVnetName: hubVnetName
    remoteVnetName: spokeVnetName
    rgToPeer: spoke_rg
  }
}

module spoke_peering '../modules/peering.bicep' = {
  name: 'spoke-hub-peering'
  scope: resourceGroup(spoke.name)
  dependsOn: [
    hub_networking
    spoke_networking    
   ]
  params: {
    localVnetName: spokeVnetName
    remoteVnetName: hubVnetName
    rgToPeer: hub_rg
  }
}

module aro_cluster '../modules/aro_cluster.bicep' = {
  name: 'aro-cluster'
  scope: resourceGroup(spoke.name)
  dependsOn: [
    spoke_networking
  ]
  params: {
    location: location
    pullSecret: pullSecret
    aadClientId: aadClientId
    aadClientSecret: aadClientSecret
    aadObjectId: aadObjectId
    apiServerVisibility: apiServerVisibility
    ingressVisibility: ingressVisibility
    spokeVnetName: spokeVnetName
    controlPlaneVnetName: controlPlaneVnetName
    computeVnetName: computeVnetName
    clusterName: clusterName
    computeNodeCount: computeNodeCount
    computeVmDiskSize: computeVmDiskSize
    computeVmSize: computeVmSize
    controlPlaneVmSize: controlPlaneVmSize
    domain: domain
    podCidr: podCidr
    serviceCidr: serviceCidr
    tags: tags
    fipsValidatedModules: fipsValidatedModules
    encryptionAtHost: encryptionAtHost
    rpObjectId: rpObjectId
    addSpRoleAssignment: 'no'
  }
}

module bastion '../modules/bastion.bicep' = {
  name: 'bastion-deployment'
  scope: resourceGroup(hub.name)
  dependsOn: [
    hub_networking
  ]
  params: {
    location: location
    bastion_ip_name: bastion_ip_name
    bastion_service_name: bastion_service_name
    hubVnetName: hubVnetName
  }
}

module jumpbox '../modules/jumpbox.bicep' = {
  name: 'jumpbox-deployment'
  scope: resourceGroup(hub.name)
  dependsOn: [
    hub_networking
  ]
  params:{
    location: location
    jumpbox_vm_name: jumpbox_vm_name
    jumpbox_vm_size: jumpbox_vm_size
    jumpbox_image_publisher: jumpbox_image_publisher
    jumpbox_image_offer: jumpbox_image_offer
    jumpbox_image_sku: jumpbox_image_sku
    jumpbox_image_version: jumpbox_image_version
    adminUsername: adminUsername
    adminPassword: adminPassword
    hubVnetName: hubVnetName
    jumpboxSubnetName: jumpboxSubnetName
    clusterName: clusterName
    spoke_rg: spoke_rg
  }
}

module firewall '../modules/firewall.bicep' = {
  name: 'firewall-deployment'
  scope: resourceGroup(hub.name)
  dependsOn: [
    hub_networking
  ]
  params:{
    location: location
    fw_pip_name: fw_pip_name
    fw_pip_sku_type: fw_pip_sku_type
    fw_pip_tier_name: fw_pip_tier_name
    azfw_name: azfw_name
    azfw_sku_name: azfw_sku_name
    azfw_sku_tier: azfw_sku_tier
    azfw_threat_intel_mode: azfw_threat_intel_mode
    azfw_enable_dns: azfw_enable_dns
    hubVnetName: hubVnetName
    fwPrivateIP: fwPrivateIP
  }
}

module routing_table '../modules/routing_table.bicep' = {
  name: routeTableName
  dependsOn: [
    firewall
  ]
  scope: resourceGroup(spoke_rg)
  params: {
    location: location
    routeTableName: routeTableName
    routeTableAddressPrefix: routeTableAddressPrefix
    routeTableNextHopType: routeTableNextHopType
    fwPrivateIP: fwPrivateIP

  }
}

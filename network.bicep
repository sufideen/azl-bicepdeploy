targetScope = 'subscription'

@description('The Azure region where the networking infrastructure will be provisioned.')
param location string = 'westeurope'

@description('The name of the core platform infrastructure resource group.')
param resourceGroupName string = 'rg-ict-connectivity-prod'

@description('The IP address space for the central Hub Virtual Network.')
param vnetAddressSpace string = '10.0.0.0/22'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
}

module hubNetwork 'br/public:avm/res/network/virtual-network:0.5.1' = {
  name: 'hub-vnet-deployment'
  scope: rg
  params: {
    name: 'vnet-ict-hub-prod'
    location: location
    addressPrefixes: [
      vnetAddressSpace
    ]
    subnets: [
      {
        // REQUIRED: Must be exactly this name to host Azure Firewall
        name: 'AzureFirewallSubnet'
        addressPrefix: '10.0.0.0/24'
      }
      {
        // REQUIRED: Must be exactly this name to host ExpressRoute or VPN Gateways
        name: 'GatewaySubnet'
        addressPrefix: '10.0.1.0/24'
      }
      {
        // REQUIRED: Must be exactly this name to host Azure Bastion jumpboxes
        name: 'AzureBastionSubnet'
        addressPrefix: '10.0.2.0/24'
      }
      {
        name: 'snet-shared-management'
        addressPrefix: '10.0.3.0/24'
      }
    ]
  }
}

output hubVnetId string = hubNetwork.outputs.resourceId
targetScope = 'resourceGroup'

@description('Name of the existing VNet.')
param vnetName string

@description('Name of the existing subnet within that VNet.')
param subnetName string

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  name: '${vnetName}/${subnetName}'
}

@description('Resource ID of the subnet.')
output subnetId string = subnet.id

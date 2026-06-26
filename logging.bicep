// This template deploys resources into a specific Resource Group
targetScope = 'resourceGroup'

@description('The name of the Log Analytics Workspace.')
param workspaceName string = 'log-ict-poc-shared'

@description('The Azure region where the workspace will be deployed.')
param location string = resourceGroup().location

@description('Number of days to retain log data. 30 days is the minimum and most cost-effective for PoCs.')
@allowed([
  30
  60
  90
  120
])
param retentionInDays int = 30

@description('The pricing tier SKU. PerGB2018 is the standard Pay-As-You-Go model.')
param skuName string = 'PerGB2018'

// Deploy the Log Analytics Workspace
resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: skuName
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Output the Workspace ID so other resources (like Firewalls or VMs) can reference it later
output workspaceId string = logWorkspace.id
output workspaceCustomerId string = logWorkspace.properties.customerId
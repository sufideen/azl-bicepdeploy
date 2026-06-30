targetScope = 'resourceGroup'

@description('Name of the Log Analytics Workspace.')
param workspaceName string

@description('Azure region. Inherits from the parent resource group when omitted.')
param location string = resourceGroup().location

@description('Number of days to retain log data.')
@allowed([30, 60, 90, 120])
param retentionInDays int = 30

@description('Pricing tier. PerGB2018 is standard Pay-As-You-Go.')
@allowed(['PerGB2018', 'CapacityReservation'])
param skuName string = 'PerGB2018'

// ── Log Analytics Workspace ───────────────────────────────────────────────────

resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: skuName
    }
    retentionInDays: retentionInDays
    features: {
      // Requires proper RBAC assignment for log access — disables legacy shared keys
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

@description('Full resource ID of the Log Analytics Workspace.')
output workspaceId string = logWorkspace.id

@description('Workspace GUID used by monitoring agents and diagnostic settings.')
output workspaceCustomerId string = logWorkspace.properties.customerId

@description('Resource name, for use in diagnostic setting references.')
output workspaceName string = logWorkspace.name

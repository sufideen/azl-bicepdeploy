targetScope = 'subscription'

@description('Name of the resource group that will hold the shared logging resources.')
param resourceGroupName string = 'rg-ict-management-poc'

@description('Azure region for all resources.')
param location string = 'westeurope'

@description('Name of the Log Analytics Workspace.')
param workspaceName string = 'log-ict-poc-shared'

@description('Number of days to retain log data. 30 days is the minimum; increase for regulated workloads.')
@allowed([30, 60, 90, 120])
param retentionInDays int = 30

@description('Log Analytics pricing tier.')
@allowed(['PerGB2018', 'CapacityReservation'])
param skuName string = 'PerGB2018'

// ── Resource Group ────────────────────────────────────────────────────────────

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: {
    layer: 'platform'
    component: 'logging'
    managedBy: 'bicep'
  }
}

// ── Log Analytics Workspace (deployed as a module scoped to the new RG) ───────

module logWorkspace './modules/log-workspace.bicep' = {
  name: 'log-workspace-deployment'
  scope: rg
  params: {
    workspaceName: workspaceName
    location: location
    retentionInDays: retentionInDays
    skuName: skuName
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

@description('Full resource ID of the Log Analytics Workspace.')
output workspaceId string = logWorkspace.outputs.workspaceId

@description('Workspace GUID for agent and diagnostic setting references.')
output workspaceCustomerId string = logWorkspace.outputs.workspaceCustomerId

@description('Resource group that holds the logging resources.')
output resourceGroupName string = rg.name

targetScope = 'subscription'

@description('Name of the resource group that will hold the shared logging resources.')
param resourceGroupName string = 'rg-ict-management-shared'

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

@description('Deploy the Windows Security Events DCR. Leave false on the first run — the SecurityEvent table takes a few minutes to provision after the Security solution is onboarded, and the DCR fails with InvalidOutputTable if it does not exist yet. Re-run with this set to true once the table is confirmed.')
param deploySecurityEventsDcr bool = false

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

// ── Data Sources: Azure Activity Log ───────────────────────────────────────────
// Connects the subscription's Activity Log to the workspace so it appears as a
// "Connected" data source instead of the placeholder "Next step" state.

module activityLogDiagnostics './modules/activity-log-diagnostics.bicep' = {
  name: 'activity-log-diagnostics-deployment'
  params: {
    workspaceId: logWorkspace.outputs.workspaceId
  }
}

// ── Data Sources: Windows Security Events ──────────────────────────────────────
// Onboards the Security solution first — it provisions the SecurityEvent table
// that the DCR's Microsoft-SecurityEvent output stream requires. The DCR fails
// with InvalidOutputTable if this hasn't run yet.

module securitySolution './modules/security-solution.bicep' = {
  name: 'security-solution-deployment'
  scope: rg
  params: {
    workspaceName: logWorkspace.outputs.workspaceName
    location: location
    workspaceId: logWorkspace.outputs.workspaceId
  }
}

// Creates the Data Collection Rule used by the Azure Monitor Agent. Associate
// it with VMs separately (Microsoft.Insights/dataCollectionRuleAssociations)
// to start ingesting Windows security events into this workspace. Gated by
// deploySecurityEventsDcr — see param description.

module securityEventsDcr './modules/security-events-dcr.bicep' = if (deploySecurityEventsDcr) {
  name: 'security-events-dcr-deployment'
  scope: rg
  params: {
    location: location
    workspaceId: logWorkspace.outputs.workspaceId
    workspaceName: logWorkspace.outputs.workspaceName
  }
  dependsOn: [
    securitySolution
  ]
}

// ── Outputs ───────────────────────────────────────────────────────────────────

@description('Full resource ID of the Log Analytics Workspace.')
output workspaceId string = logWorkspace.outputs.workspaceId

@description('Workspace GUID for agent and diagnostic setting references.')
output workspaceCustomerId string = logWorkspace.outputs.workspaceCustomerId

@description('Resource group that holds the logging resources.')
output resourceGroupName string = rg.name

@description('Resource ID of the subscription Activity Log diagnostic setting.')
output activityLogDiagnosticSettingId string = activityLogDiagnostics.outputs.diagnosticSettingId

@description('Resource ID of the Windows Security Events Data Collection Rule. Empty until deploySecurityEventsDcr=true is deployed.')
output securityEventsDcrId string = deploySecurityEventsDcr ? securityEventsDcr.outputs.dcrId : ''

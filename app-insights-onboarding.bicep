targetScope = 'subscription'

@description('Resource group containing the workload to onboard onto Application Insights.')
param workloadResourceGroupName string

@description('Name of the Application Insights component.')
param appInsightsName string

@description('Azure region for the Application Insights component.')
param location string = 'westeurope'

@description('Resource group holding the shared Log Analytics Workspace (deployed by logging.bicep).')
param managementResourceGroupName string = 'rg-ict-management-poc'

@description('Name of the shared Log Analytics Workspace (deployed by logging.bicep).')
param workspaceName string = 'log-ict-poc-shared'

// ── App Insights onboarding (scoped to the workload's own resource group) ──────
// Mirrors vm-onboarding.bicep: references pre-existing resource groups rather
// than creating them, so it is not reproducible in CI and stays lint-only there.

resource workloadResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  name: workloadResourceGroupName
}

resource existingWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  scope: resourceGroup(managementResourceGroupName)
  name: workspaceName
}

module appInsights './modules/app-insights.bicep' = {
  name: 'app-insights-deployment'
  scope: workloadResourceGroup
  params: {
    appInsightsName: appInsightsName
    location: location
    workspaceResourceId: existingWorkspace.id
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

@description('Resource ID of the Application Insights component.')
output appInsightsId string = appInsights.outputs.appInsightsId

@description('Connection string for SDK/agent configuration.')
output connectionString string = appInsights.outputs.connectionString

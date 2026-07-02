targetScope = 'resourceGroup'

@description('Name of the Application Insights component.')
param appInsightsName string

@description('Azure region. Inherits from the parent resource group when omitted.')
param location string = resourceGroup().location

@description('Resource ID of the Log Analytics Workspace this component is workspace-based against.')
param workspaceResourceId string

@description('Type of application being monitored.')
@allowed(['web', 'other'])
param applicationType string = 'web'

@description('Percentage of telemetry sampled. Lower this for high-volume applications to control cost.')
@minValue(0)
@maxValue(100)
param samplingPercentage int = 100

// ── Application Insights (workspace-based) ─────────────────────────────────────
// Workspace-based mode stores all telemetry in the shared Log Analytics workspace
// instead of a classic, standalone Application Insights store — one query surface
// for app telemetry, infrastructure logs, and security events.

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: applicationType == 'web' ? 'web' : 'other'
  properties: {
    Application_Type: applicationType
    WorkspaceResourceId: workspaceResourceId
    IngestionMode: 'LogAnalytics'
    SamplingPercentage: samplingPercentage
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

@description('Resource ID of the Application Insights component.')
output appInsightsId string = appInsights.id

@description('Connection string for SDK/agent configuration.')
output connectionString string = appInsights.properties.ConnectionString

@description('Instrumentation key. Prefer connectionString for new integrations.')
output instrumentationKey string = appInsights.properties.InstrumentationKey

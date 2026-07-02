targetScope = 'resourceGroup'

@description('Display name shown in the Azure Portal workbook gallery.')
param workbookDisplayName string = 'ALZ Platform Monitoring'

@description('Azure region. Inherits from the parent resource group when omitted.')
param location string = resourceGroup().location

@description('Resource ID of the Log Analytics Workspace the workbook queries.')
param workspaceResourceId string

// ── Monitoring Workbook (Performance / Availability / Cost tabs) ───────────────
// The workbook JSON is authored as a static file and templated at deploy time —
// loadTextContent() cannot itself reference Bicep params, so the workspace
// resource ID is injected via a placeholder token substitution instead.

var workbookContent = replace(
  loadTextContent('./workbook-content/platform-monitoring.workbook.json'),
  '__WORKSPACE_RESOURCE_ID__',
  workspaceResourceId
)

resource workbook 'Microsoft.Insights/workbooks@2023-06-01' = {
  name: guid(resourceGroup().id, workbookDisplayName)
  location: location
  kind: 'shared'
  properties: {
    displayName: workbookDisplayName
    serializedData: workbookContent
    sourceId: workspaceResourceId
    category: 'workbook'
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

@description('Resource ID of the workbook.')
output workbookId string = workbook.id

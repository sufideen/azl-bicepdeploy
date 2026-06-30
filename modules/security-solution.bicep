targetScope = 'resourceGroup'

@description('Name of the Log Analytics Workspace to onboard the Security solution onto.')
param workspaceName string

@description('Azure region. Inherits from the parent resource group when omitted.')
param location string = resourceGroup().location

@description('Resource ID of the Log Analytics Workspace.')
param workspaceId string

// ── Security Solution ────────────────────────────────────────────────────────
// Onboards the legacy "Security" solution onto the workspace. This is what
// provisions the SecurityEvent table — a Data Collection Rule targeting the
// Microsoft-SecurityEvent stream fails with InvalidOutputTable until this
// table exists.

resource securitySolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'Security(${workspaceName})'
  location: location
  plan: {
    name: 'Security(${workspaceName})'
    publisher: 'Microsoft'
    product: 'OMSGallery/Security'
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: workspaceId
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

@description('Resource ID of the Security solution.')
output securitySolutionId string = securitySolution.id

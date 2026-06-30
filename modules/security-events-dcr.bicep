targetScope = 'resourceGroup'

@description('Name of the Data Collection Rule.')
param dcrName string = 'dcr-windows-security-events'

@description('Azure region. Inherits from the parent resource group when omitted.')
param location string = resourceGroup().location

@description('Resource ID of the destination Log Analytics Workspace.')
param workspaceId string

@description('Name of the destination Log Analytics Workspace (used as the DCR data flow destination key).')
param workspaceName string

// ── Data Collection Rule ─────────────────────────────────────────────────────
// Collects Windows Security Event log entries via the Azure Monitor Agent
// and forwards them to the shared Log Analytics workspace. Associate this
// DCR with VMs (Microsoft.Insights/dataCollectionRuleAssociations) to
// activate the 'Windows security events' connected data source.

resource securityEventsDcr 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: dcrName
  location: location
  kind: 'Windows'
  properties: {
    dataSources: {
      windowsEventLogs: [
        {
          name: 'securityEventsDataSource'
          streams: [
            'Microsoft-SecurityEvent'
          ]
          xPathQueries: [
            'Security!*'
          ]
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          name: workspaceName
          workspaceResourceId: workspaceId
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-SecurityEvent'
        ]
        destinations: [
          workspaceName
        ]
      }
    ]
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

@description('Resource ID of the Data Collection Rule.')
output dcrId string = securityEventsDcr.id

@description('Resource name of the Data Collection Rule.')
output dcrName string = securityEventsDcr.name

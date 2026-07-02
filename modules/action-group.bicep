targetScope = 'resourceGroup'

@description('Name of the Action Group.')
param actionGroupName string

@description('Short name shown in SMS/notification headers. Capped at 12 characters by the resource provider.')
@maxLength(12)
param actionGroupShortName string

@description('Email recipients for alert notifications.')
param emailReceivers array = []

@description('Webhook recipients for alert notifications (e.g. a Teams incoming webhook or Power Automate flow URL). Raw Azure Monitor common-alert-schema JSON will not render as a formatted card in Teams without a transformation flow.')
param webhookReceivers array = []

@description('Whether the Action Group is active. Set false to silence all alerts routed through it without deleting the resource.')
param enabled bool = true

// ── Action Group ─────────────────────────────────────────────────────────────
// Shared notification target referenced by every alert rule in monitoring.bicep
// (Service Health, budget, resource-utilization metric alerts).

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: 'global'
  properties: {
    groupShortName: actionGroupShortName
    enabled: enabled
    emailReceivers: [for r in emailReceivers: {
      name: r.name
      emailAddress: r.email
      useCommonAlertSchema: true
    }]
    webhookReceivers: [for r in webhookReceivers: {
      name: r.name
      serviceUri: r.uri
      useCommonAlertSchema: true
    }]
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

@description('Resource ID of the Action Group.')
output actionGroupId string = actionGroup.id

@description('Name of the Action Group.')
output actionGroupName string = actionGroup.name

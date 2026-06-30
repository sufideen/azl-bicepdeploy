targetScope = 'subscription'

@description('Resource ID of the Log Analytics Workspace that will receive the subscription Activity Log.')
param workspaceId string

@description('Name of the diagnostic setting.')
param diagnosticSettingName string = 'activity-log-to-log-analytics'

// ── Activity Log Diagnostic Setting ────────────────────────────────────────────
// Subscription-scoped: streams the Azure Activity Log (Administrative, Security,
// ServiceHealth, Alert, Recommendation, Policy, Autoscale, ResourceHealth) into
// the shared Log Analytics workspace so it shows up as a connected data source.

resource activityLogDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: diagnosticSettingName
  scope: subscription()
  properties: {
    workspaceId: workspaceId
    logs: [
      { category: 'Administrative', enabled: true }
      { category: 'Security', enabled: true }
      { category: 'ServiceHealth', enabled: true }
      { category: 'Alert', enabled: true }
      { category: 'Recommendation', enabled: true }
      { category: 'Policy', enabled: true }
      { category: 'Autoscale', enabled: true }
      { category: 'ResourceHealth', enabled: true }
    ]
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

@description('Resource ID of the Activity Log diagnostic setting.')
output diagnosticSettingId string = activityLogDiagnostics.id

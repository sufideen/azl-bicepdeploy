targetScope = 'resourceGroup'

@description('Name of the Activity Log Alert.')
param alertName string = 'alz-service-health'

@description('Resource ID of the Action Group to notify.')
param actionGroupId string

@description('Whether the alert rule is active.')
param enabled bool = true

// ── Service Health Activity Log Alert ────────────────────────────────────────
// Activity Log Alerts are a distinct resource type from diagnostic settings —
// streaming ServiceHealth events into Log Analytics (activity-log-diagnostics.bicep)
// makes them queryable, but only this resource actually fires a notification.
// Must be deployed with location 'global' regardless of the parent resource group's region.

resource serviceHealthAlert 'Microsoft.Insights/activityLogAlerts@2020-10-01' = {
  name: alertName
  location: 'global'
  properties: {
    enabled: enabled
    scopes: [
      subscription().id
    ]
    condition: {
      allOf: [
        {
          field: 'category'
          equals: 'ServiceHealth'
        }
      ]
    }
    actions: {
      actionGroups: [
        {
          actionGroupId: actionGroupId
        }
      ]
    }
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

@description('Resource ID of the Service Health Activity Log Alert.')
output activityLogAlertId string = serviceHealthAlert.id

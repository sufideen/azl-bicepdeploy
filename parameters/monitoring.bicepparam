using '../monitoring.bicep'

// ── Platform Monitoring Parameters ────────────────────────────────────────────
// Deploys the Action Group, Service Health alert, cost budget, resource
// utilization alerts, and platform monitoring workbook into their own resource
// group. Depends on logging.bicep having already deployed the shared workspace.

param resourceGroupName           = 'rg-ict-monitoring-poc'
param location                    = 'westeurope'
param managementResourceGroupName = 'rg-ict-management-poc'
param workspaceName               = 'log-ict-poc-shared'
param actionGroupName             = 'ag-ict-platform-alerts'
param actionGroupShortName        = 'platformops'

// Replace with the real platform team distribution list before deploying.
param alertEmailReceivers = [
  {
    name: 'platform-team'
    email: 'platform-team@example.com'
  }
]

param alertWebhookReceivers = []

// Replace with the real monthly budget ceiling before deploying.
param budgetAmount     = 1000
param budgetStartDate  = '2026-07-01'

// Empty until real resource IDs (VMs, Firewall, etc.) are populated —
// see modules/metric-alert.bicep for the entry shape.
param resourceUtilizationAlerts = []

param workbookDisplayName = 'ALZ Platform Monitoring'

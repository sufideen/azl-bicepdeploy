targetScope = 'subscription'

@description('Name of the resource group that will hold the monitoring, alerting, and dashboard resources.')
param resourceGroupName string = 'rg-ict-monitoring-poc'

@description('Azure region for all resources.')
param location string = 'westeurope'

@description('Name of the resource group holding the shared Log Analytics Workspace (deployed by logging.bicep).')
param managementResourceGroupName string = 'rg-ict-management-poc'

@description('Name of the shared Log Analytics Workspace (deployed by logging.bicep).')
param workspaceName string = 'log-ict-poc-shared'

@description('Name of the Action Group that receives all alert notifications.')
param actionGroupName string = 'ag-ict-platform-alerts'

@description('Short name for the Action Group, capped at 12 characters.')
@maxLength(12)
param actionGroupShortName string = 'platformops'

@description('Email recipients for alert notifications, e.g. [{ name: \'platform-team\', email: \'platform-team@example.com\' }].')
param alertEmailReceivers array

@description('Webhook recipients for alert notifications (e.g. a Teams incoming webhook).')
param alertWebhookReceivers array = []

@description('Monthly subscription budget amount, in the billing currency.')
param budgetAmount int

@description('First day of the budget period, formatted YYYY-MM-01.')
param budgetStartDate string

@description('Resource-utilization metric alerts to create. Each entry: { alertName, targetResourceId, metricName, metricNamespace, operator, threshold, severity }. Defaults to empty so the pipeline stays green until real resource IDs are populated.')
param resourceUtilizationAlerts array = []

@description('Display name for the platform monitoring workbook.')
param workbookDisplayName string = 'ALZ Platform Monitoring'

// ── Existing Log Analytics Workspace (deployed by logging.bicep) ──────────────
// This repo does not chain outputs across separate `az deployment` invocations —
// each stage looks up its dependency by well-known name, same as vm-onboarding.bicep
// does with its target resource group. Note this means the workspace must already
// be LIVE in the subscription — a What-If run of logging.bicep does not create it,
// so on a brand-new subscription logging.bicep must be deployed for real (az
// deployment sub create) before this template's own What-If/deploy will resolve.

resource existingWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  scope: resourceGroup(managementResourceGroupName)
  name: workspaceName
}

// ── Resource Group ────────────────────────────────────────────────────────────

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: {
    layer: 'platform'
    component: 'monitoring'
    managedBy: 'bicep'
  }
}

// ── Action Group ──────────────────────────────────────────────────────────────
// Shared notification target for every alert rule deployed below.

module actionGroup './modules/action-group.bicep' = {
  name: 'action-group-deployment'
  scope: rg
  params: {
    actionGroupName: actionGroupName
    actionGroupShortName: actionGroupShortName
    emailReceivers: alertEmailReceivers
    webhookReceivers: alertWebhookReceivers
  }
}

// ── Service Health Alert ─────────────────────────────────────────────────────
// Notifies the Action Group whenever Azure posts a Service Health event for
// this subscription (incidents, planned maintenance, health advisories).

module serviceHealthAlert './modules/service-health-alert.bicep' = {
  name: 'service-health-alert-deployment'
  scope: rg
  params: {
    actionGroupId: actionGroup.outputs.actionGroupId
  }
}

// ── Cost Budget ───────────────────────────────────────────────────────────────
// Subscription-scoped: notifies the Action Group at 80% actual spend and 100%
// forecasted spend.

module budgetAlert './modules/budget-alert.bicep' = {
  name: 'budget-alert-deployment'
  params: {
    budgetName: 'budget-ict-platform-monthly'
    amount: budgetAmount
    startDate: budgetStartDate
    actionGroupId: actionGroup.outputs.actionGroupId
  }
}

// ── Resource Utilization Alerts ──────────────────────────────────────────────
// Array-driven so new alert targets are added by extending a parameter list,
// not by writing new Bicep. Empty by default — see resourceUtilizationAlerts.

module utilizationAlerts './modules/metric-alert.bicep' = [for (a, i) in resourceUtilizationAlerts: {
  name: 'metric-alert-deployment-${i}'
  scope: rg
  params: {
    alertName: a.alertName
    targetResourceId: a.targetResourceId
    metricName: a.metricName
    metricNamespace: a.metricNamespace
    operator: a.operator
    threshold: a.threshold
    severity: a.severity
    actionGroupId: actionGroup.outputs.actionGroupId
  }
}]

// ── Platform Monitoring Workbook ─────────────────────────────────────────────
// Tabbed Performance / Availability / Cost views against the shared workspace.

module workbook './modules/monitoring-workbook.bicep' = {
  name: 'monitoring-workbook-deployment'
  scope: rg
  params: {
    workbookDisplayName: workbookDisplayName
    location: location
    workspaceResourceId: existingWorkspace.id
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

@description('Resource group that holds the monitoring resources.')
output resourceGroupName string = rg.name

@description('Resource ID of the Action Group.')
output actionGroupId string = actionGroup.outputs.actionGroupId

@description('Resource ID of the Service Health Activity Log Alert.')
output activityLogAlertId string = serviceHealthAlert.outputs.activityLogAlertId

@description('Resource ID of the subscription budget.')
output budgetId string = budgetAlert.outputs.budgetId

@description('Resource ID of the platform monitoring workbook.')
output workbookId string = workbook.outputs.workbookId

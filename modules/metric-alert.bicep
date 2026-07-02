targetScope = 'resourceGroup'

@description('Name of the metric alert.')
param alertName string

@description('Resource ID of the resource the alert monitors, e.g. a VM, Firewall, or App Service.')
param targetResourceId string

@description('Name of the metric to evaluate, e.g. "Percentage CPU".')
param metricName string

@description('Metric namespace of the target resource, e.g. "Microsoft.Compute/virtualMachines".')
param metricNamespace string

@description('Comparison operator for the threshold.')
@allowed(['GreaterThan', 'GreaterThanOrEqual', 'LessThan', 'LessThanOrEqual'])
param operator string = 'GreaterThan'

@description('Threshold value that triggers the alert.')
param threshold int

@description('Alert severity: 0 (critical) to 4 (verbose).')
@allowed([0, 1, 2, 3, 4])
param severity int = 2

@description('How often the metric is evaluated, in ISO 8601 duration format.')
param evaluationFrequency string = 'PT5M'

@description('The rolling time window the metric is aggregated over, in ISO 8601 duration format.')
param windowSize string = 'PT15M'

@description('Resource ID of the Action Group to notify.')
param actionGroupId string

@description('Whether Azure Monitor automatically resolves the alert when the condition is no longer met.')
param autoMitigate bool = true

// ── Metric Alert ──────────────────────────────────────────────────────────────
// Generic single-resource, single-criterion metric alert. monitoring.bicep loops
// this module over a resourceUtilizationAlerts array so new alert targets are
// added by extending a parameter list, not by writing new Bicep.

resource metricAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: alertName
  location: 'global'
  properties: {
    description: 'Resource utilization alert for ${targetResourceId}'
    severity: severity
    enabled: true
    scopes: [
      targetResourceId
    ]
    evaluationFrequency: evaluationFrequency
    windowSize: windowSize
    autoMitigate: autoMitigate
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'metric1'
          metricName: metricName
          metricNamespace: metricNamespace
          operator: operator
          threshold: threshold
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroupId
      }
    ]
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

@description('Resource ID of the metric alert.')
output metricAlertId string = metricAlert.id

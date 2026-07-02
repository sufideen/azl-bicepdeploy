targetScope = 'subscription'

@description('Name of the budget.')
param budgetName string

@description('Monthly spend threshold in the subscription\'s billing currency.')
param amount int

@description('Budget evaluation cadence.')
@allowed(['Monthly', 'Quarterly', 'Annually'])
param timeGrain string = 'Monthly'

@description('First day of the budget period, formatted YYYY-MM-01. Must be in the past or present, never in the future.')
param startDate string

@description('Resource ID of the Action Group to notify when thresholds are crossed.')
param actionGroupId string

@description('Additional email addresses to notify directly, alongside the Action Group.')
param contactEmails array = []

// ── Cost Budget ───────────────────────────────────────────────────────────────
// Subscription-scoped: Microsoft.Consumption/budgets has no resource group concept.
// Two notification thresholds: an early warning on actual spend, and a hard
// forecast warning before the period even closes.

resource budget 'Microsoft.Consumption/budgets@2021-10-01' = {
  name: budgetName
  properties: {
    category: 'Cost'
    amount: amount
    timeGrain: timeGrain
    timePeriod: {
      startDate: startDate
    }
    notifications: {
      Actual_GreaterThan_80_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        thresholdType: 'Actual'
        contactEmails: contactEmails
        contactGroups: [
          actionGroupId
        ]
      }
      Forecasted_GreaterThan_100_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        thresholdType: 'Forecasted'
        contactEmails: contactEmails
        contactGroups: [
          actionGroupId
        ]
      }
    }
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

@description('Resource ID of the budget.')
output budgetId string = budget.id

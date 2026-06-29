using '../logging.bicep'

// ── Platform Logging Parameters ───────────────────────────────────────────────
// Deploys the shared Log Analytics Workspace into its own resource group.
// Increase retentionInDays to 90 or 120 for regulated / production workloads.

param resourceGroupName = 'rg-ict-management-shared'
param location         = 'westeurope'
param workspaceName    = 'log-ict-poc-shared'
param retentionInDays  = 30
param skuName          = 'PerGB2018'

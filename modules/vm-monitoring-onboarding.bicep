targetScope = 'resourceGroup'

@description('Names of existing VMs in this resource group to onboard onto Azure Monitor Agent.')
param vmNames array

@description('OS type of the VMs in vmNames. Mixed-OS resource groups need separate deployments per OS.')
@allowed(['Windows', 'Linux'])
param osType string = 'Windows'

@description('Resource ID of the Data Collection Rule to associate (e.g. the Windows Security Events DCR).')
param dataCollectionRuleId string

// ── Azure Monitor Agent extension (per VM) ──────────────────────────────────────
// Installs the agent that actually ships log/metric data. Without this, a DCR
// association alone ingests nothing.

resource vms 'Microsoft.Compute/virtualMachines@2024-07-01' existing = [for vmName in vmNames: {
  name: vmName
}]

resource amaExtension 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = [for (vmName, i) in vmNames: {
  parent: vms[i]
  name: osType == 'Windows' ? 'AzureMonitorWindowsAgent' : 'AzureMonitorLinuxAgent'
  location: vms[i].location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: osType == 'Windows' ? 'AzureMonitorWindowsAgent' : 'AzureMonitorLinuxAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}]

// ── Data Collection Rule association (per VM) ───────────────────────────────────
// Binds each VM to the DCR so the agent knows what to collect and where to send it.

resource dcrAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2023-03-11' = [for (vmName, i) in vmNames: {
  name: 'dcra-${vmName}'
  scope: vms[i]
  properties: {
    dataCollectionRuleId: dataCollectionRuleId
  }
  dependsOn: [
    amaExtension[i]
  ]
}]

// ── Outputs ───────────────────────────────────────────────────────────────────

@description('Names of VMs successfully onboarded.')
output onboardedVmNames array = vmNames

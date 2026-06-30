targetScope = 'subscription'

@description('Resource group containing the VMs to onboard.')
param vmResourceGroupName string

@description('Names of existing VMs to onboard onto Azure Monitor Agent.')
param vmNames array

@description('OS type of the VMs in vmNames. Mixed-OS resource groups need two separate deployments.')
@allowed(['Windows', 'Linux'])
param osType string = 'Windows'

@description('Resource ID of the Data Collection Rule to associate (output of logging.bicep: securityEventsDcrId).')
param dataCollectionRuleId string

// ── VM onboarding (scoped to the VMs' own resource group) ──────────────────────

resource vmResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  name: vmResourceGroupName
}

module vmOnboarding './modules/vm-monitoring-onboarding.bicep' = {
  name: 'vm-monitoring-onboarding-deployment'
  scope: vmResourceGroup
  params: {
    vmNames: vmNames
    osType: osType
    dataCollectionRuleId: dataCollectionRuleId
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

output onboardedVmNames array = vmOnboarding.outputs.onboardedVmNames

targetScope = 'subscription'

@description('Resource group that hosts the hub VNet (network.bicep default: rg-ict-connectivity-prod).')
param vnetResourceGroupName string = 'rg-ict-connectivity-prod'

@description('Name of the existing hub VNet (network.bicep default: vnet-ict-hub-prod).')
param vnetName string = 'vnet-ict-hub-prod'

@description('Name of the existing subnet to deploy the test VM into.')
param subnetName string = 'snet-shared-management'

@description('Azure region. Should match the region of the target subnet.')
param location string = 'westeurope'

@description('Name of the test VM.')
param vmName string = 'vm-loganalytics-test'

@description('Local administrator username for the test VM.')
param adminUsername string = 'azureadmin'

@description('Local administrator password for the test VM.')
@secure()
param adminPassword string

@description('Resource ID of the Data Collection Rule to associate (logging.bicep output: securityEventsDcrId).')
param dataCollectionRuleId string

// ── Test VM (deployed into the existing hub VNet's resource group) ─────────────

resource targetRg 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  name: vnetResourceGroupName
}

module subnetLookup './modules/subnet-id-lookup.bicep' = {
  name: 'subnet-id-lookup-deployment'
  scope: targetRg
  params: {
    vnetName: vnetName
    subnetName: subnetName
  }
}

module testVm './modules/test-vm.bicep' = {
  name: 'log-analytics-test-vm-deployment'
  scope: targetRg
  params: {
    vmName: vmName
    location: location
    subnetId: subnetLookup.outputs.subnetId
    adminUsername: adminUsername
    adminPassword: adminPassword
    dataCollectionRuleId: dataCollectionRuleId
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

@description('Resource ID of the test VM — delete this resource once the ingestion test is done.')
output testVmId string = testVm.outputs.vmId

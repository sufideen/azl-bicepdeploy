targetScope = 'resourceGroup'

@description('Name of the test VM. Keep it identifiable so it is easy to find and delete later.')
param vmName string = 'vm-loganalytics-test'

@description('Azure region. Inherits from the parent resource group when omitted.')
param location string = resourceGroup().location

@description('Resource ID of the existing subnet to attach the VM to (no public IP is created).')
param subnetId string

@description('Local administrator username for the test VM.')
param adminUsername string

@description('Local administrator password for the test VM.')
@secure()
param adminPassword string

@description('Resource ID of the Data Collection Rule to associate (logging.bicep output: securityEventsDcrId).')
param dataCollectionRuleId string

@description('VM size. B2s is the cheapest burstable size suitable for a short-lived ingestion test.')
param vmSize string = 'Standard_B2s'

var tags = {
  purpose: 'log-analytics-ingestion-test'
  temporary: 'true'
}

// ── Network Interface (no public IP — reach it via Bastion or Run Command) ────

resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: 'nic-${vmName}'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// ── Virtual Machine (Windows, to exercise the Security Events data source) ────

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: vmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

// ── Azure Monitor Agent ─────────────────────────────────────────────────────────

resource amaExtension 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = {
  parent: vm
  name: 'AzureMonitorWindowsAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}

// ── Data Collection Rule association ────────────────────────────────────────────

resource dcrAssociation 'Microsoft.Insights/dataCollectionRuleAssociations@2023-03-11' = {
  name: 'dcra-${vmName}'
  scope: vm
  properties: {
    dataCollectionRuleId: dataCollectionRuleId
  }
  dependsOn: [
    amaExtension
  ]
}

// ── Outputs ───────────────────────────────────────────────────────────────────

@description('Resource ID of the test VM — use this to delete it once the test is done.')
output vmId string = vm.id

@description('Resource name of the test VM.')
output vmName string = vm.name

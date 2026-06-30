// ════════════════════════════════════════════════════════════════════════════
// modules/test-vm.bicep
//
// A TEMPORARY Windows VM used only to validate that Windows Security Events
// flow into the Log Analytics workspace via the Azure Monitor Agent (AMA)
// and the Data Collection Rule (DCR). Delete it once the ingestion test
// passes — it is not part of the permanent landing zone.
//
// This file doubles as a small Bicep teaching example: params → resources →
// outputs, with comments explaining the "why" behind each construct.
// ════════════════════════════════════════════════════════════════════════════

targetScope = 'resourceGroup'

@description('Name of the test VM. Keep it identifiable so it is easy to find and delete later.')
param vmName string = 'vm-loganalytics-test'

@description('Azure region. Inherits from the parent resource group when omitted.')
param location string = resourceGroup().location

@description('Resource ID of the existing subnet to attach the VM to (no public IP is created).')
param subnetId string

@description('Local administrator username for the test VM.')
param adminUsername string

// ── Secure password handling ───────────────────────────────────────────────
// @secure() does two things:
//   1. ARM redacts this parameter's value everywhere it would otherwise
//      show up — deployment history, the Activity Log, `az deployment ...
//      show` output. It never appears in plaintext after you submit it.
//   2. Bicep refuses to compile a literal default for a @secure() param
//      (`= 'something'` is a hard error), so a password can never
//      accidentally get committed to source control.
//
// Because there's no default, the caller MUST supply it at deploy time.
// Don't pass it inline as `--parameters adminPassword='MyPassword123!'` —
// that string lands in your shell history and terminal scrollback in
// plaintext. Instead, prompt for it so it's typed but never displayed or
// stored:
//
//   read -s -p "Admin password: " VM_PASSWORD; echo
//   az deployment sub create --location westeurope \
//     --template-file test-vm-deploy.bicep \
//     --parameters adminPassword="$VM_PASSWORD" dataCollectionRuleId=<id>
//
// Or, since this is a throwaway test VM you'll delete shortly, generate a
// random one you never even need to remember:
//
//   VM_PASSWORD=$(openssl rand -base64 16)
//   az deployment sub create --location westeurope \
//     --template-file test-vm-deploy.bicep \
//     --parameters adminPassword="$VM_PASSWORD" dataCollectionRuleId=<id>
//
// Either way, unset VM_PASSWORD (or close the shell) once the deployment
// finishes.
@description('Local administrator password for the test VM. No default on purpose — see comment above for how to supply it without it ending up in shell history.')
@secure()
param adminPassword string

@description('Resource ID of the Data Collection Rule to associate (logging.bicep output: securityEventsDcrId).')
param dataCollectionRuleId string

@description('VM size. B2s is the cheapest burstable size suitable for a short-lived ingestion test.')
param vmSize string = 'Standard_B2s'

// Tags make it obvious — to you and to anyone else browsing the
// subscription — that this resource is disposable and why it exists.
var tags = {
  purpose: 'log-analytics-ingestion-test'
  temporary: 'true'
}

// ── Network Interface ──────────────────────────────────────────────────────
// No public IP is created. The VM is reachable only from inside the VNet —
// e.g. via Azure Bastion or `az vm run-command invoke` — since a short-lived
// test box has no reason to be exposed to the internet.
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

// ── Virtual Machine ─────────────────────────────────────────────────────────
// Windows Server 2022 (Azure Edition) — the Windows Security Events data
// source we're validating only applies to Windows VMs.
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
      // References the @secure() param above — Bicep keeps the value out
      // of deployment history end-to-end, not just at the param boundary.
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

// ── Azure Monitor Agent extension ───────────────────────────────────────────
// `parent: vm` makes this a child resource of the VM (equivalent to naming
// it 'vmName/AzureMonitorWindowsAgent'). AMA is what actually collects
// Windows Event Log data on the box and ships it to whatever DCR it's
// associated with below.
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

// ── Data Collection Rule association ────────────────────────────────────────
// This is the link that tells AMA on this specific VM "use this DCR" —
// without it, the agent is installed but has no rule telling it what to
// collect or where to send it. `dependsOn: [amaExtension]` ensures the
// agent exists on the VM before we try to associate a rule with it.
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

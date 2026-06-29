using '../network.bicep'

// ── Hub Network Parameters ────────────────────────────────────────────────────
// Deploys the central Hub VNet with four reserved subnets into its own resource
// group. The hubVnetId output is consumed by spoke VNet peering modules.

param location          = 'westeurope'
param resourceGroupName = 'rg-ict-connectivity-prod'
param vnetAddressSpace  = '10.0.0.0/22'

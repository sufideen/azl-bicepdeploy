targetScope = 'tenant'

@description('Short prefix applied to every management group name. Change once here to rename the entire hierarchy.')
param orgPrefix string = 'corp'

@description('Human-readable display name for the root management group shown in the Azure Portal.')
param orgDisplayName string = 'Contoso Holdings'

// ── Root ─────────────────────────────────────────────────────────────────────

resource rootMg 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: orgPrefix
  properties: {
    displayName: orgDisplayName
  }
}

// ── Platform tier (children of root) ─────────────────────────────────────────

resource platformMg 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${orgPrefix}-platform'
  properties: {
    displayName: 'Platform'
    details: {
      parent: {
        id: rootMg.id
      }
    }
  }
}

resource connectivityMg 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${orgPrefix}-connectivity'
  properties: {
    displayName: 'Connectivity (Hub Networks, Firewalls)'
    details: {
      parent: {
        id: platformMg.id
      }
    }
  }
}

resource identityMg 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${orgPrefix}-identity'
  properties: {
    displayName: 'Identity (Active Directory, Key Vaults)'
    details: {
      parent: {
        id: platformMg.id
      }
    }
  }
}

resource managementMg 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${orgPrefix}-management'
  properties: {
    displayName: 'Management (Log Analytics, Automation)'
    details: {
      parent: {
        id: platformMg.id
      }
    }
  }
}

// ── Workloads tier (children of root) ────────────────────────────────────────

resource workloadsMg 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${orgPrefix}-workloads'
  properties: {
    displayName: 'Workloads'
    details: {
      parent: {
        id: rootMg.id
      }
    }
  }
}

resource productionMg 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${orgPrefix}-production'
  properties: {
    displayName: 'Production Application Environments'
    details: {
      parent: {
        id: workloadsMg.id
      }
    }
  }
}

resource nonprodMg 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${orgPrefix}-nonprod'
  properties: {
    displayName: 'Non-Production / Testing Environments'
    details: {
      parent: {
        id: workloadsMg.id
      }
    }
  }
}

// ── Lifecycle nodes (children of root) ───────────────────────────────────────

resource sandboxMg 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${orgPrefix}-sandbox'
  properties: {
    displayName: 'Sandbox (Developer Playgrounds)'
    details: {
      parent: {
        id: rootMg.id
      }
    }
  }
}

resource decommissionedMg 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: '${orgPrefix}-decommissioned'
  properties: {
    displayName: 'Decommissioned / Legacy Resources'
    details: {
      parent: {
        id: rootMg.id
      }
    }
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

output rootManagementGroupId string = rootMg.id
output connectivityManagementGroupId string = connectivityMg.id
output managementManagementGroupId string = managementMg.id
output workloadsManagementGroupId string = workloadsMg.id

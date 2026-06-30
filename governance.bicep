targetScope = 'managementGroup'

@description('The Management Group ID being targeted. Used to namespace the assignment name. The actual deployment scope is set via --management-group-id in the CLI/pipeline.')
param managementGroupId string = 'corp-workloads'

@description('List of Azure regions where resource deployment is permitted. All other regions are denied.')
param allowedLocations array = [
  'westeurope'
  'uksouth'
]

// ── Data Residency Policy Assignment ─────────────────────────────────────────
// Built-in policy: Allowed Locations (e56962a6-4747-49cd-b67b-bf8b01975c4c)
// Effect: Deny — hard block, not audit-only.

resource locationPolicyAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  // Policy assignment names are capped at 24 characters — keep this short and
  // fixed rather than namespacing by managementGroupId.
  name: 'alz-allowed-locations'
  scope: managementGroup()
  properties: {
    displayName: 'Enforce Regional Data Residency Guardrails'
    description: 'Restricts resource deployments strictly to approved enterprise regions. Supports GDPR and UK data protection obligations.'
    policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', 'e56962a6-4747-49cd-b67b-bf8b01975c4c')
    parameters: {
      listOfAllowedLocations: {
        value: allowedLocations
      }
    }
    enforcementMode: 'Default'
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

output policyAssignmentId string = locationPolicyAssignment.id
output policyAssignmentName string = locationPolicyAssignment.name
targetScope = 'managementGroup'

@description('The Management Group ID where policies will be assigned.')
param managementGroupId string = 'ict-workloads'

// Reference an existing built-in policy definition: Allowed Locations
resource locationPolicyAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'alz-allowed-locations'
  scope: managementGroup()
  properties: {
    displayName: 'Enforce Regional Data Residency Guardrails'
    description: 'Restricts resource deployments strictly to approved enterprise regions.'
    policyDefinitionId: tenantResourceId('Microsoft.Authorization/policyDefinitions', 'e56962a6-4747-49cd-b67b-bf8b01975c4c')
    parameters: {
      listOfAllowedLocations: {
        value: [
          'westeurope'
          'uksouth'
        ]
      }
    }
  }
}
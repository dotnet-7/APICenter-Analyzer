metadata description = 'Creates a role assignment for a service principal.'
param principalId string

@allowed([
  'Device'
  'ForeignGroup'
  'Group'
  'ServicePrincipal'
  'User'
])
param principalType string = 'ServicePrincipal'
param apiCenterName string

var roleDefinitionId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource apiCenter 'Microsoft.ApiCenter/services@2024-03-01' existing = {
  name: apiCenterName
}

resource role 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, resourceGroup().id, principalId, roleDefinitionId)
  scope: apiCenter
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
  }
}

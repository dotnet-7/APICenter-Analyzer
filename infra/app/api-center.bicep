param name string
param location string
param tags object
param apiName string

// Create an API center service
resource apiCenter 'Microsoft.ApiCenter/services@2024-03-01' = {
  name: name
  location: location
  tags: tags
}

resource workspace 'Microsoft.ApiCenter/services/workspaces@2024-03-01' existing = {
  parent: apiCenter
  name: 'default'
}

resource api 'Microsoft.ApiCenter/services/workspaces/apis@2024-03-01' = {
  parent: workspace
  name: apiName
  properties: {
    kind: 'rest'
    title: apiName
  }
}

resource version 'Microsoft.ApiCenter/services/workspaces/apis/versions@2024-03-01' = {
  parent: api
  name: 'v1'
  properties: {
    title: 'v1'
    lifecycleStage: 'Design'
  }
}

output name string = apiCenter.name
output id string = apiCenter.id

targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Optional parameters to override the default azd resource naming conventions. Update the main.parameters.json file to provide values. e.g.,:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
param functionName string = ''
param appServicePlanName string = ''
param storageAccountName string = ''
param apiCenterName string = ''
param logAnalyticsName string = ''
param applicationInsightsName string = ''
param applicationInsightsDashboardName string = ''

param resourceGroupName string = ''

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// Create an App Service Plan to group applications under the same payment plan and SKU
module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: 'B1'
    }
    kind: 'linux'
  }
}

// Create the storage account
module storageAccount './core/storage/storage-account.bicep' = {
  name: 'storageaccount'
  scope: rg
  params: {
    name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageStorageAccounts}${resourceToken}'
    location: location
    tags: tags
  }
}

// Create the function
module function './core/host/functions.bicep' = {
  name: 'functionapp'
  scope: rg
  params: {
    name: !empty(functionName) ? functionName : '${abbrs.webSitesFunctions}${resourceToken}'
    location: location
    tags: union(tags, { 'azd-service-name': 'function' })
    appServicePlanId: appServicePlan.outputs.id
    runtimeName: 'node'
    runtimeVersion: '18'
    storageAccountName: storageAccount.outputs.name
    managedIdentity: true
    applicationInsightsName: monitoring.outputs.applicationInsightsName
  }
}

// Create the api center
module apiCenter './app/api-center.bicep' = {
  name: 'apicenter'
  scope: rg
  params: {
    name: !empty(apiCenterName) ? apiCenterName : 'apic-${resourceToken}'
    location: location
    tags: tags
    apiName: 'api1'
  }
}

// Give api center access to the function
module apiCenterAccess './core/security/role.bicep' = {
  name: 'apicenteraccess'
  scope: rg
  params: {
    principalId: function.outputs.identityPrincipalId
    roleDefinitionId: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
    principalType: 'ServicePrincipal'
  }
}

// Monitor application with Azure Monitor
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    applicationInsightsDashboardName: !empty(applicationInsightsDashboardName) ? applicationInsightsDashboardName : '${abbrs.portalDashboards}${resourceToken}'
  }
}

output RESOURCE_GROUP_NAME string = rg.name
output AZURE_API_CENTER_ID string = apiCenter.outputs.id
output AZURE_FUNCTION_NAME string = function.outputs.name

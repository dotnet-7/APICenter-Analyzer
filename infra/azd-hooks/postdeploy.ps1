# PowerShell syntax
echo "Configuring EventGrid subscription for API Center"
$output = azd env get-values  
$resourceGroupName = ($output -split "`n" | Where-Object { $_ -match 'RESOURCE_GROUP_NAME' }).Split("=")[1]
$azureApiCenterId = ($output -split "`n" | Where-Object { $_ -match 'AZURE_API_CENTER_ID' }).Split("=")[1]  
$azureFunctionName = ($output -split "`n" | Where-Object { $_ -match 'AZURE_FUNCTION_NAME' }).Split("=")[1] 
$azureFunctionId = az functionapp function show --name $azureFunctionName --function-name apicenter-analyzer --resource-group $resourceGroupName --query "id" --output tsv

$res = az eventgrid event-subscription create --name MyEventSubscription --source-resource-id "$azureApiCenterId" --endpoint "$azureFunctionId" --endpoint-type azurefunction --included-event-types Microsoft.ApiCenter.ApiDefinitionAdded Microsoft.ApiCenter.ApiDefinitionUpdated

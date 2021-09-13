targetScope = 'subscription'

// Parameters - Common
param environment  string
param appName  string
param includeNetworkSecurity  string
var includeSecurity  = includeNetworkSecurity=='true'

// Variables - Resource Names
var subnetName_CosmosExpose  = 'subnet-cosmosexpose'
var subnetName_CosmosPvtEndpoint = 'subnet-cosmospvtendpoint'
var subnetName_ApiAppConnect = 'subnet-apiappconnect'
var subnetName_ApiAppPvtEndpoint = 'subnet-apiapppvtendpoint'
var subnetName_WfeAppConnect = 'subnet-wfeappconnect'
var subnetName_ACRegistry = 'subnet-acregistry'
var subnetName_FontDoor = 'subnet-frontdoor'
var resourceGroupName  = 'rg-${appName}-${environment}'
var vnetName  = 'vnet-${environment}-${appName}'

var cosmosDBAccountName = 'cosmos-${appName}-${environment}'
var cosmosDBName = 'db-${appName}'
var cosmosDBContainers_Employees =  'Employees'

var containerRegistryName =  'cr${appName}${environment}'

// Deployment- Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' ={
  name:resourceGroupName
  location:deployment().location
}

var frontDoorEndpointName = 'afd-${appName}-${environment}'

// Deployment - Virtual Network
module vNetDeploy 'modules/vnet.bicep' = {
  name: 'vNetDeploy'
  scope: resourceGroup
  params:{
    region:resourceGroup.location
    vnetName:vnetName
    subnetName_CosmosExpose:subnetName_CosmosExpose
    subnetName_CosmosPvtEndpoint:subnetName_CosmosPvtEndpoint
    subnetName_ApiAppConnect:subnetName_ApiAppConnect
    subnetName_ApiAppPvtEndpoint:subnetName_ApiAppPvtEndpoint
    subnetName_WfeAppConnect:subnetName_WfeAppConnect
    subnetName_ACRegistry:subnetName_ACRegistry
    subnetName_FontDoor:subnetName_FontDoor
  }
}

// Deployment - Container Registry
module acRegistryDeploy 'modules/acRegistry.bicep' = {
  name: 'acRegistryDeploy'
  scope: resourceGroup
  params:{
    containerRegistryName:containerRegistryName
    region:resourceGroup.location
  }
}

// Deployment - App Service Plan
module appPlanDeploy 'modules/appPlan.bicep' = {
  name: 'appPlanDeploy'
  scope: resourceGroup
  params:{
    environment:environment
    appName:appName
    includeNetworkSecurity:includeSecurity
    region:resourceGroup.location
    virtualNetworkName:vnetName
    subnetName:subnetName_ApiAppPvtEndpoint
    subnetId_ApiAppConnect:vNetDeploy.outputs.subnetId_ApiAppConnect
    subnetId_WfeAppConnect:vNetDeploy.outputs.subnetId_WfeAppConnect
    cosmosDBAccountName:cosmosDBAccountName
    cosmosDBName:cosmosDBName
    cosmosDBContainers_Employees:cosmosDBContainers_Employees
    containerRegistryName:containerRegistryName
  }
}

// Deployment - Cosmos DB
module cosmosDbDeploy 'modules/cosmos.bicep' = {
  name: 'cosmosDbDeploy'
  scope: resourceGroup
  params:{
    environment:environment
    appName:appName
    region:resourceGroup.location
    virtualNetworkName:vnetName
    subnetName:subnetName_CosmosPvtEndpoint
    apiAppPrincipalId:appPlanDeploy.outputs.apiAppPrincipalId
    includeNetworkSecurity:includeSecurity
    cosmosDBAccountName:cosmosDBAccountName
    cosmosDBName: cosmosDBName
    cosmosDBContainers_Employees:cosmosDBContainers_Employees
  }
}

// Deployment - Front Door
module frontDoorDeploy 'modules/frontDoor.bicep' = if(includeSecurity) {
  name: 'frontDoorDeploy'
  scope: resourceGroup
  params: {
    environment:environment
    appName:appName
    skuName: 'Premium_AzureFrontDoor'
    endpointName: frontDoorEndpointName
    originHostName: appPlanDeploy.outputs.wfeHostName
    privateEndpointResourceId: appPlanDeploy.outputs.wfeResourceId
    privateLinkResourceType: 'sites' 
    privateEndpointLocation: resourceGroup.location
  }
}

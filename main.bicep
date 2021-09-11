targetScope = 'subscription'

// Parameters - Common
param environment  string
param appName  string
param includeNetworkSecurity  bool

// Parameters - Resource Names
param subnetName_CosmosDb  string = 'subnet-cosmosdb'
param subnetName_ACRegistry  string = 'subnet-acregistry'
param subnetName_ApiApp  string = 'subnet-apiapp'
param subnetName_WfeApp  string = 'subnet-wfeapp'
param subnetName_FontDoor  string = 'subnet-frontdoor'
var resourceGroupName  = 'rg-${appName}-${environment}'
var vnetName  = 'vnet-${environment}-${deployment().location}-${appName}'
var vNetId ='/subscriptions/${subscription().id}/resourceGroups/${resourceGroupName}/providers/Microsoft.Network/virtualNetworks/${vnetName}'

// Deployment- Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' ={
  name:resourceGroupName
  location:deployment().location
}

// Deployment - Virtual Network
module vNetDeploy 'modules/vnet.bicep' = {
  name: 'vNetDeploy'
  scope: resourceGroup
  params:{
    region:resourceGroup.location
    vnetName:vnetName
    subnetName_CosmosDb:subnetName_CosmosDb
    subnetName_ACRegistry:subnetName_ACRegistry
    subnetName_ApiApp:subnetName_ApiApp
    subnetName_WfeApp:subnetName_WfeApp
    subnetName_FontDoor:subnetName_FontDoor
  }
}

// Deployment - App Service Plan
module appPlanDeploy 'modules/appPlan.bicep' = {
  name: 'appPlanDeploy'
  scope: resourceGroup
  params:{
    environment:environment
    appName:appName
    region:resourceGroup.location
    vNetName:vnetName
    subnetName_ApiApp:subnetName_ApiApp
    subnetName_WfeApp:subnetName_WfeApp
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
    virtualNetworkId:vNetId
    virtualNetworkName:vnetName
    subnetName:subnetName_CosmosDb
    apiAppPrincipalId:appPlanDeploy.outputs.apiAppPrincipalId
    includeNetworkSecurity:includeNetworkSecurity
  }
}

// // Deployment - Container Registry
// module acRegistryDeploy 'acRegistry.bicep' = {
//   name: 'acRegistryDeploy'
//   scope: resourceGroup
//   params:{
//     environment:environment
//     appName:appName
//     region:resourceGroup.location
//   }
// }

// Deployment - Front Door
// module frontDoorDeploy 'frontDoor.bicep' = {
//   name: 'frontDoorDeploy'
//   scope: resourceGroup
//   params:{
//     environment:environment
//     appName:appName
//     backendHostUrl:appPlanDeploy.outputs.hostUrl
//   }
// }

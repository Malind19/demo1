targetScope = 'subscription'

// Parameters - Common
param environment  string
param appName  string
param includeNetworkSecurity  bool

// Parameters - Resource Names
param subnetName_CosmosExpose  string = 'subnet-cosmosexpose'
param subnetName_CosmosPvtEndpoint  string = 'subnet-cosmospvtendpoint'
param subnetName_ApiAppConnect  string = 'subnet-apiappconnect'
param subnetName_ApiAppPvtEndpoint  string = 'subnet-apiapppvtendpoint'
param subnetName_WfeAppConnect  string = 'subnet-wfeappconnect'
param subnetName_ACRegistry  string = 'subnet-acregistry'
param subnetName_FontDoor  string = 'subnet-frontdoor'
var resourceGroupName  = 'rg-${appName}-${environment}'
var vnetName  = 'vnet-${environment}-${deployment().location}-${appName}'

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
    subnetName_CosmosExpose:subnetName_CosmosExpose
    subnetName_CosmosPvtEndpoint:subnetName_CosmosPvtEndpoint
    subnetName_ApiAppConnect:subnetName_ApiAppConnect
    subnetName_ApiAppPvtEndpoint:subnetName_ApiAppPvtEndpoint
    subnetName_WfeAppConnect:subnetName_WfeAppConnect
    subnetName_ACRegistry:subnetName_ACRegistry
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
    subnetId_ApiAppConnect:vNetDeploy.outputs.subnetId_ApiAppConnect
    subnetId_WfeAppConnect:vNetDeploy.outputs.subnetId_WfeAppConnect
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

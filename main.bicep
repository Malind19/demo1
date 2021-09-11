targetScope = 'subscription'

// Parameters - Common
param environment  string
param appName  string
param includeNetworkSecurity  bool

// Variables - Resource Names
var subnetName_CosmosExpose  = 'subnet-cosmosexpose'
var subnetName_CosmosPvtEndpoint = 'subnet-cosmospvtendpoint'
var subnetName_ApiAppConnect = 'subnet-apiappconnect'
var subnetName_ApiAppPvtEndpoint = 'subnet-apiapppvtendpoint'
var subnetName_WfeAppConnect = 'subnet-wfeappconnect'
var subnetName_ACRegistry = 'subnet-acregistry'
var subnetName_FontDoor = 'subnet-frontdoor'
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
    virtualNetworkName:vnetName
    subnetName:subnetName_ApiAppPvtEndpoint
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

// Deployment - Container Registry
module acRegistryDeploy 'modules/acRegistry.bicep' = {
  name: 'acRegistryDeploy'
  scope: resourceGroup
  params:{
    environment:environment
    appName:appName
    region:resourceGroup.location
  }
}

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

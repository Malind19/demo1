targetScope = 'subscription'

// Parameters - Common
param environment  string
param appName  string

// Parameters - Constants
param subnetName_CosmosDb  string = 'subnet-cosmosdb'
param subnetName_ACRegistry  string = 'subnet-acregistry'
param subnetName_ApiApp  string = 'subnet-apiapp'
param subnetName_WfeApp  string = 'subnet-wfeapp'
param subnetName_FontDoor  string = 'subnet-frontdoor'

// Deployment- Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' ={
  name:'rg-${appName}-${environment}'
  location:deployment().location
}

// Deployment - Virtual Network
module vNetDeploy 'vnet.bicep' = {
  name: 'vNetDeploy'
  scope: resourceGroup
  params:{
    environment:environment
    appName:appName
    region:resourceGroup.location
    subnetName_CosmosDb:subnetName_CosmosDb
    subnetName_ACRegistry:subnetName_ACRegistry
    subnetName_ApiApp:subnetName_ApiApp
    subnetName_WfeApp:subnetName_WfeApp
    subnetName_FontDoor:subnetName_FontDoor
  }
}

// Deployment - App Service Plan
module cosmosDbDeploy 'cosmos.bicep' = {
  name: 'cosmosDbDeploy'
  scope: resourceGroup
  params:{
    environment:environment
    appName:appName
    region:resourceGroup.location
  }
}

// Deployment - Container Registry
module acRegistryDeploy 'acRegistry.bicep' = {
  name: 'acRegistryDeploy'
  scope: resourceGroup
  params:{
    environment:environment
    appName:appName
    region:resourceGroup.location
  }
}

// Deployment - App Service Plan
module appPlanDeploy 'appPlan.bicep' = {
  name: 'appPlanDeploy'
  scope: resourceGroup
  params:{
    environment:environment
    appName:appName
    region:resourceGroup.location
    vNetName:vNetDeploy.outputs.name
    subnetName_ApiApp:subnetName_ApiApp
    subnetName_WfeApp:subnetName_WfeApp
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

targetScope = 'subscription'

// Parameters - Common
param environment  string
param appName  string

// Parameters - Constants
param subnetName_cosmosDb  string = 'subnet-cosmosdb'
param subnetName_acRegistry  string = 'subnet-acregistry'
param subnetName_appPlan  string = 'subnet-appplan'
param subnetName_fontDoor  string = 'subnet-frontdoor'

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
    subnetName_cosmosDb:subnetName_cosmosDb
    subnetName_acRegistry:subnetName_acRegistry
    subnetName_appPlan:subnetName_appPlan
    subnetName_fontDoor:subnetName_fontDoor
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
    subnetName:subnetName_appPlan
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

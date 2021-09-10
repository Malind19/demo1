targetScope = 'subscription'

// Parameters - Common
param environment  string
param appName  string

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
  }
}

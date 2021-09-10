targetScope = 'subscription'

param environment  string
param appName  string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' ={
  name:'rg-${appName}-${environment}'
  location:deployment().location
}

module appPlanDeploy 'appPlan.bicep' = {
  name:'appPlanDeploy'
  scope: resourceGroup
  params:{
    environment:environment
    appName:appName
  }
}

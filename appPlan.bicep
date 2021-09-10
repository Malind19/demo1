// Imported params
param environment  string
param appName  string
param region string = resourceGroup().location

// Local params
param sku  string = 'B1'

resource  appPlan 'Microsoft.Web/serverfarms@2021-01-15' ={
  name:'plan-${environment}-${region}-${appName}'
  location: region
  kind:'linux'
  sku:{
    name: sku
  }
  properties:{
    reserved:true
  }
} 

output planId string = appPlan.id

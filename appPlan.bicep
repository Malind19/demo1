//  Globally inherited params
param environment  string
param appName  string

// Resource specific params
param region string = resourceGroup().location
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

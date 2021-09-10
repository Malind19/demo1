// Imported params
param environment  string
param appName  string
param region string = resourceGroup().location

// Local params
param sku  string = 'B1'
param linuxFxVersion string = 'node|14-lts'

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

resource apiAppService 'Microsoft.Web/sites@2020-06-01' = {
  name: 'app-${appName}-${environment}-api'
  location: region
  properties: {
    serverFarmId: appPlan.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
    }
  }
}

resource wfeAppService 'Microsoft.Web/sites@2020-06-01' = {
  name: 'app-${appName}-${environment}-wfe'
  location: region
  properties: {
    serverFarmId: appPlan.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
    }
  }
}

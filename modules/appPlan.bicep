// Imported params
param environment  string
param appName  string
param region string = resourceGroup().location
param subnetId_ApiAppConnect  string
param subnetId_WfeAppConnect  string

// Local params
param sku  string = 'P1V2'
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

resource apiAppService 'Microsoft.Web/sites@2021-01-15' = {
  name: 'app-${appName}-${environment}-api'
  location: region
  identity:{
    type:'SystemAssigned'
  }
  properties: {
    serverFarmId: appPlan.id
    httpsOnly:true
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      vnetRouteAllEnabled:true
    }
    virtualNetworkSubnetId:subnetId_ApiAppConnect
  }
}

resource wfeAppService 'Microsoft.Web/sites@2021-01-15' = {
  name: 'app-${appName}-${environment}-wfe'
  location: region
  properties: {
    serverFarmId: appPlan.id
    httpsOnly:true
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      vnetRouteAllEnabled:true
    }
    virtualNetworkSubnetId:subnetId_WfeAppConnect
  }
}

output hostUrl string = wfeAppService.properties.defaultHostName
output apiAppPrincipalId string = apiAppService.identity.principalId

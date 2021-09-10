// Imported params
param environment  string
param appName  string
param region string = resourceGroup().location
param vNetName  string
param subnetName  string

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

resource apiAppService 'Microsoft.Web/sites@2020-06-01' = {
  name: 'app-${appName}-${environment}-api'
  location: region
  properties: {
    serverFarmId: appPlan.id
    httpsOnly:true
    siteConfig: {
      linuxFxVersion: linuxFxVersion
    }
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
    virtualNetworkSubnetId:'/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${vNetName}/subnets/${subnetName}'
  }
}

output hostUrl string = wfeAppService.properties.defaultHostName

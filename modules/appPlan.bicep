// Imported params
param environment  string
param appName  string
param includeNetworkSecurity  bool

param region string = resourceGroup().location
param subnetId_ApiAppConnect  string
param subnetId_WfeAppConnect  string
param subnetName  string
param virtualNetworkName  string

// Local params
param sku  string = 'P1V2'
param linuxFxVersion string = 'node|14-lts'
param privateEndpointName string = 'pe-apiapp-${appName}-${environment}'

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

resource apiAppPrivateNetwork 'Microsoft.Network/privateEndpoints@2021-02-01' =  if(includeNetworkSecurity) {
  name: privateEndpointName
  location: region
  properties:{
    privateLinkServiceConnections:[
      {
        name:'plsConnection'
        properties:{
          privateLinkServiceId:apiAppService.id
          groupIds:[
            'sites'
          ]
        }
      }
    ]
    subnet: {
      id: resourceId('Microsoft.Network/VirtualNetworks/subnets', virtualNetworkName, subnetName)
    }
  }
}

output wfeHostName string = wfeAppService.properties.defaultHostName
output wfeResourceId string = wfeAppService.id
output apiAppPrincipalId string = apiAppService.identity.principalId

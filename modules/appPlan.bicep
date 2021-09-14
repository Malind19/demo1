// Imported params
param environment  string
param appName  string
param includeNetworkSecurity  bool
param cosmosDBAccountName string
param cosmosDBName string
param cosmosDBContainers_Employees string

param region string = resourceGroup().location
param subnetId_ApiAppConnect  string
param subnetId_WfeAppConnect  string
param subnetName  string
param virtualNetworkName  string
param containerRegistryName  string

// Local params
param sku  string = 'P1V2'
param privateEndpointName string = 'pe-apiapp-${appName}-${environment}'
var privateDnsZoneName = 'privatelink.azurewebsites.net'

// Deployments - App Plan and App Services
resource  appPlan 'Microsoft.Web/serverfarms@2021-01-15' ={
  name:'plan-${environment}-${appName}'
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
      linuxFxVersion: 'DOCKER|${containerRegistryName}.azurecr.io/springdataapi:latest'
      vnetRouteAllEnabled:true
      appSettings:[
        {
          name: 'subscription_Id'
          value: subscription().subscriptionId
        }
        {
          name:'resourceGroup_Name'
          value:resourceGroup().name
        }
        {
          name:'cosmosDB_AccountName'
          value:cosmosDBAccountName
        }
        {
          name:'cosmosDB_Endpoint'
          value:'https://${cosmosDBAccountName}.documents.azure.com:443/'
        }
        {
          name:'cosmosDB_Name'
          value:cosmosDBName
        }
        {
          name:'cosmosDB_Containers_Employees'
          value:cosmosDBContainers_Employees
        }
      ]
    }
    virtualNetworkSubnetId:subnetId_ApiAppConnect
  }
}

resource wfeAppService 'Microsoft.Web/sites@2021-01-15' = {
  name: 'app-${appName}-${environment}-wfe'
  location: region
  identity:{
    type:'SystemAssigned'
  }
  properties: {
    serverFarmId: appPlan.id
    httpsOnly:true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistryName}.azurecr.io/springdatafe:latest'
      vnetRouteAllEnabled:true
      appSettings:[
        {
          name: 'apiApp_HostUrl'
          value: 'https://${apiAppService.properties.defaultHostName}'
        }
      ]
    }
    virtualNetworkSubnetId:subnetId_WfeAppConnect
  }
}

// Deployments - Private Endpoint and Networking
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = if(includeNetworkSecurity) {
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

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = if(includeNetworkSecurity) {
  name: privateDnsZoneName
  location: 'global'
}

resource apiAppPvtDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = if(includeNetworkSecurity) {
  parent: privateEndpoint
  dependsOn:[
    privateDnsZone
    privateEndpoint
  ]
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azurewebsites-net'
        properties: {
          privateDnsZoneId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/privateDnsZones/${privateDnsZoneName}'
        }
      }
    ]
  }
}

resource privateDnsZone_A_1 'Microsoft.Network/privateDnsZones/A@2018-09-01' = if(includeNetworkSecurity) {
  parent: privateDnsZone
  name: 'app-app22-d5-api'
  properties: {
    metadata: {
      creator: 'created by Pipeline'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: '192.168.4.100'
      }
    ]
  }
}

resource privateDnsZone_A_2 'Microsoft.Network/privateDnsZones/A@2018-09-01' = if(includeNetworkSecurity) {
  parent: privateDnsZone
  name: 'app-app22-d5-api.scm'
  properties: {
    metadata: {
      creator: 'created by Pipeline'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: '192.168.4.100'
      }
    ]
  }
}

resource privateDnsZone_SOA 'Microsoft.Network/privateDnsZones/SOA@2018-09-01' = if(includeNetworkSecurity) {
  parent: privateDnsZone
  name: '@'
  properties: {
    ttl: 3600
    soaRecord: {
      email: 'azureprivatedns-host.microsoft.com'
      expireTime: 2419200
      host: 'azureprivatedns.net'
      minimumTtl: 10
      refreshTime: 3600
      retryTime: 300
      serialNumber: 1
    }
  }
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = if(includeNetworkSecurity) {
  parent: privateDnsZone
  name: '1cf36ceee22f5'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${virtualNetworkName}'
    }
  }
}

output wfeHostName string = wfeAppService.properties.defaultHostName
output wfeResourceId string = wfeAppService.id
output apiAppPrincipalId string = apiAppService.identity.principalId

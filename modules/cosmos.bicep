// Imported params
param environment  string
param appName  string
param includeNetworkSecurity  bool

param region string = resourceGroup().location
param subnetId  string
param virtualNetworkId  string

// Local params
param employeeContainerName string = 'Employees'
param privateEndpointName string = 'pe-cosmos-${appName}-${environment}'
param tags object = {
  'deploymentGroup':'cosmosdb'
}

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-06-15' = {
  name: 'cosmos-${appName}-${environment}'
  tags:tags
  location: region
  properties:{
    databaseAccountOfferType:'Standard'
    enableAutomaticFailover:false
    enableMultipleWriteLocations:false
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: region
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
  }
}

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-06-15' = {
  name: '${cosmosDbAccount.name}/db-${appName}'
  tags: tags
  dependsOn: [
    cosmosDbAccount
  ]
  properties:{
    resource:{
      id:'db-${appName}'
    }
  }
}

resource employeesContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-06-15' = {
  name:'${cosmosDb.name}/${employeeContainerName}'
  tags:tags
  dependsOn: [
    cosmosDbAccount
    cosmosDb
  ]
  properties:{
    resource:{
      id: employeeContainerName
      partitionKey:{
        paths:[
          '/id'
        ]
      }
    }
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = if (includeNetworkSecurity) {
  name: 'privatelink.documents.azure.com'
  tags:tags
  location: 'global'
}

resource privateDnsZones_privatelink 'Microsoft.Network/privateDnsZones/A@2018-09-01' = if (includeNetworkSecurity) {
  parent: privateDnsZone
  name: 'cosmos-${appName}-${environment}'
  properties: {
    metadata: {
      creator: 'created by private endpoint via bicep'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: '192.168.4.4'
      }
    ]
  }
}

resource privateDnsZones_privatelink_region 'Microsoft.Network/privateDnsZones/A@2018-09-01' = if (includeNetworkSecurity) {
  parent: privateDnsZone
  name: 'cosmos-${appName}-${environment}-${region}'
  properties: {
    metadata: {
      creator: 'created by private endpoint via bicep'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: '192.168.4.5'
      }
    ]
  }
}

resource Microsoft_Network_privateDnsZones_SOA 'Microsoft.Network/privateDnsZones/SOA@2018-09-01' = if (includeNetworkSecurity) {
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

resource privateDnsZones_vNetLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = if (includeNetworkSecurity) {
  parent: privateDnsZone
  tags:tags
  name: 'lr67zpu3hc6ei'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' =  if (includeNetworkSecurity) {
  name: privateEndpointName
  tags:tags
  location: 'eastus'
  properties: {
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: cosmosDbAccount.id
          groupIds: [
            'Sql'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    subnet: {
      id: subnetId
    }
    customDnsConfigs: []
  }
}

resource privateEndpoints_dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = if (includeNetworkSecurity) {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-documents-azure-com'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

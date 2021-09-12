// Imported params
param environment  string
param appName  string
param includeNetworkSecurity  bool
param cosmosDBAccountName string
param cosmosDBName string
param cosmosDBContainers_Employees string

param region string = resourceGroup().location
param subnetName  string
param virtualNetworkName  string
param apiAppPrincipalId  string

// Local params
param privateEndpointName string = 'pe-cosmos-${appName}-${environment}'
param tags object = {
  'deploymentGroup':'cosmosdb'
}

var roleDefinitionId = guid('sql-role-definition-', apiAppPrincipalId, cosmosDbAccount.id)
var roleAssignmentId = guid(roleDefinitionId, apiAppPrincipalId, cosmosDbAccount.id)
var roleDefinitionName = 'Cosmos_ReadWrite'
var dataActions = [
  'Microsoft.DocumentDB/databaseAccounts/readMetadata'
  'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*'
]
var privateDnsZoneName = 'privatelink.documents.azure.com'

// Deployments - Coosmos DB Resources 
resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-04-15' = {
  name: cosmosDBAccountName
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
  name: '${cosmosDbAccount.name}/${cosmosDBName}'
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
  name:'${cosmosDb.name}/${cosmosDBContainers_Employees}'
  tags:tags
  dependsOn: [
    cosmosDbAccount
    cosmosDb
  ]
  properties:{
    resource:{
      id: cosmosDBContainers_Employees
      partitionKey:{
        paths:[
          '/id'
        ]
      }
    }
  }
}

// Deployments - Private Endpoint and Networking
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-07-01' = if(includeNetworkSecurity) {
  name: privateEndpointName
  location: region
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/VirtualNetworks/subnets', virtualNetworkName, subnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'plsConnection'
        properties: {
          privateLinkServiceId: cosmosDbAccount.id
          groupIds: [
            'Sql'
          ]
        }
      }
    ]
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = if(includeNetworkSecurity) {
  name: privateDnsZoneName
  location: 'global'
}

resource apiAppPvtDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' =  if(includeNetworkSecurity) {
  parent: privateEndpoint
  dependsOn:[
    privateDnsZone
    privateEndpoint
  ]
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-documents-azure-com'
        properties: {
          privateDnsZoneId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/privateDnsZones/${privateDnsZoneName}'
        }
      }
    ]
  }
}

resource privateDnsZone_A_1 'Microsoft.Network/privateDnsZones/A@2018-09-01' = if(includeNetworkSecurity) {
  parent: privateDnsZone
  name: 'cosmos-app22-d5'
  properties: {
    metadata: {
      creator: 'created by Pipeline'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: '192.168.4.36'
      }
    ]
  }
}

resource privateDnsZone_A_2 'Microsoft.Network/privateDnsZones/A@2018-09-01' = if(includeNetworkSecurity) {
  parent: privateDnsZone
  name: 'cosmos-app22-d5-eastus'
  properties: {
    metadata: {
      creator: 'created by Pipeline'
    }
    ttl: 10
    aRecords: [
      {
        ipv4Address: '192.168.4.37'
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
  name: '26goz5jemcopq'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${virtualNetworkName}'
    }
  }
}

// Deployments - Azure RBAC Setup for App Service - Pending MS Support Ticket
resource sqlRoleDefinition 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2021-04-15' = {
  name: '${cosmosDbAccount.name}/${roleDefinitionId}'
  properties: {
    roleName: roleDefinitionName
    type: 'CustomRole'
    assignableScopes: [
      cosmosDbAccount.id
    ]
    permissions: [
      {
        dataActions: dataActions
      }
    ]
  }
}

resource sqlRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2021-04-15' = {
  name: '${cosmosDbAccount.name}/${roleAssignmentId}'
  properties: {
    roleDefinitionId: sqlRoleDefinition.id
    principalId: apiAppPrincipalId
    scope: cosmosDbAccount.id
  }
}

output sqlRoleAssignmentId string = sqlRoleAssignment.id
output sqlRoleDefinitionId string = sqlRoleDefinition.id

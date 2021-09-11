// Imported params
param environment  string
param appName  string
param includeNetworkSecurity  bool

param region string = resourceGroup().location
param subnetName  string
param virtualNetworkName  string
param apiAppPrincipalId  string

// Local params
param employeeContainerName string = 'Employees'
param privateEndpointName string = 'pe-cosmos-${appName}-${environment}'
param tags object = {
  'deploymentGroup':'cosmosdb'
}

var roleDefinitionId = guid('sql-role-definition-', apiAppPrincipalId, cosmosDbAccount.id)
var roleAssignmentId = guid(roleDefinitionId, apiAppPrincipalId, cosmosDbAccount.id)
var roleDefinitionName = 'Cosmos_ReadWrite'
param dataActions array = [
  'Microsoft.DocumentDB/databaseAccounts/readMetadata'
  'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*'
]

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-04-15' = {
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

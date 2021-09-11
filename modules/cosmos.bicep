// Imported params
param environment  string
param appName  string
param region string = resourceGroup().location
param virtualNetworkName  string
param subnetName  string

// Local params
param employeeContainerName string = 'Employees'
param privateEndpointName string = 'pe-cosmos-${appName}-${environment}'

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2021-06-15' = {
  name: 'cosmos-${appName}-${environment}'
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

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-07-01' = {
  name: privateEndpointName
  location: region
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/VirtualNetworks/subnets', virtualNetworkName, subnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'MyConnection'
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

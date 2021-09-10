// Imported params
param environment  string
param appName  string
param region string = resourceGroup().location

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts@2021-06-15' = {
  name: 'cosmos-${appName}-${environment}'
  location: region
  properties:{
    databaseAccountOfferType:'Standard'
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

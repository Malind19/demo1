// Imported params
param environment  string
param appName  string
param region string = resourceGroup().location

resource frontDoor 'Microsoft.Network/frontDoors@2020-05-01' = {
  name: 'fd${appName}${environment}'
  location: region
}

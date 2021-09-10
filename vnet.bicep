//  Imported params
param environment  string
param appName  string
param region string = resourceGroup().location
param subnetName_CosmosDb  string
param subnetName_ACRegistry  string
param subnetName_ApiApp  string
param subnetName_WfeApp  string
param subnetName_FontDoor  string

// Local params
param addressSpaces array = [
  '192.168.4.0/24'
]

param subnets array = [
  {
    name: subnetName_CosmosDb
    properties: {
      addressPrefix: '192.168.4.0/27'
    }
  }
  {
    name: subnetName_ACRegistry
    properties: {
      addressPrefix: '192.168.4.32/27'
    }
  }
  {
    name: subnetName_ApiApp
    properties: {
      addressPrefix: '192.168.4.64/27'
      delegations:[
        {
          name:'delegation'
          properties: {
            serviceName: 'Microsoft.Web/serverfarms'
          }
        }
      ]
    }
  }
  {
    name: subnetName_WfeApp
    properties: {
      addressPrefix: '192.168.4.96/27'
      delegations:[
        {
          name:'delegation'
          properties: {
            serviceName: 'Microsoft.Web/serverfarms'
          }
        }
      ]
    }
  }
  {
    name: subnetName_FontDoor
    properties: {
      addressPrefix: '192.168.4.128/27'
    }
  }
]

// Resource Definition
resource vNet 'Microsoft.Network/virtualNetworks@2021-02-01' ={
  name:'vnet-${environment}-${region}-${appName}'
  location:region
  properties: {
    addressSpace: {
      addressPrefixes: addressSpaces
    }
    subnets: subnets
  }
}

output id string = vNet.id
output name string = vNet.name

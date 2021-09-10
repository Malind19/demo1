//  Imported params
param environment  string
param appName  string
param region string = resourceGroup().location

// Local params
param addressSpaces array = [
  '192.168.4.0/24'
]

param subnets array = [
  {
    name: 'subnet-cosmosdb'
    properties: {
      addressPrefix: '192.168.4.0/27'
    }
  }
  {
    name: 'subnet-acregistry'
    properties: {
      addressPrefix: '192.168.4.32/27'
    }
  }
  {
    name: 'subnet-appplan'
    properties: {
      addressPrefix: '192.168.4.64/27'
    }
  }
  {
    name: 'subnet-frontdoor'
    properties: {
      addressPrefix: '192.168.4.96/27'
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

output name string = vNet.name
output id string = vNet.id

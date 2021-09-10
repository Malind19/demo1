//  Imported params
param environment  string
param appName  string
param region string = resourceGroup().location
param subnetName_cosmosDb  string
param subnetName_acRegistry  string
param subnetName_appPlan  string
param subnetName_fontDoor  string

// Local params
param addressSpaces array = [
  '192.168.4.0/24'
]

param subnets array = [
  {
    name: subnetName_cosmosDb
    properties: {
      addressPrefix: '192.168.4.0/27'
    }
  }
  {
    name: subnetName_acRegistry
    properties: {
      addressPrefix: '192.168.4.32/27'
    }
  }
  {
    name: subnetName_appPlan
    properties: {
      addressPrefix: '192.168.4.64/27'
    }
  }
  {
    name: subnetName_fontDoor
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

output id string = vNet.id
output name string = vNet.name

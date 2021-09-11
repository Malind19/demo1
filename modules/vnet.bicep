//  Imported params
param region string = resourceGroup().location
param vnetName  string
param subnetName_CosmosExpose  string
param subnetName_CosmosPvtEndpoint  string
param subnetName_ApiAppConnect  string
param subnetName_ApiAppPvtEndpoint  string
param subnetName_WfeAppConnect  string
param subnetName_ACRegistry  string
param subnetName_FontDoor  string

// Local params
param addressSpaces array = [
  '192.168.4.0/24'
]

param subnets array = [
  {
    name: subnetName_CosmosExpose
    properties: {
      addressPrefix: '192.168.4.0/27'
    }
  }
  {
    name: subnetName_CosmosPvtEndpoint
    properties: {
      addressPrefix: '192.168.4.32/27'
    }
  }
  {
    name: subnetName_ApiAppConnect
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
    name: subnetName_ApiAppPvtEndpoint
    properties: {
      addressPrefix: '192.168.4.96/27'
    }
  }
  {
    name: subnetName_WfeAppConnect
    properties: {
      addressPrefix: '192.168.4.128/27'
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
    name: subnetName_ACRegistry
    properties: {
      addressPrefix: '192.168.4.160/27'
    }
  }
  {
    name: subnetName_FontDoor
    properties: {
      addressPrefix: '192.168.4.192/27'
    }
  }
]

// Resource Definition
resource vNet 'Microsoft.Network/virtualNetworks@2021-02-01' ={
  name:vnetName
  location:region
  properties: {
    addressSpace: {
      addressPrefixes: addressSpaces
    }
    subnets: subnets
  }
}

resource subnet_apiAppConnect 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  parent: vNet
  name: subnetName_ApiAppConnect
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

resource subnet_wfeAppConnect 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  parent: vNet
  name: subnetName_WfeAppConnect
  properties: {
    addressPrefix: '192.168.4.128/27'
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

output id string = vNet.id
output name string = vNet.name
output subnetId_ApiAppConnect string = subnet_apiAppConnect.id
output subnetId_WfeAppConnect string = subnet_wfeAppConnect.id

// Imported params
param containerRegistryName  string
param region string = resourceGroup().location

// Local params
param sku  string = 'Premium'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview'= {
  name: containerRegistryName
  location:region
  sku:{
    name:sku
  }
  properties:{
    adminUserEnabled:true
  }
}

// Imported params
param environment  string
param appName  string
param region string = resourceGroup().location

// Local params
param sku  string = 'Premium'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-06-01-preview'= {
  name:'cr${appName}${environment}'
  location:region
  sku:{
    name:sku
  }
  properties:{
    
  }
}

// Imported params
param environment  string
param appName  string
param region string = resourceGroup().location

// Local params
param sku  string = 'Basic'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2019-05-01'= {
  name:'cr${appName}${environment}'
  location:region
  sku:{
    name:sku
  }
  properties:{
    
  }
}

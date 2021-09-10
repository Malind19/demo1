// Imported params
param environment  string
param appName  string
param backendHostUrl  string

resource frontDoor 'Microsoft.Network/frontDoors@2020-05-01' = {
  name: 'fd${appName}${environment}'
  location: 'global'
  properties:{
    frontendEndpoints:[
      {
        name:'endpoint1'
        properties:{
          hostName: 'fd${appName}${environment}.azurefd.net'
        }
      }
    ]
    healthProbeSettings: [
      {
        id: 'healthProbeSettings1'
        name: 'healthProbeSettings1'
        properties: {
          path: '/'
          protocol: 'Https'
          intervalInSeconds: 120
        }
      }
    ]
    loadBalancingSettings:[
      {
        id:'loadBalancingSettings1'
        name:'loadBalancingSettings1'
        properties:{
          sampleSize:4
          successfulSamplesRequired:2
        }
      }
    ]
    backendPools:[
      {
        name:'backendPool1'
        properties:{
          backends:[
            {
              address:backendHostUrl
              backendHostHeader:backendHostUrl
              httpPort:80
              httpsPort:443
              weight:100
              priority:1
            }
          ]
        }
      }
    ]
  }
}

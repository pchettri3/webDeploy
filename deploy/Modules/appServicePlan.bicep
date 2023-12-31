/*
  This Bicep file defines the deployment of an Azure App Service Plan (ASE) for an application.
  It creates an isolated Linux-based ASE server farm with specific configuration settings.

  Parameters:
  - sitesLocation: The location for the ASE server farm and associated resources.
  - serverfarmsResourceGroup: The resource group where the ASE server farm will be deployed.
  - AseHostingEnvironmentId: The ID of the ASE hosting environment.
  - appResourceGroupName: The resource group name for the application.
  - ApplicationName: The name of the application.

  Outputs:
  - serverfarmsId: The ID of the created ASE server farm.
  - serverfarmsName: The name of the created ASE server farm.
*/

param sitesLocation string
param serverfarmsResourceGroup string
param AseHostingEnvironmentId string
param appResourceGroupName string
param ApplicationName string 

var apsResourceName = replace(appResourceGroupName,'ase-apps-${ApplicationName}-rg','ase-${ApplicationName}-asp')

resource aseServerFarmRestringsource 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: apsResourceName
  location: sitesLocation
  tags: {}
  sku: {
    name: 'I1v2'
    tier: 'IsolatedV2'
    size: 'I1v2'
    family: 'Iv2'
    capacity: 1
  }
  kind: 'linux'
  properties: {
    hostingEnvironmentProfile: {
      id: AseHostingEnvironmentId
    }
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: true
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
}


output serverfarmsId string = aseServerFarmRestringsource.id
output serverfarmsName string = aseServerFarmRestringsource.name

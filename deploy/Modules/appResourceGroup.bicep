targetScope = 'subscription'
param resourceGroupName string
param tags object
param tenantId string
param amerworkspaceId string
param apacworkspaceId string
param emeaworkspaceId string
param userID string
param networkResourceGroup string
param DeployStorage string
param saDeploy bool = DeployStorage == 'yes' ? true : false
param sitesName string
param InfoPrdPrivateDNSID string
param appInstanceName string //array
@secure()
param sitesLocation string
param adminUsername string
param sitesSubscriptionId string
param sitesKind string
param sitesIdentityType string
param Linuxversion string
param dbdeployType string

/*
--------------------------------------------------------------- 
Creating resource group for the app deployment
---------------------------------------------------------------
*/
resource appResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: sitesLocation
  tags: tags
}
output rgNames string = resourceGroupName

param configPropertiesRemoteDebuggingVersion string
//param configPropertiesLinuxFxVersion string
param configPropertiesScmType string

param sitesResourceGroup string

/*
--------------------------------------------------------------- 
if dbdeployType is pgsql then dbsubnetSuffix is postgresql else it is mysql.
deployment appends the dbsubnetSuffix to the appInstanceName to create the database subnet name.
---------------------------------------------------------------
*/
param pgsqldeploy bool = dbdeployType == 'pgsql' ? true : false

var privateDnsZoneId = dnsZone.outputs.postgresPrivateDnsZoneId
@secure()
param administratorLoginPassword string

@description('This variable is used to determine the suffix for the database subnet based on the value of dbdeployType.')
param dbsubnetSuffix string = dbdeployType == 'pgsql' ? 'postgresql' : 'mysql'
var dbSubnetName = replace(networkResourceGroup, 'ntw-rg', '${appInstanceName}-${dbsubnetSuffix}-sn')
var aseResourceName = replace(sitesResourceGroup, 'ase-rg', 'tier2-ase')
var vnetsuffix = contains(networkResourceGroup, '-prd') ? 'ase-vnet' : 'vnet'
var VnetName = replace(networkResourceGroup, 'ntw-rg', vnetsuffix)

var pesubnetsuffix = contains(networkResourceGroup, '-prd') ? 'ase-endpoints-sn' : 'endpoints-sn'
@description('Vnet and subent changes on prd and non prd')
var privateEndPointSubnetName = replace(networkResourceGroup, 'ntw-rg', pesubnetsuffix)

/*
-------------------------------------------------------------------------------------------
Referencing existing Ase hosting environment and ussin output to create new ASP and web app
-------------------------------------------------------------------------------------------
*/
resource AseHosting 'Microsoft.Web/hostingEnvironments@2022-09-01' existing = {
  name: aseResourceName
  scope: resourceGroup(sitesResourceGroup)
}


/*
---------------------------------------------------------------
Creating new Tier2 app specific ASP for webapp
---------------------------------------------------------------
*/
module aseASP './appServicePlan.bicep' = {
  name: 'ASP${substring(resourceGroupName, 4, length(resourceGroupName) - 8)}-Deploy'
  scope: resourceGroup(appResourceGroup.name)
  dependsOn: [
    AseHosting
  ]
  params: {
    sitesLocation: sitesLocation
    serverfarmsResourceGroup: sitesResourceGroup
    appResourceGroupName: appResourceGroup.name
    AseHostingEnvironmentId: AseHosting.id
    ApplicationName: appInstanceName

  }
}

var aspID = aseASP.outputs.serverfarmsId

/*
---------------------------------------------------------------
Deploys web app in Ase hosting environment
---------------------------------------------------------------
*/

    module AseAppDeploy './webAppModule/aseWebApp.bicep' = {//[for (ap,i) in appInstanceName : {
      scope: appResourceGroup // resourceGroup('avt-${locationlist[location]}-${environment}-${ap}-rg')
      name: 'Ase-App-${substring(resourceGroupName, 4, length(resourceGroupName) - 8)}-Deploy${appInstanceName}'
      dependsOn: [
        AseHosting
      ]
      params: {
        sitesName: sitesName 
        sitesAseHostingEnvironmentName: AseHosting.name 
        sitesAseHostingEnvironmentId: AseHosting.id
        sitesServerfarmsAspId: aspID
        sitesTags: {}
        sitesKind: sitesKind
        sitesIdentityType: sitesIdentityType
        Linuxversion: Linuxversion
        sitesLocation: sitesLocation

        configPropertiesRemoteDebuggingVersion: configPropertiesRemoteDebuggingVersion
        configPropertiesScmType: configPropertiesScmType
        amerworkspaceId: amerworkspaceId
        emeaworkspaceId: emeaworkspaceId
        apacworkspaceId: apacworkspaceId

      }
    }

@description('Location for all resources.')

//var dbSubnetName = replace(resourceGroupName, 'ase-apps-${appName}-rg', '${appInstanceName}-postgresql-sn')

/*
---------------------------------------------------------------
Referencing existing network resource group and Vnet
---------------------------------------------------------------
*/
  resource netResourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
    name: networkResourceGroup

  }

  resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
    name: VnetName
    scope: netResourceGroup

  }

  var dbsubnetID = '${virtualNetwork.id}/subnets/${dbSubnetName}'

/*
---------------------------------------------------------------
Deploys DNS zone for vnet integrated D?NS and adds one vnet link to the zone
---------------------------------------------------------------
*/
  module dnsZone './Database/dnszone.bicep' = {
    scope: netResourceGroup
    name: '${dbdeployType}-dnsZoneDeployment'
    params: {
      vnetId: virtualNetwork.id
      resourceGroupName: resourceGroupName
      appinstanceName: appInstanceName
      dbdeployType: dbdeployType

    }
  }

/*
------------------------------------------------------------------------------------
Deploys musql DB server if the dbdeployType is mysql else deploys postgresql DB server
--------------------------------------------------------------------------------------
*/
module msSqlPrivate './Database/mssql.bicep' = if (!pgsqldeploy) {
  scope: appResourceGroup
  name: 'mysqlDeployments${uniqueString(resourceGroupName)}'
  params: {
    location: sitesLocation
    resourceGroupName: resourceGroupName
    administratorLogin: adminUsername 
    administratorLoginPassword: administratorLoginPassword 
    subnetId: dbsubnetID
    privateDnsZoneArmResourceId: privateDnsZoneId
  }
}

/*
---------------------------------------------------------------
Deploys pgsql DB server if the dbdeployType is gresql DB server
---------------------------------------------------------------
*/
module postgresPrivate './Database/postgress.bicep' = if (pgsqldeploy) {
  scope: appResourceGroup
  name: 'postgresDeployment${uniqueString(resourceGroupName)}'
  params: {
    location: sitesLocation
    resourceGroupName: resourceGroupName
    administratorLogin: adminUsername 
    administratorLoginPassword: administratorLoginPassword 
    privateDnsZoneArmResourceId: privateDnsZoneId
    subnetId: dbsubnetID
  }
}

/*
--------------------------------------------------------------- 
For SA and KV name pick 6 letter from app name and add the last letter of app name 
if it is longer than 6 letter. 
For KV name - are retained for storage account - are replaced with empty string and 
converted to lower case.
---------------------------------------------------------------
*/
var appsuffix = length(appInstanceName) == 7 ? '' : substring(appInstanceName, length(appInstanceName) - 1, 1)
var appprefix = take(appInstanceName, 6)
var appNameFix = '${appprefix}${appsuffix}'
var keyVaultName = replace(resourceGroupName, 'ase-apps-${sitesName}-rg', '${appNameFix}-kv')

/*
---------------------------------------------------------------
Deploys Key vault along with private endpoint connection
---------------------------------------------------------------
*/
var siteresourceIdentity = AseAppDeploy.outputs.siteresourceIdentity
module keyVault './Database/kv.bicep' = {
  scope: appResourceGroup
  name: 'keyVaultDeployment${uniqueString(resourceGroupName)}'
  params: {
    location: sitesLocation
    tenantId: tenantId
    userID: userID
    keyVaultName: keyVaultName
    VnetName: virtualNetwork.name
    // VnetId: virtualNetwork.id
    privateEndPointSubnetName: privateEndPointSubnetName
    resourceGroupName: netResourceGroup.name
    siteresourceIdentity: siteresourceIdentity
    InfoPrdPrivateDNSID: InfoPrdPrivateDNSID

  }
}

/*
--------------------------------------------------------------- 
For SA and KV name pick 6 letter from app name and add the last letter of app name 
if it is longer than 6 letter. 
For storage account - are replaced with empty string and 
converted to lower case.
---------------------------------------------------------------
*/

var saAccountN = replace(replace(resourceGroupName, 'ase-apps-${sitesName}-rg', '${appNameFix}-sa'), '-', '')
var saAccountName = toLower(saAccountN)

/*
---------------------------------------------------------------
Deploys Storage acciunt along with private endpoint connection, if the SA deploy is set to yes
---------------------------------------------------------------
*/
module appStorageAccount 'storageAccount.bicep' = if (saDeploy) {
  name: 'StorageAccount${uniqueString(resourceGroupName)}'
  scope: appResourceGroup
  params: {
    location: sitesLocation
    subscriptionId: sitesSubscriptionId
    saAccountName: saAccountName
    tenantId: tenantId
    VnetId: virtualNetwork.id
    privateEndPointSubnetName: privateEndPointSubnetName
    InfoPrdPrivateDNSID: InfoPrdPrivateDNSID

  }

}

output moduleResourceOutput object = {
  dnszone: dnsZone.outputs.privateDnsZoneName
  privateDnsZoneName: dnsZone.outputs.privateDnsZoneId
  KeyVaultPrivateEpName: keyVault.outputs.KeyVaultPrivateEpName
  peSubnetId: 'The subnet ID for the Key vault PE ${keyVault.outputs.peSubnetId}'

}

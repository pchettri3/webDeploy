/*
  This Bicep file creates an Azure resource group for each application instance specified in the appInstanceName array parameter.
  It requires several parameters such as subscription, environmentlist, environment, location, locationlist, azServiceName, azService, app, appInstanceName, sitesLocation, sitesPropertiesSiteConfigLinuxFxVersion, configPropertiesRemoteDebuggingVersion, sitesSubscriptionId, sitesKind, configPropertiesLinuxFxVersion, configPropertiesScmType, and sitesIdentityType.
  The module ApplicationResourceGroups is used to create the resource groups using the parameters specified in the for loop.
*/
targetScope = 'subscription'

param subscription string
param amerworkspaceId string
param apacworkspaceId string
param emeaworkspaceId string
var subprefix = take(subscription, 4)
param environmentlist object
param environment string
param appInstanceName string
param Location string
param locationlist object
param adminUsername string
param InfoPrdPrivateDNSID string
param tenantId string
param userID string

@secure()
param administratorLoginPassword string

param Linuxversion string
param dbdeployType string
param configPropertiesRemoteDebuggingVersion string
param sitesSubscriptionId string
param sitesKind string
param networkResourceGroup string
param DeployStorage string
param configPropertiesScmType string
param sitesIdentityType string
param sitesResourceGroup string
param orgPrefix string
var resouceGroupAppSuffix = replace(appInstanceName, '-${environment}', '')
module ApplicationResourceGroups './Modules/appResourceGroup.bicep' = {//[for (ap,i) in appInstanceName : {

  name: '${appInstanceName}${subprefix}'

  params: {
    resourceGroupName: '${orgPrefix}-${locationlist[Location]}-${environmentlist[environment]}-ase-apps-${appInstanceName}-rg'

    tags: {}

    configPropertiesRemoteDebuggingVersion: configPropertiesRemoteDebuggingVersion
    sitesSubscriptionId: sitesSubscriptionId
    sitesKind: sitesKind

    configPropertiesScmType: configPropertiesScmType
    sitesIdentityType: sitesIdentityType
    networkResourceGroup: networkResourceGroup
    Linuxversion: Linuxversion
    dbdeployType: dbdeployType
    sitesResourceGroup: sitesResourceGroup
    appInstanceName: appInstanceName
    tenantId: tenantId
    userID: userID
    sitesLocation: Location
    DeployStorage: DeployStorage
    sitesName: appInstanceName
    adminUsername: adminUsername
    administratorLoginPassword: administratorLoginPassword
    InfoPrdPrivateDNSID: InfoPrdPrivateDNSID
    amerworkspaceId: amerworkspaceId
    emeaworkspaceId: emeaworkspaceId
    apacworkspaceId: apacworkspaceId
  }
}

//output appResourceGroup string = ApplicationResourceGroups.outputs.aseId
//output aspResourceName string = ApplicationResourceGroups.outputs.aspid
output dbServerOutput object = ApplicationResourceGroups.outputs.moduleResourceOutput

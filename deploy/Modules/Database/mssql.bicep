param location string
param resourceGroupName string
param administratorLogin string
@secure()
param administratorLoginPassword string
param subnetId string
param privateDnsZoneArmResourceId string

// Assigns 30 days backup retention for production environment and 15 days for non-production environment*********
var backupRetentionDays  = contains(resourceGroupName, 'prd') ? 30 : 15
var serverName = replace(resourceGroupName, 'rg', 'mysql')
resource mysql_serverName_resource 'Microsoft.DBforMySQL/flexibleServers@2023-06-30' = {
  name: serverName
  location: location
  sku: {
    name: 'Standard_D2ads_v5'
    tier: 'GeneralPurpose'
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storage: {
      storageSizeGB: 64
      iops: 492
      autoGrow: 'Disabled'
      autoIoScaling: 'Enabled'
      logOnDisk: 'Disabled'
    }
    version: '8.0.21'
    availabilityZone: '3'

    replicationRole: 'None'
    network: {
      publicNetworkAccess: 'Disabled'
      delegatedSubnetResourceId: subnetId
      privateDnsZoneResourceId: privateDnsZoneArmResourceId
    }
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
  }
}
output backupRetentionDays int = mysql_serverName_resource.properties.backup.backupRetentionDays
output msSqlserverName string = mysql_serverName_resource.name
output msSql_id string = mysql_serverName_resource.id

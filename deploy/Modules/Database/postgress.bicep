// Parameters
param location string
param resourceGroupName string
param administratorLogin string
@secure()
param administratorLoginPassword string
param subnetId string
param privateDnsZoneArmResourceId string

// Variables
var serverName = replace(resourceGroupName,'rg','pgsql')
var backupRetentionDays  = contains(resourceGroupName, 'prd') ? 30 : 15

// Postgres
resource serverName_resource 'Microsoft.DBforPostgreSQL/flexibleServers@2023-03-01-preview' = {
  name: serverName
  location: location
  sku: {
    name: 'Standard_D2ds_v5'
    tier: 'GeneralPurpose'
  }
  properties: {
    dataEncryption: {
      type: 'SystemManaged'
    }
    storage: {
     // tier: 'P10'
      storageSizeGB: 128
    //  autoGrow: 'Disabled'
    }
    authConfig: {
      activeDirectoryAuth: 'Disabled'
      passwordAuth: 'Enabled'
    }
    version: '15'
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    network: {
      delegatedSubnetResourceId: subnetId
     privateDnsZoneArmResourceId: privateDnsZoneArmResourceId
    }
    highAvailability: {
      mode: 'Disabled'
    }
    maintenanceWindow: {
      customWindow: 'Disabled'
      dayOfWeek: 0
      startHour: 0
      startMinute: 0
    }
    replicationRole: 'Primary'
    availabilityZone: '3'
 
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: 'Disabled'
    }

}

}

output serverName string = serverName_resource.name
output pgsql_id string = serverName_resource.id
output pgsql_Subnet string = serverName_resource.properties.network.delegatedSubnetResourceId

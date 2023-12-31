Connect-AzAccount -Tenant "tenantid" -Subscription "testSubID"
$scriptDirectory = "C:\lab\appAseT2"
set-location -path $scriptDirectory

$params = @{
  name                  = "apptestpc" + (get-date).ToString("yyyyMMddhhmmss")
  Location              = 'eastus' #  'eastus' 'westus3' southeastasia westeurope northeurope
  locationFromTemplate  = 'eastus'
  environment           = 'DR'  # use DEV, Prod, UAT, Test, Services
  subscription          = 'testSubID'
  TemplateFile          = "${scriptDirectory}\main.bicep"
  TemplateParameterFile = "${scriptDirectory}\varparam.jsonc"
  dbdeployType          = "pgsql" #  mysql, pgsql, sqlserver
  appInstanceName       = "kpgapp-t2"#IF the name is not unique, the deployment will fail as it network resources are not unique
  sitesResourceGroup    = "pct-ase-rg"
  networkResourceGroup  = "pct-network-rg"
  orgPrefix = "pct"
  Linuxversion          = "TOMCAT|8.5-java11" #  'TOMCAT|8.5-java11'   'TOMCAT|10.0-java17'  'JBOSSEAP|7-java17'  TOMCAT|8.5-java11 "PHP|8.2" 

  
} 

New-AzSubscriptionDeployment @params -Verbose -whatif

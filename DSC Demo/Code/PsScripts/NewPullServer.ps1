function GetProjectLocation
{
	#PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& 'C:\Vikas\Deployment Orchestration\Deployment Orchestration\Readtest.ps1'"
	split-path $MyInvocation.PSCommandPath -Parent -ErrorAction SilentlyContinue
	#$PSScriptRoot
	#Get-Location 
	
}
$global:ProjectLocation = GetProjectLocation	
#$global:ProjectLocation =  $global:ProjectLocation -replace "\\DSCConfiguration\\bin\\Debug", "";
#$global:ProjectLocation =  $global:ProjectLocation+'\DSCConfiguration'

#-> import Logger module
$varLoggerModuleLocation = $global:ProjectLocation +"\Moduler\Logger.psm1"
Import-Module -Name $varLoggerModuleLocation -Force -ErrorAction Stop;
    Log-Start
    Log-Write  " " #-> insert an empty line
	Log-Write  "PullServer"
	Log-Write  " " #-> insert an empty line
	Log-Write  "Process :: $(Get-Date) :: Start"
configuration NewPullServer
{
param
(
[string[]]$ComputerName = 'localhost'
)
#-> Get the Modules
Log-Write  "Process :: $(Get-Date) :: Import Module xPSDesiredStateConfiguration"

Import-DSCResource -ModuleName PSDesiredStateConfiguration
Import-DSCResource -ModuleName xPSDesiredStateConfiguration

    Node $ComputerName
{
Log-Write  "PullServer :: $(Get-Date) :: setting the node $ComputerName as pullserver"
Log-Write  "DSCServiceFeature :: $(Get-Date) :: start"
Log-Write  "DSCServiceFeature :: $(Get-Date) :: check the Dsc Service Feature Exists"
WindowsFeature DSCServiceFeature
{
Ensure = "Present"
Name   = "DSC-Service"
LogPath = "C:\DSC\NewPullserver.txt"
}
Log-Write  "DSCServiceFeature :: $(Get-Date) :: End"
Log-Write  "xDscWebService:: $(Get-Date) :: start"

xDscWebService PSDSCPullServer
{
Ensure                  = "Present"
EndpointName            = "PSDSCPullServer"
Port                    = 8090
PhysicalPath            = "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer"
CertificateThumbPrint   = "AllowUnencryptedTraffic"
ModulePath              = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules"
ConfigurationPath       = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"
State                   = "Started"
DependsOn               = "[WindowsFeature]DSCServiceFeature"
}

Log-Write  "xDscWebService:: $(Get-Date) :: End"
Log-Write  "xDscWebService:: $(Get-Date) :: PSDSCComplianceServer start"

xDscWebService PSDSCComplianceServer
{
Ensure                  = "Present"
EndpointName            = "PSDSCComplianceServer"
Port                    = 9080
PhysicalPath            = "$env:SystemDrive\inetpub\wwwroot\PSDSCComplianceServer"
CertificateThumbPrint   = "AllowUnencryptedTraffic"
State                   = "Started"
IsComplianceServer      = $true
DependsOn               = ("[WindowsFeature]DSCServiceFeature","[xDSCWebService]PSDSCPullServer")
}
Log-Write  "xDscWebService:: $(Get-Date) :: PSDSCComplianceServer End"
}
}

#This line actually calls the function above to create the MOF file.

NewPullServer –ComputerName pullserver
Log-Write  "xDscWebService:: $(Get-Date) :: Dsc Configuration Start"
Start-DscConfiguration .\NewPullServer –Wait -Force
Log-Write  "xDscWebService:: $(Get-Date) :: Dsc Configuration Ens"

Log-Finish

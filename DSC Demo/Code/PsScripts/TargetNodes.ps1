
param(
$targetMachines
)
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
    
    Log-Write  " " #-> insert an empty line
	Log-Write  "Target Nodes $targetMachines"
	Log-Write  " " #-> insert an empty line
	Log-Write  "Process :: $(Get-Date) :: Start"
Configuration TargetNodes
{
param ($MachineName,
[Parameter(Mandatory)]$Language,
[Parameter(Mandatory)]$LocalPath,
$AppPoolName)

Import-DscResource -Module xChrome
Import-DscResource -Module xTimeZone
Import-DscResource -Module xFirefox

Import-DscResource -Module cWebAdministration

Log-Write  "Target Nodes Configuration:: $(Get-Date) :: Start"
Node $MachineName
{
Log-Write  "Target Nodes WindowsFeature IIS:: $(Get-Date) :: $MachineName Start"
#Install the IIS Role
WindowsFeature IIS
{
Ensure = “Present”
Name = “Web-Server”
}
Log-Write  "Target Nodes WindowsFeature IIs:: $(Get-Date) :: $MachineName End"
Log-Write  "Target Nodes WindowsFeature Asp:: $(Get-Date) :: $MachineName Start"
#Install ASP.NET 4.5
WindowsFeature ASP
{
Ensure = “Present”
Name = “Web-Asp-Net45”
}
Log-Write  "Target Nodes WindowsFeature:: $(Get-Date) :: $MachineName End"
#For ppe node install Chrome and set time zone
if($Machine -eq 'prod'){
Log-Write  "Target Nodes Install Chorme:: $(Get-Date) :: $MachineName start"
    MSFT_xChrome chrome {
    Language = $Language
    LocalPath = $LocalPath
    }
    Log-Write  "Target Nodes Install Chorme:: $(Get-Date) :: $MachineName End"
    Log-Write  "Target Nodes set TimeZone:: $(Get-Date) :: $MachineName start"
    xTimeZone TimeZoneExample
    {
    TimeZone = "Pacific Standard Time"
    }
    Log-Write  "Target Nodes set TimeZone:: $(Get-Date) :: $MachineName End"
}
#for staging and PPE node install firefox
else{
 Log-Write  "Target Nodes Install firefox:: $(Get-Date) :: $MachineName start"
    MSFT_xFirefox firefox
    {
	VersionNumber = "4.42.0.0"
	Language = "en-US"
	OS = "win"
	LocalPath = $LocalPath
    }
     Log-Write  "Target Nodes Install firefox:: $(Get-Date) :: $MachineName End"
}

#WebSite Deploy

 Log-Write  "Target Nodes WebSite Deploy:: $(Get-Date) :: $MachineName start"
  #Copy-Item -Path \\13.67.117.174\C$\DSCWebsite\ -Destination \\$MachineName\c$\inetpub\wwwroot -Filter *.* -Force -Recurse
  Copy-Item -Path \\pullserver\mntdevops\ -Destination \\$MachineName\c$\inetpub\wwwroot -Filter *.* -Force -Recurse
  #\\DEVOPSSOLUTIONS\DSCWebsite

  Log-Write  "Target Nodes WebSite Deploy:: $(Get-Date) :: $MachineName Copy website content"
# Copy the website content

#SourcePath      = "\\$MachineName\c$\inetpub\wwwroot\mntdevops"
File WebContent
{
    Ensure          = "Present"
    SourcePath      = "C:\mntdevops"
    DestinationPath = "\\$MachineName\c$\inetpub\wwwroot\mntdevops"
    Recurse         = $true
    Type            = "Directory"
    DependsOn       = "[WindowsFeature]ASP"
}       
Log-Write  "Target Nodes WebSite Deploy:: $(Get-Date) :: $MachineName create new Apppool"
# Create the new AppPool
cAppPool NewAppPool
{
    Name = $AppPoolName
    Ensure = "Present"
    autoStart = "true"  
    managedRuntimeVersion = "v4.0"
    managedPipelineMode = "Integrated"
    startMode = "AlwaysRunning"
    identityType = "LocalSystem"
    #restartSchedule = @("18:30:00","05:00:00")
}
Log-Write  "Target Nodes WebSite Deploy:: $(Get-Date) :: $MachineName create new website"
# Create the new Website
cWebsite NewWebsite
{
    Ensure          = "Present"
    Name            = 'mntdevops'
    State           = "Started"
    PhysicalPath    = "\\$MachineName\c$\inetpub\wwwroot\mntdevops"
    BindingInfo  = @(
        PSHOrg_cWebBindingInformation 
        {
            Protocol = 'HTTP'
            Port     = 8080
            HostName = '*'
        }
    )
            
    ApplicationPool = $AppPoolName
    DependsOn = @("[WindowsFeature]IIS","[File]WebContent","[cAppPool]NewAppPool")           
}


}
Log-Write  "Target Nodes Configuration:: $(Get-Date) :: End"
}

Configuration SetPullMode
{
param($MachineName,[string]$guid)

Node  $MachineName
{
Log-Write  "Set Pull Configuration:: $(Get-Date) :: $MachineName start"
LocalConfigurationManager
{
ConfigurationModeFrequencyMins = 1
RefreshFrequencyMins =30
ConfigurationMode = ‘ApplyAndAutocorrect’
ConfigurationID = $guid
RefreshMode = ‘Pull’
DownloadManagerName = ‘WebDownloadManager’
DownloadManagerCustomData = @{
ServerUrl = ‘http://52.187.172.19:8090/PSDSCPullServer.svc’;
         AllowUnsecureConnection = ‘true’ }
}
Log-Write  "Set Pull Configuration:: $(Get-Date) :: $MachineName End"
}
}

$targetMachines = @("prod")
Log-Write  "Target Nodes:: $(Get-Date) :: Start"
foreach ($Machine in $targetMachines) {
if($Machine -eq 'ppe'){
#


TargetNodes –MachineName $Machine -Language "en-us" -LocalPath "C:\Windows\Temp\ChromeSetup.exe" -AppPoolName 'TrendAppPool'
}
else{
TargetNodes –MachineName $Machine -Language "en-us" -LocalPath "C:\Windows\Temp\Firefox Setup Stub 54.0.1.exe" -AppPoolName 'TrendAppPool'
}

$Guid= [guid]::NewGuid()

$source = "C:\Users\dscuser\TargetNodes\$Machine.mof"

$target= "C:\Program Files\WindowsPowerShell\DscService\Configuration\$Guid.mof"

copy $source $target
New-DSCChecksum $target

SetPullMode -MachineName $Machine –guid $Guid 

Set-DSCLocalConfigurationManager –Computer $Machine -Path "C:\Users\dscuser\SetPullMode" –Verbose


}
Log-Write  "Target Nodes:: $(Get-Date) :: End"
Log-Finish

function GetProjectLocation{
split-path $MyInvocation.PSCommandPath -Parent
}
$LogProjectLocation =GetProjectLocation
$LogProjectLocation = $LogProjectLocation -replace "Module" , ""
$LogPath= $LogProjectLocation +"Log\AvailabilityLog.txt" 
$LogStatusPath= $LogProjectLocation +"Log\AvailabilityStatusLog.txt" 
$DestinationPath="C:\testresults"

Write-Output $LogPath
$ScriptVersion="1.3"
$sFullPath=$LogPath
$sFullPathStatus=$LogStatusPath

Function Log-Start
{  
  
  Process
  {
	# $sFullPath = $LogPath + "\" + $LogName
    Write-Output $sFullPath
    
	# Check if file exists and delete if it does
    If((Test-Path -Path $sFullPath))
	{
     # Remove-Item -Path $sFullPath -Force
     # Write-Host "file exists"
     Clear-Content -Path $sFullPath -Force
    }
    
    # Create file and start logging
    # New-Item -Path $LogPath -Value $LogName -ItemType File
    
    # Add-Content -Path $sFullPath -Value "***************************************************************************************************"
    # Add-Content -Path $sFullPath -Value "Started processing at [$([DateTime]::Now)]."
    # Add-Content -Path $sFullPath -Value "***************************************************************************************************"
    # Add-Content -Path $sFullPath -Value ""
    # Add-Content -Path $sFullPath -Value "Running script version [$ScriptVersion]."
    # Add-Content -Path $sFullPath -Value ""
    # Add-Content -Path $sFullPath -Value "***************************************************************************************************"
    Add-Content -Path $sFullPath -Value ""
  
    #Write to screen for debug mode
    #Write-Debug "***************************************************************************************************"
    #Write-Debug "Started processing at [$([DateTime]::Now)]."
    #Write-Debug "***************************************************************************************************"
    #Write-Debug ""
    #Write-Debug "Running script version [$ScriptVersion]."
    #Write-Debug ""
    #Write-Debug "***************************************************************************************************"
    #Write-Debug ""
  }
}
 
Function Log-Write([string]$LineValue)
{  
  Process
  {
    Add-Content -Path $sFullPath -Value $LineValue
  
    # Write to screen for debug mode
	# Write-Debug $LineValue

	# Write-Host $LineValue
  }
}

Function Log-StatusWrite([string]$LineValue)
{  
  Process
  {
    Add-Content -Path $sFullPathStatus -Value $LineValue
  
    #Write to screen for debug mode
    #Write-Debug $LineValue

	#Write-Host $LineValue
  }
}

Function Log-StatusStart
{   
  
  Process
  {
	# $sFullPath = $LogPath + "\" + $LogName
    Write-Output $sFullPathStatus
    
	#Check if file exists and delete if it does
    If((Test-Path -Path $sFullPathStatus))
	{
		# Remove-Item -Path $sFullPath -Force
		#Write-Host "file exists"
		Clear-Content -Path $sFullPathStatus -Force
    }    
  }
}

Function Log-Error([string]$ErrorDesc)
{
  
  Process
  {
    Add-Content -Path $sFullPath  -Value $ErrorDesc
  
    #Write to screen for debug mode
    # Write-Debug "Error: An error has occurred [$ErrorDesc]."
    
    #If $ExitGracefully = True then run Log-Finish and exit script
   
    Log-Finish 
    Break    
  }
}
 
Function Log-Finish()
{  
  Process
  {
    Add-Content -Path $sFullPath  -Value ""
 
    #Exit calling script if NoExit has not been specified or is set to False
   Copy-Item -Path $LogPath  -Destination $DestinationPath
      Exit
        
  }
}
 

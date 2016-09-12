##-----------------------------------------------------------------------
## <copyright file="ApplyVersionToAssemblies.ps1">(c) http://TfsBuildExtensions.codeplex.com/. This source is subject to the Microsoft Permissive License. See http://www.microsoft.com/resources/sharedsource/licensingbasics/sharedsourcelicenses.mspx. All other rights reserved.</copyright>
##-----------------------------------------------------------------------
# Look for a 0.0.0.0 pattern in the build number. 
# If found use it to version the assemblies.
#
# For example, if the 'Build number format' build process parameter 
# $(BuildDefinitionName)_$(Year:yyyy).$(Month).$(DayOfMonth)$(Rev:.r)
# then your build numbers come out like this:
# "Build HelloWorld_2013.07.19.1"
# This script would then apply version 2013.07.19.1 to your assemblies.
	
# Enable -Verbose option
[CmdletBinding()]
	
# Disable parameter
# Convenience option so you can debug this script or disable it in 
# your build definition without having to remove it from
# the 'Post-build script path' build process parameter.
param([switch]$Disable)
if ($PSBoundParameters.ContainsKey('Disable'))
{
	Write-Verbose "Script disabled; no actions will be taken on the files."
}
	
	
	
# Regular expression pattern to find the version in the build number 
# and then apply it to the assemblies
$VersionRegex = "\d+\.\d+\.\d+\.\d+"
$InformationalVersionRegex = "DEVELOPMENT"
$ManualBuildNumberRegEx = "\d+\.\d+"
	
# If this script is not running on a build server, remind user to 
# set environment variables so that this script can be debugged
if(-not $Env:BUILD -and -not ($Env:BUILD_SOURCESDIRECTORY -and $Env:BUILD_BUILDNUMBER))
{
	Write-Error "You must set the following environment variables"
	Write-Error "to test this script interactively."
	Write-Host '$Env:BUILD_SOURCESDIRECTORY - For example, enter something like:'
	Write-Host '$Env:BUILD_SOURCESDIRECTORY = "C:\code\FabrikamTFVC\HelloWorld"'
	Write-Host '$Env:BUILD_BUILDNUMBER - For example, enter something like:'
	Write-Host '$Env:BUILD_BUILDNUMBER = "Build HelloWorld_0000.00.00.0"'
	Write-Host '$Env:BuildNumber = "8.1"'
	exit 1
}
	
# Make sure path to source code directory is available
if (-not $Env:BUILD_SOURCESDIRECTORY)
{
	Write-Error ("BUILD_SOURCESDIRECTORY environment variable is missing.")
	exit 1
}
elseif (-not (Test-Path $Env:BUILD_SOURCESDIRECTORY))
{
	Write-Error "BUILD_SOURCESDIRECTORY does not exist: $Env:BUILD_SOURCESDIRECTORY"
	exit 1
}
Write-Verbose "BUILD_SOURCESDIRECTORY: $Env:BUILD_SOURCESDIRECTORY"
	
# Make sure there is a build number
if (-not $Env:BUILD_BUILDNUMBER)
{
	Write-Error ("TFS BUILD_BUILDNUMBER environment variable is missing.")
	exit 1
}

# Make sure there is a build number
if (-not $Env:BuildNumber)
{
	Write-Error ("Manually entered BuildNumber environment variable is missing.")
	exit 1
}

Write-Verbose "BUILD_BUILDNUMBER: $Env:BUILD_BUILDNUMBER"
Write-Verbose "BuildNumber: $Env:BuildNumber"

	
# Get and validate the version data
$VersionData = [regex]::matches($Env:BUILD_BUILDNUMBER,$VersionRegex)
switch($VersionData.Count)
{
   0		
      { 
         Write-Error "Could not find version number data in TF_BUILD_BUILDNUMBER."
         exit 1
      }
   1 {}
   default 
      { 
         Write-Warning "Found more than instance of version data in TF_BUILD_BUILDNUMBER." 
         Write-Warning "Will assume first instance is version."
      }
}

$ManualVersionData = [regex]::matches($Env:BuildNumber, $ManualBuildNumberRegEx)
switch($ManualVersionData.Count)
{
	0
	{
		Write-Error "Could not find the manually entered version number in BuildNumber."
		exit 1
	}
	1 {}
	default
	{
		Write-Warning "Found more than one instance of version data in BuildNumber."
		Write-Warning "Will assume first instance is manually entered version."
	}
}

$NewVersion = $VersionData[0]
$NewManuallyEnteredVersion = "$ManualVersionData.0.0"
	
if(-not $Disable)
{
	$found = gci -path $Env:BUILD_SOURCESDIRECTORY -filter "GlobalAssemblyInfo.cs" -recurse
	
	$hasFile = Test-Path $found.FullName
	
	if($hasFile) {
		$file = gi $found.FullName
		$filecontent = Get-Content($file)
		attrib $file -r
		$filecontent -replace $VersionRegex, $NewManuallyEnteredVersion `
					 -replace $InformationalVersionRegex, $NewVersion | Out-File $file
		Write-Verbose "$file - version applied"
	}
	else{
		Write-Verbose "GlobalAssemblyInfo.cs not found"
	}
}
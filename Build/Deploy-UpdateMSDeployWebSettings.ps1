# This script is meant for the deployment server and not the build server.  
# A deployment server is expected to have a certain structure (e.g. e:\tools, e:\deploy, etc.)  
[CmdletBinding(PositionalBinding=$false)]
param(
    [string]
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $SiteName, 

    [string]
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $BuildType,

    [string]
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $connectionString,

    $deploymentDriveLetter = "E"
)

# Reference functions in other files
. "${deploymentDriveLetter}:\Deploy\$BuildType\drop\Build\poke-xml.ps1"

$paramFilePath = "${deploymentDriveLetter}:\Deploy\$BuildType\drop\Vantage.Web.SetParameters.xml"

poke-xml $paramFilePath "/parameters/setParameter[@name='IIS Web Application Name']/@value" $SiteName
poke-xml $paramFilePath "/parameters/setParameter[@name='DefaultConnection-Web.config Connection String']/@value" $connectionString
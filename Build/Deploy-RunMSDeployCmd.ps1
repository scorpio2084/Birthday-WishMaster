# This script is meant for the deployment server and not the build server.  
# A deployment server is expected to have a certain structure (e.g. e:\tools, e:\deploy, etc.)  
param(
    [string]
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $BuildType,

    $deploymentDriveLetter = "E"
)

& "${deploymentDriveLetter}:\Deploy\$BuildType\drop\Vantage.Web.deploy.cmd" /Y -EnableRule:EncryptWebConfig 
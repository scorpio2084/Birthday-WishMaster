[CmdletBinding(PositionalBinding=$false)]
param 
(
    [string]
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $connectionString,
    
    [string]
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $configFileAndPath,

    $buildDriveLetter = "E"
)

# Reference functions in other files
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
.$scriptPath/poke-xml.ps1

poke-xml $configFileAndPath "/configuration/connectionStrings/add[@name='DefaultConnection']/@connectionString" $connectionString
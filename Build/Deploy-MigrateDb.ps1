# This script is meant for the deployment server and not the build server.  
# A deployment server is expected to have a certain structure (e.g. e:\tools, e:\deploy, etc.)  
[CmdletBinding(PositionalBinding=$false)]
param 
(
    [string]
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $BuildType,

    [string]
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $connectionString,

    $fluentMigratorProvider = "SqlServer2012",

    $deploymentDriveLetter = "E"
)

# Reference functions in other files
. "${deploymentDriveLetter}:\Deploy\$BuildType\drop\Build\poke-xml.ps1"

$migrateExePath = "${deploymentDriveLetter}:\tools\fluentMigrator\migrate.exe"
$dataMigrateAssembly = "${deploymentDriveLetter}:\deploy\$BuildType\drop\DbMigration\Vantage.Deployment.dll"

# Update the connection string in the config file 
poke-xml "$dataMigrateAssembly.config" "/configuration/connectionStrings/add[@name='DefaultConnection']/@connectionString" $connectionString

# Migrate the DB
& $migrateExePath --assembly=$dataMigrateAssembly --tag "Developer" --provider=$fluentMigratorProvider --conn=DefaultConnection --timeout=600
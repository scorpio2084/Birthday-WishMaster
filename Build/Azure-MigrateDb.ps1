[CmdletBinding(PositionalBinding=$false)]
param 
(
    [string]
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $BuildTypeWithVersion,
    
    [string]
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $ReliabuilderVersion,

    [string]
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $connectionString,

    $fluentMigratorProvider = "SqlServer2012",

    $buildDriveLetter = "E",

    $MasterBranch = "N",

    $BuildPrefix = "Reliabuilder-r"
)

IF ($MasterBranch -eq "Y") {
    $BuildPrefix = "Reliabuilder"
}

# Reference functions in other files
. "${buildDriveLetter}:\BuildDrop\$BuildTypeWithVersion\${BuildPrefix}_v$ReliabuilderVersion\drop\Build\poke-xml.ps1"

$migrateExePath = "${buildDriveLetter}:\tools\fluentMigrator\migrate.exe"
$dataMigrateAssembly = "${buildDriveLetter}:\BuildDrop\$BuildTypeWithVersion\${BuildPrefix}_v$ReliabuilderVersion\drop\DbMigration\Vantage.Deployment.dll"

# Update the connection string in the config file 
poke-xml "$dataMigrateAssembly.config" "/configuration/connectionStrings/add[@name='DefaultConnection']/@connectionString" $connectionString

# Migrate the DB
& $migrateExePath --assembly=$dataMigrateAssembly --tag "Developer" --provider=$fluentMigratorProvider --conn=DefaultConnection --timeout=600
[CmdletBinding(PositionalBinding=$false)]
param(
    [string]
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $AgentBuildDirectory,

    $BuildConfiguration = "Debug"
)

$sourcePath = "$AgentBuildDirectory\s"
$stagingPath = "$AgentBuildDirectory\b"

$targetPath = "$stagingPath\Reliabuilder"
$scriptPath = "$targetPath\Build"
$testPath = "$targetPath\Tests"
$publishWeb = "$targetPath\_PublishWeb"
$fluentMigratorPath = "$targetPath\DbMigration"

if (-not(Test-Path($targetPath))) {
        mkdir $targetPath
    }

if (-not(Test-Path($scriptPath))) {
        mkdir $scriptPath
    }

if (-not(Test-Path($testPath))) {
        mkdir $testPath
    }
   
if (-not(Test-Path($publishWeb))) {
        mkdir $publishWeb
    }
    
if (-not(Test-Path($fluentMigratorPath))) {
        mkdir $fluentMigratorPath
    }    

Rename-Item "$sourcePath\Source\Vantage.Web\obj\$BuildConfiguration\Package\PackageTmp" "$sourcePath\Source\Vantage.Web\obj\$BuildConfiguration\Package\_PublishWeb" -Force

Copy-Item "$sourcePath\Source\Vantage.Web\obj\$BuildConfiguration\Package\*.*" -Destination $targetPath
Copy-Item "$sourcePath\Source\Vantage.Web\obj\$BuildConfiguration\Package\_PublishWeb" -Recurse -Destination $targetPath -Force
Copy-Item "$sourcePath\Source\Vantage.IntegrationTests\bin\$BuildConfiguration\*.*" -Destination $testPath
Copy-Item "$sourcePath\Source\Vantage.Deployment\bin\$BuildConfiguration\*.*" -Destination $fluentMigratorPath
Copy-Item "$sourcePath\Build\*.*" -Destination $scriptPath
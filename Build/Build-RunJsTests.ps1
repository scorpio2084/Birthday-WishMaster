
[CmdletBinding(PositionalBinding=$false)]
param(
    [string]
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $AgentBuildDirectory,

    $buildDriveLetter = "E"
)
             
$jsTestPath = "$AgentBuildDirectory\s\Source\Vantage.UnitTests\Web\Scripts"                    
$resultsPath = "$jsTestPath\TestResults"
$chutzpahExePath = "${buildDriveLetter}:\Tools\Chutzpah\chutzpah.console.exe"

if (-not(Test-Path($resultsPath))) {
        mkdir $resultsPath
}

& $chutzpahExePath /testmode All /path $jsTestPath /junit "$resultsPath\QUnitTestResult.xml"
# This script assumes...
# + {root folder}
#   + Build - where this file lives and user specific settings
#   + Source - folder with the Vantage source code
#   - default.ps1 - psake file with build targets
#
set target=%1
if [%1] == [] set target=default
set settings=%2

"../Source/.nuget/NuGet.exe" restore "../Source/WishMaster.sln"

# Note: psake path below assumes 4.5.0
powershell.exe -NoProfile -ExecutionPolicy unrestricted -Command ^
 "& { Import-Module '.\..\Source\packages\psake.4.5.0\tools\psake.psm1';" ^
 "Invoke-psake .\..\default.ps1 %target% -parameters @{\"namedSettings\"=\"%settings%\";};" ^
 "if ($lastexitcode -ne 0) {write-host "ERROR: $lastexitcode" -fore RED; exit $lastexitcode} }"
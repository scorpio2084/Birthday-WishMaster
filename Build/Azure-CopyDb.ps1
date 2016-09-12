# The name of the server where the source database resides
$ServerName = "reliabuildersql"

# The name of the source database (the database to copy) 
$DatabaseSource = "Vantage_Reliabuilder_Prod" 

# The name of the target database (the name of the copy)
$DatabaseDestination = "Vantage_Reliabuilder_Staging" 

# Copy a database 
Start-AzureSqlDatabaseCopy -ServerName $ServerName -DatabaseName $DatabaseSource -PartnerDatabase $DatabaseDestination -Force

# Wait for copy to complete
$i = 0
$secs = 0
do
{
    $check = Get-AzureSqlDatabaseCopy -ServerName $ServerName -DatabaseName $DatabaseSource -PartnerDatabase $DatabaseDestination
    $i = $check.PercentComplete
    Write-Output "Database Copy ($DatabaseDestination) not complete in $secs seconds"

    $secs += 10
    Start-Sleep -s 10
}
while($i -ne $null -and $secs -lt 600)

Write-Output "($DatabaseDestination) has been created." 

# Change new database pricing tier
$newTier = Get-AzureSqlDatabaseServiceObjective -ServerName reliabuildersql -ServiceObjectiveName S0
Set-AzureSqlDatabase -DatabaseName Vantage_Reliabuilder_Staging -ServerName reliabuildersql -Edition Standard -ServiceObjective $newTier -Force
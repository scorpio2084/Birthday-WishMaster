# The name of the server where the source database resides
$ServerName = "reliabuildersql"

# The name of the target database (the name of the copy)
$PartnerDatabaseName = "Vantage_Reliabuilder_Staging" 

# Remove existing database
Remove-AzureSqlDatabase -ServerName $ServerName -DatabaseName $PartnerDatabaseName -Force

# Monitor the status of the removal
Get-AzureSqlDatabaseOperation -ServerName $ServerName -DatabaseName $PartnerDatabaseName
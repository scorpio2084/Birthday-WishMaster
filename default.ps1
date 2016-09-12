# required parameters :
# 	$databaseName

Framework "4.6"

properties {
	$solutionName = "WishMaster"
	$productName = "WishMaster"
    $unitTestAssembly = "Wish.UnitTests.dll"
    $integrationTestAssembly = "Wish.IntegrationTests.dll"
	$dataLoadTestAssembly = "Wish.Deployment.dll"

    # you can override the following set of properties in your settings file
	$projectConfig = "Debug"
	$databaseName = $solutionName
	$databaseServer = ".\SqlServer"
	$connection_string = "server=$databaseServer;database=$databaseName;Integrated Security=true;"
	$fluentMigratorProvider = "SqlServer2014"
	$fluentMigratorTag = "Developer"
	$vsVersion = "14.0"
	# end of override set

	$base_dir = resolve-path .\
	$source_dir = "$base_dir\Source"
	$packagesPath = "$source_dir\packages"
	$nuGet_dir = "$source_dir\.nuget"
    $7zipPath = "$packagesPath\7-Zip.CommandLine.9.20.0\tools" #todo - use $7zipExePath instead (see Init) 
	
	$build_dir = "$base_dir\build output"
	$testCopyIgnorePath = "_ReSharper"
	$package_dir = "$build_dir\package"	
	$package_file = "$build_dir\latestVersion\" + $solutionName +"_Package.zip"
		
	$web_dir = "$source_dir\Wish.Web" 
	$data_load_dir = "$source_dir\Wish.Deployment"
    $unit_test_dir = "$source_dir\Wish.UnitTests"
	$integration_test_dir = "$source_dir\Wish.IntegrationTests"
    $test_dir = "$build_dir\test"
    $js_test_dir = "$test_dir\Wishmaster.UnitTests\Web\Scripts"

	# including machine and user specific properties
	$userName = $env:UserName
	$computerName = $env:ComputerName

	# from most-specific to least specific. stops after the first match.
	$settingsFileOrder = @("$namedSettings", "$userName-$computerName", "$userName", "$computerName")

	Foreach($set in $settingsFileOrder) {
		$path = "$base_dir\Build\settings-$set.ps1"
		if (Test-Path $path) {
			Write-Host "Loading settings from: $path"
	 		. $path
			break
		}
	}
}

task default -depends Init, Compile, Db-Update, test-unit, test-integration, test-js
task full -depends Init, Compile, Db-Rebuild, test-unit, test-js, Db-LoadTestData, test-integration

task Test {
	Write-Host "Empty task"
}

task Init {
    delete_file $package_file
    delete_directory $build_dir
    create_directory $test_dir
	create_directory $build_dir

	write-host "Source dir: [ $source_dir ]"
	if (Test-Path "$nuGet_dir\NuGet.config") {
		[xml]$nugetConfig = Get-Content $nuGet_dir\NuGet.config;
		$repoPath = $nugetConfig.SelectSingleNode("/configuration/config/add[@key='repositoryPath']")
		if ($repoPath -ne $null) {
			$packagesPath = Resolve-Path (Join-Path $source_dir ".nuget" $repoPath.value)
		}
	}

	$script:migrateExePath = ((Get-ChildItem $packagesPath -Recurse "migrate.exe") | where { $_.FullName -match "FluentMigrator\.[\d\.]+\\tools" }).FullName;
	$script:nunitConsoleExePath = ((Get-ChildItem $packagesPath -Recurse "nunit-console.exe") | where { $_.FullName -match "NUnit.Runners\.[\d\.]+\\tools" }).FullName;
    #$script:chutzpahExePath = ((Get-ChildItem $packagesPath -Recurse "chutzpah.console.exe") | where { $_.FullName -match "Chutzpah\.[\d\.]+\\tools" }).FullName;
	$config = @"
Config: 
DB      : $connection_string
NUnit   : $nunitConsoleExePath
Migrator: $migrateExePath
#Chutzpah: $chutzpahExePath
"@
	Write-Host $config
}

task ConnectionString {
	write-host "Using connection string: $connection_string"
	poke-xml "$web_dir\web.config" "/configuration/connectionStrings/add[@name='DefaultConnection']/@connectionString" $connection_string
	poke-xml "$data_load_dir\App.config" "/configuration/connectionStrings/add[@name='DefaultConnection']/@connectionString" $connection_string
	poke-xml "$integration_test_dir\App.config" "/configuration/connectionStrings/add[@name='DefaultConnection']/@connectionString" $connection_string
}

task Clean -depends Init {
    write-host "Perform clean"
    msbuild /t:clean /v:q /nologo /p:Configuration=debug /p:VisualStudioVersion=$vsVersion $source_dir\$solutionName.sln
    msbuild /t:clean /v:q /nologo /p:Configuration=release /p:VisualStudioVersion=$vsVersion $source_dir\$solutionName.sln
    delete_file $error_dir
}

task Compile -depends Clean {
    write-host "Perform compile"
    msbuild /t:build /v:q /ds /nologo /p:Configuration=$projectConfig /p:VisualStudioVersion=$vsVersion $source_dir\$solutionName.sln
}

task CompileMigrations -depends Init {
    write-host "Compiling Migrations"
    msbuild /t:clean /v:q /ds /nologo /p:Configuration=$projectConfig /p:VisualStudioVersion=$vsVersion $source_dir\Wish.Deployment\Wish.Deployment.csproj
    msbuild /t:build /v:q /ds /nologo /p:Configuration=$projectConfig /p:VisualStudioVersion=$vsVersion $source_dir\Wish.Deployment\Wish.Deployment.csproj
}
task test-clean { 
    delete_directory $test_dir
}

task test-unit -depends Init, test-clean {
	write-host "Starting C# Unit Tests"
    exec {
        & $nunitConsoleExePath $unit_test_dir\bin\$projectConfig\$unitTestAssembly /nologo /nodots /xml=$build_dir\CSharpUnitTestResult.xml    
    }
}

task restore-chutzpah -depends Init {
	Write-Host "Get Chutzpah via NuGet"
	# Note: This is a temp task as NuGet (via the solutions packages config) should fetch Chutzpah.  However, after installing TFS 2015, we ran into a strange issue on the build server involving Chutzpah and it's files (TFS could not delete them for the next build run).  We will try this again in the future.  
	exec {
		& "$nuGet_dir\NuGet" install Chutzpah -version "4.1.0" -NonInteractive -RequireConsent -solutionDir $source_dir
	}
	$script:chutzpahExePath = ((Get-ChildItem $packagesPath -Recurse "chutzpah.console.exe") | where { $_.FullName -match "Chutzpah\.[\d\.]+\\tools" }).FullName;
	Write-Host $script:chutzpahExePath
}

task test-js -depends Init, test-clean, restore-chutzpah {
	write-host "Starting JavaScript Unit Tests"
	copy_js_files $source_dir $test_dir
    exec {
        & $script:chutzpahExePath /testmode All /path $js_test_dir /junit $build_dir\JavascriptUnitTestResult.xml
	}
}

task test-integration -depends Init, test-clean, Compile, Db-Update {
    write-host "Starting integration tests"
	exec {
		& $nunitConsoleExePath $integration_test_dir\bin\$projectConfig\$integrationTestAssembly /nologo /nodots /xml=$build_dir\IntegrationTestResult.xml    
	}
}

task Db-Update -depends ConnectionString, CompileMigrations {
    exec { 
        & $migrateExePath --assembly=$source_dir\Wish.Deployment\bin\$projectConfig\$dataLoadTestAssembly --tag $fluentMigratorTag --provider=$fluentMigratorProvider --conn=DefaultConnection --timeout=600
	}
}

task Db-Rollback -depends ConnectionString, CompileMigrations {
    exec { 
        # todo - provide migration number.
        & $migrateExePath --assembly=$source_dir\Wish.Deployment\bin\$projectConfig\$dataLoadTestAssembly --tag $fluentMigratorTag --provider=$fluentMigratorProvider --conn=DefaultConnection --task rollback-all --timeout=600
	}
}


task Db-Recreate  {
	$cmds = @(
	 "USE MASTER";
	 @"
WHILE EXISTS(select NULL from sys.databases where name='$databaseName')
BEGIN
    DECLARE @SQL varchar(max)
    SELECT @SQL = COALESCE(@SQL,'') + 'Kill ' + Convert(varchar, SPId) + ';'
    FROM MASTER..SysProcesses
    WHERE DBId = DB_ID(N'$databaseName') AND SPId <> @@SPId
    EXEC(@SQL)
    DROP DATABASE [$databaseName]
END
"@;
	"CREATE DATABASE [$databaseName]";
)
	run_sql $connection_string $cmds
}

task Db-Rebuild -depends ConnectionString, CompileMigrations, Db-Recreate, Db-Update {
}

task Db-LoadTestData -depends Db-Recreate {
    exec { 
        # todo - split the building of the DB + system data from the loading of test data
		# do that with migratiom Profiles
    } "Data load failure"  
}

task Package -depends Compile {
    delete_directory $package_dir
	#web app
    copy_website_files "$webapp_dir" "$package_dir\web" 
	
	zip_directory $package_dir $package_file 
}

function global:zip_directory($directory,$file) {
    write-host "Zipping folder: " $test_assembly
    delete_file $file
    cd $directory
    & "$7zipPath\7za.exe" a -mx=9 -r $file
    cd $base_dir
}

function global:copy_website_files($source,$destination) {
    write-host "Copy website files to output directory"
    $exclude = @('*.user','*.dtd','*.tt','*.cs','*.csproj','*.orig', '*.log') 
    copy_files $source $destination $exclude
	delete_directory "$destination\obj"
}

function global:copy_js_files($source, $destination) {
	write-host "Copy JS files to output directory"
	robocopy $source $destination *.js /S /NFL /NDL /NJH /NJS /nc /ns /np
}

function global:copy_files_and_directory_structure($source, $destination, $include=@()) {

	$items = Get-ChildItem $source -Recurse -Include $include | ?{ $_.fullname -notmatch "\\packages\\?" }
	
	foreach ($item in $items)
	{
		$dir = $item.DirectoryName.Replace($source,$destination)
		$target = $item.FullName.Replace($source,$destination)

		if (!(test-path($dir))) { 
			create_directory($dir)
		}

		copy-item -path $item.FullName -destination $target -recurse -force
	}	
}

function global:copy_files($source,$destination,$exclude=@()){    
    create_directory $destination

	Get-ChildItem $source -Recurse -Exclude $exclude | Copy-Item -Destination {Join-Path $destination $_.FullName.Substring($source.length)}
}

function global:Copy_and_flatten ($source,$filter,$dest) {
  ls $source -filter $filter  -r | Where-Object{!$_.FullName.Contains("$testCopyIgnorePath") -and !$_.FullName.Contains("packages") }| cp -dest $dest -force
}

function global:copy_all_assemblies_for_test($destination){
  write-host "Copy assemblies to output directory" 
  create_directory $destination
  Copy_and_flatten $source_dir\*\bin\$projectConfig *.dll $destination
  Copy_and_flatten $source_dir\*\bin\$projectConfig *.config $destination
  Copy_and_flatten $source_dir\*\bin\$projectConfig *.xml $destination
  Copy_and_flatten $source_dir\*\bin\$projectConfig *.pdb $destination
  Copy_and_flatten $source_dir\*\bin\$projectConfig *.xlsx $destination
  write-host "All files copied to output directory"
}

function global:delete_file($file) {
    if($file) { remove-item $file -force -ErrorAction SilentlyContinue | out-null } 
}

function global:delete_directory($directory_name)
{
  rd $directory_name -recurse -force  -ErrorAction SilentlyContinue | out-null
}

function global:delete_files_in_dir($dir)
{
	get-childitem $dir -recurse | foreach ($_) {remove-item $_.fullname}
}

function global:create_directory($directory_name)
{
  mkdir $directory_name  -ErrorAction SilentlyContinue  | out-null
}

function global:run_sql($connectionString, $sqlCommands) {
	echo "Will run $sqlCommands against $connectionString"
    $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    $connection.Open()
	foreach($cmd in $sqlCommands) {
		$command = new-object system.data.sqlclient.sqlcommand($cmd, $connection)
		if ($command.ExecuteNonQuery() -ne -1) {
			echo "Failed to execute SQL command: $cmd"
		}
	}

    $connection.Close()
}

function script:poke-xml($filePath, $xpath, $value, $namespaces = @{}) {
    [xml] $fileXml = Get-Content $filePath
    
    if($namespaces -ne $null -and $namespaces.Count -gt 0) {
        $ns = New-Object Xml.XmlNamespaceManager $fileXml.NameTable
        $namespaces.GetEnumerator() | %{ $ns.AddNamespace($_.Key,$_.Value) }
        $node = $fileXml.SelectSingleNode($xpath,$ns)
    } else {
        $node = $fileXml.SelectSingleNode($xpath)
    }
    
    Assert ($node -ne $null) "could not find node @ $xpath"
        
    if($node.NodeType -eq "Element") {
        $node.InnerText = $value
    } else {
        $node.Value = $value
    }

    $fileXml.Save($filePath) 
} 

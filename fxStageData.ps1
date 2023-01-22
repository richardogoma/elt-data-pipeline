Param(
    [string]$InstanceName = 'localhost'
    ,[string]$Database = 'NLNGProjects'
    ,[string]$SourceFile = '.\20230109-111923-8266970-requests-1.csv'
    ,[string]$SqlDataType = 'VARCHAR(MAX)'
    ,[string]$TableName = 'Requests'
)
# =========================================

function Import-CsvToSqlTable {
    [CmdletBinding()]
    param([string]$InstanceName
          ,[string]$Database
          ,[string]$SourceFile
          ,[string]$SqlDataType = 'VARCHAR(255)'
          ,[pscredential]$SqlCred
          ,[string]$TableName
          ,[Switch]$Append
          )
    
        #Check file existence. Should be a perfmon csv
        if(-not (Test-Path $SourceFile) -and $SourceFile -notlike '*.csv'){
            Write-Error "Invalid file: $SourceFile"
        }
    
        $source = Get-ChildItem $SourceFile
    
        #Cleanup input file (Quoted Identifiers)
        Write-Verbose "[Clean Inputs]"
        (Get-Content $source).Replace('"','') | Set-Content $source
        
        #Get csv header row, create staging table for load, remove first item 'cause it's junk
        $Header = (Get-Content $source | Select-Object -First 1).Split(',')
        $CleanHeader = @()
    
        #Cleanup header names to be used column names
        #Remove non-alphanumeric characters
        foreach($h in $Header){
            $CleanValue = $h -Replace '[^a-zA-Z0-9_]',''
            $CleanHeader += $CleanValue
            Write-Verbose "[Cleaned Header] $h -> $CleanValue"
        }

        function BuildSQL {
            param (
                [array]$sql, 
                [array]$CleanHeader, 
                [string]$SqlDataType, 
                [string]$TableName
            )
            
            $sql += ("CREATE TABLE [$TableName]($($CleanHeader[0]) {0} `n" -f 'INT PRIMARY KEY')
            $CleanHeader[1..$CleanHeader.Length] | ForEach-Object {$sql += ",$_ $SqlDataType `n"}
            $sql += ");"
            $sql = $sql -join "`n"
            Write-Verbose "[CREATE TABLE Statement] $sql"

            return $sql
        }
    
        # Build create table statement if loading table does not exist
        $StagingTableName = "temp_{0}" -f $TableName
        if(-not $Append){
            $tempsql = @("IF EXISTS (SELECT 1 FROM sys.tables WHERE name  = '$StagingTableName') DROP TABLE [$StagingTableName];")
        } else {
             $tempsql = @("IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name  = '$StagingTableName')")
        }
        $tempsql = BuildSQL -sql $tempsql -CleanHeader $CleanHeader -SqlDataType $SqlDataType -TableName $StagingTableName

        # Build create table statement if integration table does not exist
        $IntegrationTableName = "prod_{0}" -f $TableName
        $prodsql = @("IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name  = '$IntegrationTableName')")
        $prodsql = BuildSQL -sql $prodsql -CleanHeader $CleanHeader -SqlDataType $SqlDataType -TableName $IntegrationTableName
        
        # Executing create table statements and loading data into staging area
        try{
            if($SqlCred){
                Invoke-Sqlcmd -ServerInstance $InstanceName -Database $Database -Query $tempsql -Username $SqlCred.UserName -Password $SqlCred.GetNetworkCredential().Password
                Invoke-Sqlcmd -ServerInstance $InstanceName -Database $Database -Query $prodsql -Username $SqlCred.UserName -Password $SqlCred.GetNetworkCredential().Password
                $cmd = "bcp 'dbo.$StagingTableName' in '$SourceFile' -S'$InstanceName' -d'$Database' -F2 -c -t',' -U'$($SqlCred.UserName)' -P'$($SqlCred.GetNetworkCredential().Password)'"
            } else {
                Invoke-Sqlcmd -ServerInstance $InstanceName -Database $Database -Query $tempsql
                Invoke-Sqlcmd -ServerInstance $InstanceName -Database $Database -Query $prodsql
                $cmd = "bcp 'dbo.$StagingTableName' in '$SourceFile' -S'$InstanceName' -d'$Database' -F2 -c -t',' -T"
            }
            Write-Verbose "[BCP Command] $cmd"
        
            $cmdout = Invoke-Expression $cmd
            if($cmdout -join '' -like '*error*'){
                throw $cmdout
            }
            Write-Verbose "[BCP Results] $cmdout"
            if($SqlCred){
                $rowcount = Invoke-Sqlcmd -ServerInstance $InstanceName -Database $Database -Query "SELECT COUNT(1) [RowCount] FROM [$StagingTableName];" -Username $SqlCred.UserName -Password $SqlCred.GetNetworkCredential().Password
            } else {
                $rowcount = Invoke-Sqlcmd -ServerInstance $InstanceName -Database $Database -Query "SELECT COUNT(1) [RowCount] FROM [$StagingTableName];"
            }
            $output = New-Object PSObject -Property @{'Instance'=$InstanceName;'Database'=$Database;'Table'="$StagingTableName";'RowCount'=$rowcount.RowCount}

            # Start background job to integrate staged data with production data (incrementally)
            Start-Job -ScriptBlock { param($InstanceName, $Database, $TableName, $PrimaryKey)
                & ".\fxIntegrateStagedData.ps1" -InstanceName $InstanceName -Database $Database -TableName $TableName -PrimaryKey $PrimaryKey
                } -ArgumentList $InstanceName, $Database, $TableName, $($CleanHeader[0])

            Write-Output "Loading source data into the staging area" >> ProgramLog.log
            return $output >> ProgramLog.log
        
        }
        catch{
            Write-Error $Error[0] -ErrorAction Stop
        }
    }

Import-CsvToSqlTable -InstanceName $InstanceName -Database $Database -SourceFile $SourceFile `
    -TableName $TableName -SqlDataType $SqlDataType # -Verbose





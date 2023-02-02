Param(
    [string]$InstanceName
    ,[string]$Database
    ,[string]$SourceFile 
    ,[string]$SqlDataType
    ,[string]$TableName
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
            $tempsql += ("CREATE TABLE [$StagingTableName]($($CleanHeader[0]) $SqlDataType `n")
        } else {
             $tempsql = @("IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name  = '$StagingTableName')")
             $tempsql += ("CREATE TABLE [$StagingTableName]($($CleanHeader[0]) $SqlDataType `n")
        }
        $tempsql = BuildSQL -sql $tempsql -CleanHeader $CleanHeader -SqlDataType $SqlDataType -TableName $StagingTableName

        # Build create table statement if integration table does not exist
        $IntegrationTableName = $TableName
        $prodsql = @("IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name  = '$IntegrationTableName')")
        $prodsql += ("CREATE TABLE [$IntegrationTableName]($($CleanHeader[0]) {0} `n" -f 'INT PRIMARY KEY')
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
            $output = New-Object PSObject -Property @{'Instance'=$InstanceName;'Database'=$Database;'Table'="$StagingTableName";'RowCount'=$rowcount.RowCount;'Timestamp'=Get-Date}

            # Write to log file
            . .\fxWriteLog.ps1
            Write-Function -data $output -description "Loading source data into the staging area" -file "ProgramLog.log"
        }
        catch{
            throw $Error[0]; $Error.Clear()
        }
    }

Import-CsvToSqlTable -InstanceName $InstanceName -Database $Database -SourceFile $SourceFile -TableName $TableName -SqlDataType $SqlDataType # -Verbose




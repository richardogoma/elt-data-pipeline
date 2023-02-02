Param(
     [string]$InstanceName
    ,[string]$Database
    ,[pscredential]$SqlCred
    ,[string]$TableName
    ,[string]$PrimaryKey
)
# =========================================

function IntegrateData {
    [CmdletBinding()]
    param(
           [string]$InstanceName
          ,[string]$Database
          ,[pscredential]$SqlCred
          ,[string]$TableName
          ,[string]$PrimaryKey
          )

    $FileVariables=@(
        "TableName=$TableName",
        "PrimaryKey=$PrimaryKey"
    )

    $Params=@{
        ServerInstance=$InstanceName
        Database=$Database
        InputFile=".\DML-IntegrationTbl.sql"
        Variable=$FileVariables
    }

    try {
        if($SqlCred){
            $rowcount = Invoke-Sqlcmd @Params -Username $SqlCred.UserName -Password $SqlCred.GetNetworkCredential().Password
        } else {
            $rowcount = Invoke-Sqlcmd @Params
        }
        $output = New-Object PSObject -Property @{'Instance'=$InstanceName;'Database'=$Database;'Table'="[dbo].[$TableName]";'NewRowsCount'=$rowcount.NewRowsCount;'Timestamp'=Get-Date}

        # Write to log file
        . .\fxWriteLog.ps1
        Write-Function -data $output -description "Loading new data into the integration table" -file "ProgramLog.log"
    }
    catch {
        throw $Error[0]; $Error.Clear()
    }
    
}

IntegrateData -InstanceName $InstanceName -Database $Database -TableName $TableName -PrimaryKey $PrimaryKey
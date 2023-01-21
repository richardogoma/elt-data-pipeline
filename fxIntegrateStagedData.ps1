Param(
     [string]$InstanceName
    ,[string]$Database
    ,[pscredential]$SqlCred
    ,[string]$TableName
)

function IntegrateData {
    [CmdletBinding()]
    param(
           [string]$InstanceName
          ,[string]$Database
          ,[pscredential]$SqlCred
          ,[string]$TableName
          )

    $DBParam = "TableName=" + $TableName

    if($SqlCred){
        $rowcount = Invoke-Sqlcmd -ServerInstance $InstanceName -Database $Database -InputFile ".\DML-IntegrationTbl.sql" -Variable $DBParam -Username $SqlCred.UserName -Password $SqlCred.GetNetworkCredential().Password
    } else {
        $rowcount = Invoke-Sqlcmd -ServerInstance $InstanceName -Database $Database -InputFile ".\DML-IntegrationTbl.sql" -Variable $DBParam
    }
    $output = New-Object PSObject -Property @{'Instance'=$InstanceName;'Database'=$Database;'Table'="[dbo].[prod_$TableName]";'NewRowsCount'=$rowcount.NewRowsCount}
    
    Write-Output "Loading new data into the integration table" >> ProgramLog.log
    return $output >> ProgramLog.log
}

IntegrateData -InstanceName $InstanceName -Database $Database -TableName $TableName
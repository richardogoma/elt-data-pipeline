Param(
    [string]$InstanceName = 'localhost'
    ,[string]$Database = 'NLNGProjects'
    ,[string]$SourceFile = '.\20230124-190224-8308822-workflows-1.csv'
    ,[string]$SqlDataType = 'VARCHAR(MAX)'
    ,[string]$TableName = 'tblNLNGITWorkflows'
    ,[string]$cwd
    ,[string]$PrimaryKey = 'ID'
)

# ==========================
if ($cwd.Length -ne 0) {
    Set-Location -Path "$cwd\ELT_development"
}
# ==========================

try {
    # Start background job to load data into the staging area
    $job = Start-Job -ScriptBlock { param($InstanceName, $Database, $SourceFile, $SqlDataType, $TableName)
            & ".\fxStageData.ps1" -InstanceName $InstanceName -Database $Database -SourceFile $SourceFile -SqlDataType $SqlDataType -TableName $TableName
        } -ArgumentList $InstanceName, $Database, $SourceFile, $SqlDataType, $TableName

        # Get the results of the job
        Receive-Job -Job $job -Wait -AutoRemoveJob -ErrorAction Stop

        if($job.State -eq "Completed") {

            Write-Output "Source data staging complete >>> integrating data ..."
            # Start background job to integrate staged data with production data (incrementally)
            $childjob = Start-Job -ScriptBlock { param($InstanceName, $Database, $TableName, $PrimaryKey)
                    & ".\fxIntegrateStagedData.ps1" -InstanceName $InstanceName -Database $Database -TableName $TableName -PrimaryKey $PrimaryKey
                } -ArgumentList $InstanceName, $Database, $TableName, $PrimaryKey
            
            # Get the results of the job
            Receive-Job -Job $childjob -Wait -AutoRemoveJob -ErrorAction Stop
            
            Write-Output "Data integration complete. See program log."

        }
}
catch {
    throw $Error[0]; $Error.Clear()
}

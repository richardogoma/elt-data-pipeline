Param(
    [string]$InstanceName = 'localhost'
    ,[string]$Database = 'NLNGProjects'
    ,[string]$SourceFile = '.\20230109-111923-8266970-requests-1.csv'
    ,[string]$SqlDataType = 'VARCHAR(MAX)'
    ,[string]$TableName = 'tblNLNGITRequests'
)

# ==========================
Set-Variable -Name 'PrimaryKey' -Value 'ID'

try {
    # Start background job to load data into the staging area
    $job = Start-Job -ScriptBlock { param($InstanceName, $Database, $SourceFile, $SqlDataType, $TableName)
        & ".\fxStageData.ps1" -InstanceName $InstanceName -Database $Database -SourceFile $SourceFile -SqlDataType $SqlDataType -TableName $TableName
        } -ArgumentList $InstanceName, $Database, $SourceFile, $SqlDataType, $TableName
    
        # Wait for the job to complete
        Wait-Job -Job $job

        if($job.State -eq "Completed") {

            # Start background job to integrate staged data with production data (incrementally)
            Start-Job -ScriptBlock { param($InstanceName, $Database, $TableName, $PrimaryKey)
                & ".\fxIntegrateStagedData.ps1" -InstanceName $InstanceName -Database $Database -TableName $TableName -PrimaryKey $PrimaryKey
                } -ArgumentList $InstanceName, $Database, $TableName, $PrimaryKey
            }
}
catch {
    Write-Error $Error[0] -ErrorAction Stop
}

# =========================================

<#
    # Get the status of all jobs in the current session
    Get-Job

    # Start background job
    $job = start-job {get-process}

    # Wait for the job to complete
    Wait-Job -Job $job

    # View job state
    $job.state

    # Get the results of the job
    $resp = Receive-Job -Job $job

    # Remove the job from the session
    Remove-Job -Job $job

    $resp
#>

        

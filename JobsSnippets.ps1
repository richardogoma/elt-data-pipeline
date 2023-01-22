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

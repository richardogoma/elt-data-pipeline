Function Write-Function {
    param ($data, $description, $file)

    $retryCount = 0
    $maxRetries = 10

    while ($retryCount -lt $maxRetries) {
      try {
        Write-Output $description | Out-File -FilePath $file -Append
        $data | Out-File -FilePath $file -Append
        break
      } catch [System.IO.IOException] {
        if ($_.Exception.Message -like "being used by another process") {
          $retryCount++
          Write-Host "File is locked, retrying in 1 second..."
          Start-Sleep -Seconds 1
        } else {
          Write-Host "Unexpected error: $_"
          break
        }
      }
    }

    if ($retryCount -eq $maxRetries) {
      Write-Host "Maximum number of retries reached, giving up."
    }
}
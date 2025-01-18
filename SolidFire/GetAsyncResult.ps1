# Force PowerShell to Use TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Bypass SSL Certificate Validation (For Testing Only)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# Define the SolidFire API endpoint and credentials
$ClusterIP = "10.208.94.40"
$Username = "admin"
$Password = "milcalVDC!"
$ApiUrl = "https://$ClusterIP/json-rpc/10.0"

# Encode credentials for basic authentication
$AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${Password}"))
$Headers = @{
    "Authorization" = "Basic $AuthInfo"
    "Content-Type" = "application/json"
}

# Prompt for asyncHandle
$AsyncHandle = Read-Host "Enter the asyncHandle for the operation"

# Define the JSON payload for the API call
$Payload = @{
    method = "GetAsyncResult"
    params = @{
        asyncHandle = (107)
    }
    id = 1
} | ConvertTo-Json -Depth 10 -Compress

# Make the API call
try {
    $Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Headers $Headers -Body $Payload

    # Check the status of the operation
    $Status = $Response.result.status
    Write-Host "Async operation status: $Status"

    if ($Status -eq "complete") {
        # Check for errors or results
        if ($null -ne $Response.result.error) {
            $ErrorDetails = $Response.result.error
            Write-Host "The operation completed with errors:" -ForegroundColor Red
            Write-Host "Error Name: $($ErrorDetails.name)"
            Write-Host "Error Message: $($ErrorDetails.message)"
        } else {
            $Result = $Response.result.result
            Write-Host "The operation completed successfully with the following result:" -ForegroundColor Green
            $Result | Format-List
        }
    } elseif ($Status -eq "running") {
        Write-Host "The operation is still running. Check again later." -ForegroundColor Yellow
    } else {
        Write-Host "The operation status is unknown or unexpected. Details:" -ForegroundColor Red
        $Response.result | Format-List
    }

} catch {
    Write-Error "Failed to retrieve async result: $_"
}
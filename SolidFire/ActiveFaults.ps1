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

# Define the JSON payload for the API call
$Payload = @{
    method = "ListClusterFaults"
    params = @{
        faultTypes = "current"
        bestPractices = $false
    }
    id = 1
} | ConvertTo-Json -Depth 10 -Compress

# Make the API call
$Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Headers $Headers -Body $Payload
$Faults = $Response.result.faults

# Display the faults with additional details
if ($Faults.Count -eq 0) {
    Write-Host "No active faults found on the cluster."
} else {
    $Faults | ForEach-Object {
        [PSCustomObject]@{
            FaultID       = $_.clusterFaultID
            Severity      = $_.severity
            Type          = $_.type
            Node          = $_.nodeID
            DriveID       = $_.driveID
            ErrorCode     = $_.code
            Details       = $_.details
            FaultSpecific = $_.data       # Additional fault-specific details
            Date          = $_.date
        }
    } | Format-Table -AutoSize
}
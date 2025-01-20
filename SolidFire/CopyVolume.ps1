# Force PowerShell to Use TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Bypass SSL Certificate Validation (For Testing Only)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }


# Define the API endpoint and credentials
$SolidFireAPI = "https://<ClusterManagementEndpoint>/json-rpc/10.0"
$User = "admin"
$Password = "milcalVDC!"

# Parameters for CopyVolume
$SourceVolumeID = 3    # Replace with the source volume ID
$DestinationVolumeID = 2  # Replace with the destination volume ID

# Optional parameter: Snapshot ID (use current active volume if not provided)
$SnapshotID = $null  # Set to an integer value if you want to copy from a specific snapshot

# Prepare the request payload
$Params = @{
    volumeID = $SourceVolumeID
    dstVolumeID = $DestinationVolumeID
}
if ($SnapshotID -ne $null) {
    $Params.snapshotID = $SnapshotID
}

$Payload = @{
    method = "CopyVolume"
    params = $Params
    id = 1
} | ConvertTo-Json -Depth 10

# Debug: Output the payload for verification
Write-Host "Payload: $($Payload | ConvertTo-Json -Depth 10)" -ForegroundColor Cyan

# Make the API request
try {
    Write-Host "Starting CopyVolume operation from volume ID $SourceVolumeID to $DestinationVolumeID..." -ForegroundColor Yellow

    $Response = Invoke-RestMethod -Uri $SolidFireAPI -Method Post -Body $Payload -ContentType "application/json" -Credential (New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString $Password -AsPlainText -Force)))

    # Handle the response
    if ($Response.result) {
        $AsyncHandle = $Response.result.asyncHandle
        $CloneID = $Response.result.cloneID
        Write-Host "CopyVolume initiated successfully." -ForegroundColor Green
        Write-Host "  Async Handle: $AsyncHandle"
        Write-Host "  Clone ID: $CloneID"
    } else {
        Write-Host "CopyVolume operation completed, but no result returned." -ForegroundColor Red
    }
} catch {
    Write-Host "An error occurred during CopyVolume: $_" -ForegroundColor Red
}
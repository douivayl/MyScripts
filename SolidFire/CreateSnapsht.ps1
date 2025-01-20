# Force PowerShell to Use TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Bypass SSL Certificate Validation (For Testing Only)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# Define the API endpoint and credentials
$SolidFireAPI = "https://10.208.94.40/json-rpc/10.0"
$User = "admin"
$Password = "milcalVDC!"


# Specify the volume ID for which to create a snapshot
$VolumeID = 10  # Replace with the source volume ID

# Optional: Name and description for the snapshot
$SnapshotName = "ManualSnapshot_" + (Get-Date -Format "yyyyMMddHHmmss")
$SnapshotDescription = "Created manually via PowerShell script on " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# Prepare the request payload
$Payload = @{
    method = "CreateSnapshot"
    params = @{
        volumeID = $VolumeID
        name = $SnapshotName
        attributes = @{
            description = $SnapshotDescription
        }
    }
    id = 1
} | ConvertTo-Json -Depth 10

# Debug: Output the payload for verification
Write-Host "Payload: $($Payload | ConvertTo-Json -Depth 10)" -ForegroundColor Cyan

# Make the API request
try {
    Write-Host "Creating snapshot for volume ID $VolumeID..." -ForegroundColor Yellow

    $Response = Invoke-RestMethod -Uri $SolidFireAPI -Method Post -Body $Payload -ContentType "application/json" -Credential (New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString $Password -AsPlainText -Force)))

    # Handle the response
    if ($Response.result) {
        $SnapshotID = $Response.result.snapshotID
        Write-Host "Snapshot created successfully." -ForegroundColor Green
        Write-Host "  Snapshot ID: $SnapshotID"
        Write-Host "  Snapshot Name: $SnapshotName"
    } else {
        Write-Host "Snapshot creation completed, but no result returned." -ForegroundColor Red
    }
} catch {
    Write-Host "An error occurred while creating the snapshot: $_" -ForegroundColor Red
}
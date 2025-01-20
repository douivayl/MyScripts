# Force PowerShell to Use TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Bypass SSL Certificate Validation (For Testing Only)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }


# Define the API endpoint and credentials
$SolidFireAPI = "https://<ClusterManagementEndpoint>/json-rpc/10.0"
$User = "admin"
$Password = "milcalVDC!"

# Parameters for the volume
$VolumeName = "TestVolumeRec09"
$VolumeSizeGB = 6144  # 6TB = 6144GB
$AccountID = <AccountID>  # Replace with the actual account ID

# Convert volume size to bytes (1 GB = 1024^3 bytes)
$VolumeSizeBytes = $VolumeSizeGB * 1GB

# Prepare the request payload
$Payload = @{
    method = "CreateVolume"
    params = @{
        name = $VolumeName
        accountID = $AccountID
        totalSize = $VolumeSizeBytes
    }
    id = 1
} | ConvertTo-Json -Depth 10

# Debug: Output the payload for verification
Write-Host "Payload: $($Payload | ConvertTo-Json -Depth 10)" -ForegroundColor Cyan

# Make the API request
try {
    Write-Host "Creating volume '$VolumeName' with size $VolumeSizeGB GB..." -ForegroundColor Yellow

    $Response = Invoke-RestMethod -Uri $SolidFireAPI -Method Post -Body $Payload -ContentType "application/json" -Credential (New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString $Password -AsPlainText -Force)))

    # Handle the response
    if ($Response.result) {
        $VolumeID = $Response.result.volume.volumeID
        Write-Host "Volume created successfully. Volume ID: $VolumeID" -ForegroundColor Green
    } else {
        Write-Host "Volume creation completed, but no result returned." -ForegroundColor Red
    }
} catch {
    Write-Host "An error occurred while creating the volume: $_" -ForegroundColor Red
}

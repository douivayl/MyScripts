# Force TLS 1.2 for Secure Communication
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Bypass SSL Certificate Validation (For Testing Only)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# Define API URL
$ApiUrl = "https://10.208.174.40/json-rpc/10.0"

# Define Credentials
$Username = "admin"
$Password = "fraschVDC!"

# Create Basic Authentication Header
$Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${Password}"))

# Define Headers
$Headers = @{
    "Content-Type"  = "application/json"
    "Authorization" = "Basic $Auth"
}

# Function to List Snapshots for a Given Volume ID
function Get-SnapshotsForVolume {
    param (
        [int]$VolumeID
    )
    # Define Request Body
    $Body = @{
        method = "ListSnapshots"
        params = @{
            volumeID = $VolumeID
        }
        id = 1
    } | ConvertTo-Json -Depth 10

    # Send API Request
    $Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Body $Body -Headers $Headers

    # Extract and Return Snapshots
    if ($Response.result.snapshots) {
        return $Response.result.snapshots | Select-Object Name, SnapshotID, CreateTime, Status, TotalSize, VolumeID
    } else {
        Write-Output "No snapshots found for volume ID: $VolumeID"
        return @()
    }
}

# List of Volume IDs
$VolumeIDs = @(92, 25, 26)

# Iterate Over Each Volume and Retrieve Snapshots
foreach ($VolumeID in $VolumeIDs) {
    Write-Output "Snapshots for Volume ID: $VolumeID"
    $Snapshots = Get-SnapshotsForVolume -VolumeID $VolumeID
    $Snapshots | Format-Table -AutoSize
}
<#
.SYNOPSIS
    Create a new snapshot for a SolidFire volume.

.DESCRIPTION
    This script creates a new snapshot for a specified SolidFire volume.
    The snapshot is assigned a name and description based on the timestamp.

.PARAMETER IPAddress
    The management IP address of the SolidFire cluster.

.PARAMETER Username
    The username for SolidFire admin.

.PARAMETER Password
    The password for SolidFire admin.

.PARAMETER VolumeID
    The ID of the volume for which to create a snapshot.

.EXAMPLE
    .\Create-SolidFireSnapshot.ps1 -IPAddress "10.10.10.1" -Username "admin" -Password "yourPassword" -VolumeID 123

    Creates a snapshot for volume ID 123.

.EXAMPLE
    .\Create-SolidFireSnapshot.ps1

    Prompts for credentials, volume ID, and creates the snapshot.

.OUTPUTS
    The script will display output similar to this:

    Creating snapshot for volume ID 123...
    Snapshot created successfully.
      Snapshot ID: 4567
      Snapshot Name: ManualSnapshot_202402041200

.NOTES
    This script forces the use of TLS 1.2 and bypasses SSL certificate validation in order to work with my specific host for running the script.
    You may not need it at all, depending on your Windows host.
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

param (
    [string]$IPAddress,
    [string]$Username,
    [string]$Password,
    [int]$VolumeID
)

function Create-SolidFireSnapshot {
    param (
        [string]$IPAddress,
        [string]$Username,
        [string]$Password,
        [int]$VolumeID
    )

    if (-not $IPAddress) {
        $IPAddress = Read-Host "Enter the SolidFire API IP address"
    }
    if (-not $Username) {
        $Username = Read-Host "Enter your SolidFire username"
    }
    if (-not $Password) {
        $Password = Read-Host "Enter your SolidFire password" -AsSecureString
        $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
        )
    }
    if (-not $VolumeID -or $VolumeID -le 0) {
        $VolumeID = Read-Host "Enter the volume ID for the snapshot" -as [int]
    }

    $apiUrl = "https://$IPAddress/json-rpc/11.0"
    $authInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${Password}"))
    $headers = @{
        "Authorization" = "Basic $authInfo"
        "Content-Type"  = "application/json"
    }

    # Generate snapshot name and description
    $snapshotName = "ManualSnapshot_" + (Get-Date -Format "yyyyMMddHHmm")
    $snapshotDescription = "Created manually via PowerShell script on " + (Get-Date -Format "yyyy-MM-dd HH:mm")

    $payload = @"
{
    "method": "CreateSnapshot",
    "params": {
        "volumeID": $VolumeID,
        "name": "$snapshotName",
        "attributes": {
            "description": "$snapshotDescription"
        }
    },
    "id": 1
}
"@

    try {
        Write-Host "Creating snapshot for volume ID $VolumeID..." -ForegroundColor Yellow
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $payload

        if ($response.result) {
            $snapshotID = $response.result.snapshotID
            Write-Host "✅ Snapshot created successfully." -ForegroundColor Green
            Write-Host "  Snapshot ID: $snapshotID"
            Write-Host "  Snapshot Name: $snapshotName"
        } else {
            Write-Host "❌ Snapshot creation completed, but no result returned." -ForegroundColor Red
        }
    } catch {
        Write-Host "🚨 Error creating snapshot: $_" -ForegroundColor Red
    }
}

Create-SolidFireSnapshot -IPAddress $IPAddress -Username $Username -Password $Password -VolumeID $VolumeID

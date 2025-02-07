<#
.SYNOPSIS
    Create a new volume in a SolidFire cluster.

.DESCRIPTION
    This script creates a new volume in a SolidFire cluster with a specified name, size, and account ID.
    It ensures correct input validation and displays the response upon successful creation.

.PARAMETER IPAddress
    The management IP address of the SolidFire cluster.

.PARAMETER Username
    The username for SolidFire admin.

.PARAMETER Password
    The password for SolidFire admin.

.PARAMETER VolumeName
    The name of the new volume.

.PARAMETER VolumeSizeGB
    The size of the volume in gigabytes (GB).

.PARAMETER AccountID
    The account ID associated with the volume.

.EXAMPLE
    .\Create-SolidFireVolume.ps1 -IPAddress "10.10.10.1" -Username "admin" -Password "yourPassword" -VolumeName "DataVol1" -VolumeSizeGB 1024 -AccountID 123

    Creates a new 1TB volume named "DataVol1" for account ID 123.

.EXAMPLE
    .\Create-SolidFireVolume.ps1

    Prompts for credentials, volume details, and creates the volume.

.OUTPUTS
    The script will display output similar to this:

    Creating volume 'DataVol1' with size 1024 GB...
    Volume created successfully. Volume ID: 4567

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
    [string]$VolumeName,
    [int]$VolumeSizeGB,
    [int]$AccountID
)

function Create-SolidFireVolume {
    param (
        [string]$IPAddress,
        [string]$Username,
        [string]$Password,
        [string]$VolumeName,
        [int]$VolumeSizeGB,
        [int]$AccountID
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
    if (-not $VolumeName) {
        $VolumeName = Read-Host "Enter the name of the new volume"
    }
    if (-not $VolumeSizeGB -or $VolumeSizeGB -le 0) {
        $VolumeSizeGB = Read-Host "Enter the volume size in GB (minimum 1GB)" -as [int]
    }
    if (-not $AccountID -or $AccountID -le 0) {
        $AccountID = Read-Host "Enter the associated account ID" -as [int]
    }

    $apiUrl = "https://$IPAddress/json-rpc/11.0"
    $authInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${Password}"))
    $headers = @{
        "Authorization" = "Basic $authInfo"
        "Content-Type"  = "application/json"
    }

    # Convert volume size from GB to bytes
    $volumeSizeBytes = $VolumeSizeGB * 1GB

    $payload = @"
{
    "method": "CreateVolume",
    "params": {
        "name": "$VolumeName",
        "accountID": $AccountID,
        "totalSize": $volumeSizeBytes
    },
    "id": 1
}
"@

    try {
        Write-Host "Creating volume '$VolumeName' with size $VolumeSizeGB GB..." -ForegroundColor Yellow
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $payload

        if ($response.result) {
            $volumeID = $response.result.volume.volumeID
            Write-Host "✅ Volume created successfully. Volume ID: $volumeID" -ForegroundColor Green
        } else {
            Write-Host "❌ Volume creation completed, but no result returned." -ForegroundColor Red
        }
    } catch {
        Write-Host "🚨 Error creating volume: $_" -ForegroundColor Red
    }
}

Create-SolidFireVolume -IPAddress $IPAddress -Username $Username -Password $Password -VolumeName $VolumeName -VolumeSizeGB $VolumeSizeGB -AccountID $AccountID

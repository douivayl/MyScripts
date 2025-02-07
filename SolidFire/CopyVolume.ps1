<#
.SYNOPSIS
    Copies a SolidFire volume to another volume.

.DESCRIPTION
    This script initiates a volume copy operation from a source volume to a destination volume.
    Optionally, a snapshot ID can be specified for copying from a specific snapshot.

.PARAMETER IPAddress
    The management IP address of the SolidFire cluster.

.PARAMETER Username
    The username for SolidFire admin.

.PARAMETER Password
    The password for SolidFire admin.

.PARAMETER SourceVolumeID
    The ID of the source volume to copy from.

.PARAMETER DestinationVolumeID
    The ID of the destination volume to copy to.

.PARAMETER SnapshotID
    (Optional) The snapshot ID to copy from. If not provided, the active volume is used.

.EXAMPLE
    .\Copy-SolidFireVolume.ps1 -IPAddress "10.10.10.1" -Username "admin" -Password "yourPassword" -SourceVolumeID 3 -DestinationVolumeID 2

    Copies volume ID 3 to volume ID 2 using the active volume.

.EXAMPLE
    .\Copy-SolidFireVolume.ps1

    Prompts for credentials, volume IDs, and optional snapshot ID before copying.

.OUTPUTS
    The script will display output similar to this:

    Starting CopyVolume operation from volume ID 3 to 2...
    CopyVolume initiated successfully.
      Async Handle: 789654
      Clone ID: 2345

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
    [int]$SourceVolumeID,
    [int]$DestinationVolumeID,
    [int]$SnapshotID
)

function Copy-SolidFireVolume {
    param (
        [string]$IPAddress,
        [string]$Username,
        [string]$Password,
        [int]$SourceVolumeID,
        [int]$DestinationVolumeID,
        [int]$SnapshotID
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
    if (-not $SourceVolumeID -or $SourceVolumeID -le 0) {
        $SourceVolumeID = Read-Host "Enter the source volume ID" -as [int]
    }
    if (-not $DestinationVolumeID -or $DestinationVolumeID -le 0) {
        $DestinationVolumeID = Read-Host "Enter the destination volume ID" -as [int]
    }
    if (-not $SnapshotID -or $SnapshotID -le 0) {
        $SnapshotID = $null
    }

    $apiUrl = "https://$IPAddress/json-rpc/11.0"
    $authInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${Password}"))
    $headers = @{
        "Authorization" = "Basic $authInfo"
        "Content-Type"  = "application/json"
    }

    # Prepare the request payload
    $params = @{
        volumeID   = $SourceVolumeID
        dstVolumeID = $DestinationVolumeID
    }

    if ($SnapshotID -ne $null) {
        $params.snapshotID = $SnapshotID
    }

    $payload = @{
        "method" = "CopyVolume"
        "params" = $params
        "id" = 1
    } | ConvertTo-Json -Depth 10

    try {
        Write-Host "Starting CopyVolume operation from volume ID $SourceVolumeID to $DestinationVolumeID..." -ForegroundColor Yellow
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $payload

        if ($response.result) {
            $asyncHandle = $response.result.asyncHandle
            $cloneID = $response.result.cloneID
            Write-Host "✅ CopyVolume initiated successfully." -ForegroundColor Green
            Write-Host "  Async Handle: $asyncHandle"
            Write-Host "  Clone ID: $cloneID"
        } else {
            Write-Host "❌ CopyVolume operation completed, but no result returned." -ForegroundColor Red
        }
    } catch {
        Write-Host "🚨 Error during CopyVolume: $_" -ForegroundColor Red
    }
}

Copy-SolidFireVolume -IPAddress $IPAddress -Username $Username -Password $Password -SourceVolumeID $SourceVolumeID -DestinationVolumeID $DestinationVolumeID -SnapshotID $SnapshotID

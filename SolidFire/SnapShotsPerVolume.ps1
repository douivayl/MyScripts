<#
.SYNOPSIS
    Retrieves snapshots for specified SolidFire volume IDs.

.DESCRIPTION
    This script connects to a SolidFire cluster using the provided API URL, credentials, and retrieves snapshot details for the specified volume IDs.

.PARAMETER ApiUrl
    The SolidFire API URL (e.g., https://<MVIP>/json-rpc/10.0).

.PARAMETER Username
    The SolidFire username.

.PARAMETER Password
    The SolidFire password (secure string).

.PARAMETER VolumeIDs
    An array of SolidFire volume IDs for which snapshots will be retrieved.

.EXAMPLE
    .\Get-Snapshots.ps1 -ApiUrl "https://10.208.174.40/json-rpc/10.0" -Username "admin" -Password (ConvertTo-SecureString "password" -AsPlainText -Force) -VolumeIDs 92, 25, 26

.NOTES
    This script forces the use of TLS 1.2 and bypasses SSL certificate validation in order to work with my specific host for running the script. You may not need it at all, depending on your Windows host.
#>

param (
    [string]$ApiUrl = (Read-Host "Enter the SolidFire API URL (e.g., https://<MVIP>/json-rpc/10.0)"),
    [string]$Username = (Read-Host "Enter your SolidFire username"),
    [SecureString]$Password = (Read-Host -AsSecureString "Enter your SolidFire password"),
    [int[]]$VolumeIDs = @(Read-Host "Enter the Volume IDs (comma-separated)" -split "," | ForEach-Object { $_.Trim() -as [int] })
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

$SecurePassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
$Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${SecurePassword}"))

$Headers = @{
    "Content-Type"  = "application/json"
    "Authorization" = "Basic $Auth"
}

function Get-SnapshotsForVolume {
    param (
        [int]$VolumeID
    )

    $Body = @{
        method = "ListSnapshots"
        params = @{ volumeID = $VolumeID }
        id = 1
    } | ConvertTo-Json -Depth 10

    try {
        $Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Body $Body -Headers $Headers

        if ($Response.result.snapshots) {
            return $Response.result.snapshots | Select-Object Name, SnapshotID, CreateTime, Status, TotalSize, VolumeID
        } else {
            Write-Host "No snapshots found for volume ID ${VolumeID}" -ForegroundColor Yellow
            return @()
        }
    } catch {
        Write-Host "Error retrieving snapshots for volume ID ${VolumeID}: $_" -ForegroundColor Red
        return @()
    }
}

foreach ($VolumeID in $VolumeIDs) {
    Write-Host "Snapshots for Volume ID: ${VolumeID}" -ForegroundColor Cyan
    $Snapshots = Get-SnapshotsForVolume -VolumeID $VolumeID
    $Snapshots | Format-Table -AutoSize
}

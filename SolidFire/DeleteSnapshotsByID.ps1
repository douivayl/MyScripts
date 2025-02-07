<#
.SYNOPSIS
    Delete SolidFire snapshots by ID.

.DESCRIPTION
    This script deletes SolidFire snapshots using the provided snapshot IDs.
    It supports both command-line parameters and interactive prompts for input.

.PARAMETER Username
    The username for the SolidFire admin.

.PARAMETER Password
    The password for the SolidFire admin.

.PARAMETER SnapshotID
    The IDs of the snapshots to be deleted. Accepts multiple IDs.

.PARAMETER IPAddress
    The mgmt IP address of the SolidFire cluster.

.EXAMPLE
    .\Delete-SolidFireSnapshot.ps1 -Username "yourUsername" -Password "yourPassword" -SnapshotID "snapshotID1","snapshotID2" -IPAddress "yourSolidFireIPAddress"

    Deletes the specified snapshots using the provided credentials and IP address.

.EXAMPLE
    .\Delete-SolidFireSnapshot.ps1

    Prompts for the necessary information and deletes the specified snapshots.

.NOTES
    This script forces the use of TLS 1.2 and bypasses SSL certificate validation in order to work with my specific host for running the script. You may not need it at all, depending on your windows host.
#>

# Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Bypass SSL Certificate Validation (For Testing Only)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

param (
    [string]$Username,
    [string]$Password,
    [string[]]$SnapshotID,
    [string]$IPAddress
)

function Remove-SolidFireSnapshot {
    param (
        [string]$Username,
        [string]$Password,
        [string[]]$SnapshotID,
        [string]$IPAddress
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

    if (-not $SnapshotID) {
        $SnapshotID = @()
        $SnapshotID += Read-Host "Enter the Snapshot ID to delete"
    }

    $apiUrl = "https://$IPAddress/json-rpc/11.0"

    $authInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${Password}"))
    $headers = @{
        "Authorization" = "Basic $authInfo"
        "Content-Type"  = "application/json"
    }

    foreach ($id in $SnapshotID) {
        $body = @{
            "method" = "DeleteSnapshot"
            "params" = @{
                "snapshotID" = $id
            }
            "id" = 1
        } | ConvertTo-Json -Depth 10

        try {
            $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $body -Headers $headers

            if ($response.result) {
                Write-Host "✅ Snapshot ID $id deleted successfully." -ForegroundColor Green
            } else {
                Write-Host "❌ Failed to delete snapshot ID $id." -ForegroundColor Red
            }
        } catch {
            Write-Host "🚨 Error deleting snapshot ID ${id}: $_" -ForegroundColor Red
        }
    }
}

Remove-SolidFireSnapshot -Username $Username -Password $Password -SnapshotID $SnapshotID -IPAddress $IPAddress

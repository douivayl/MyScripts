<#
.SYNOPSIS
    Delete SolidFire group snapshots by ID.

.DESCRIPTION
    This script deletes SolidFire group snapshots using the provided group snapshot IDs.

.PARAMETER Username
    The username for the SolidFire admin.

.PARAMETER Password
    The password for the SolidFire admin.

.PARAMETER GroupSnapshotID
    The IDs of the group snapshots to be deleted. Accepts multiple IDs.

.PARAMETER IPAddress
    The mgmt IP address of the SolidFire cluster.

.EXAMPLE
    .\Delete-SolidFireGroupSnapshot.ps1 -Username "admin" -Password "yourPassword" -GroupSnapshotID "123","456" -IPAddress "10.10.10.1"

.EXAMPLE
    .\Delete-SolidFireGroupSnapshot.ps1

.NOTES
    Uses TLS 1.2 and bypasses SSL validation for testing purposes.
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

param (
    [string]$Username,
    [string]$Password,
    [string[]]$GroupSnapshotID,
    [string]$IPAddress
)

function Remove-SolidFireGroupSnapshot {
    param (
        [string]$Username,
        [string]$Password,
        [string[]]$GroupSnapshotID,
        [string]$IPAddress
    )

    if (-not $Username) {
        $Username = Read-Host "Enter your SolidFire username"
    }
    if (-not $Password) {
        $Password = Read-Host "Enter your SolidFire password" -AsSecureString
        $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
        )
    }
    if (-not $IPAddress) {
        $IPAddress = Read-Host "Enter the SolidFire API IP address"
    }
    if (-not $GroupSnapshotID) {
        $GroupSnapshotID = @()
        $GroupSnapshotID += Read-Host "Enter the Group Snapshot ID to delete"
    }

    $apiUrl = "https://$IPAddress/json-rpc/11.0"

    $authInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${Password}"))
    $headers = @{
        "Authorization" = "Basic $authInfo"
        "Content-Type"  = "application/json"
    }

    foreach ($id in $GroupSnapshotID) {
        $body = @{
            "method" = "DeleteGroupSnapshot"
            "params" = @{
                "groupSnapshotID" = $id
            }
            "id" = 1
        } | ConvertTo-Json -Depth 10

        try {
            $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $body -Headers $headers

            if ($response.result) {
                Write-Host "✅ Group Snapshot ID $id deleted successfully." -ForegroundColor Green
            } else {
                Write-Host "❌ Failed to delete Group Snapshot ID $id." -ForegroundColor Red
            }
        } catch {
            Write-Host "🚨 Error deleting Group Snapshot ID $id: $_" -ForegroundColor Red
        }
    }
}

$GroupSnapshotIDs = Read-Host "Enter Group Snapshot ID(s) to delete (comma-separated)"
$GroupSnapshotList = $GroupSnapshotIDs -split "," | ForEach-Object { $_.Trim() }

foreach ($ID in $GroupSnapshotList) {
    $CleanID = ($ID -replace '\D', '') -as [int]

    if ($CleanID -gt 0) {  
        Remove-SolidFireGroupSnapshot -Username $Username -Password $Password -GroupSnapshotID $CleanID -IPAddress $IPAddress
    } else {
        Write-Host "⚠️ Invalid Group Snapshot ID: $ID" -ForegroundColor Yellow
    }
}

Write-Host "✅ Group snapshot deletion process completed!" -ForegroundColor Cyan

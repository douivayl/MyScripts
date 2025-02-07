<#
.SYNOPSIS
    Retrieve and display SolidFire cluster fullness thresholds.

.DESCRIPTION
    This script retrieves cluster fullness thresholds from a SolidFire cluster,
    displays them in a formatted table, and provides warnings if usage exceeds thresholds.

.PARAMETER IPAddress
    The management IP address of the SolidFire cluster.

.PARAMETER Username
    The username for SolidFire admin.

.PARAMETER Password
    The password for SolidFire admin.

.EXAMPLE
    .\Get-SolidFireClusterThresholds.ps1 -IPAddress "10.10.10.1" -Username "admin" -Password "yourPassword"

    Retrieves and displays cluster fullness thresholds, checking if usage exceeds limits.

.EXAMPLE
    .\Get-SolidFireClusterThresholds.ps1

    Prompts for credentials and IP address, then retrieves cluster thresholds.

.OUTPUTS
    The script will display output similar to this:

    Cluster Fullness Thresholds:
    Block Fullness Stage: stage4Critical
    Metadata Fullness Stage: stage1Happy
    Fullness: stage4Critical
    Stage 2 Block Threshold (Bytes): 68234761994240
    Stage 3 Block Threshold (Bytes): 70769086300160
    Stage 4 Block Threshold (Bytes): 73303410606080
    Stage 5 Block Threshold (Bytes): 84477476864000
    Used Cluster Bytes: 75686584583016

    Warning: Cluster is above Stage 2 Block Threshold!
    Warning: Cluster is above Stage 3 Block Threshold!
    Error: Cluster is above Stage 4 Block Threshold!

.NOTES
    This script forces the use of TLS 1.2 and bypasses SSL certificate validation in order to work with my specific host for running the script.
    You may not need it at all, depending on your Windows host.
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

param (
    [string]$IPAddress,
    [string]$Username,
    [string]$Password
)

function Retrieve-SolidFireClusterThresholds {
    param (
        [string]$IPAddress,
        [string]$Username,
        [string]$Password
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

    $apiUrl = "https://$IPAddress/json-rpc/11.0"
    $authInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${Password}"))
    $headers = @{
        "Authorization" = "Basic $authInfo"
        "Content-Type"  = "application/json"
    }

    $payload = @"
{
    "method": "GetClusterFullThreshold",
    "params": {},
    "id": 1
}
"@

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $payload
        $thresholds = $response.result

        Write-Host "Cluster Fullness Thresholds:" -ForegroundColor Cyan
        Write-Host "--------------------------------------------"
        Write-Host "Block Fullness Stage: $($thresholds.blockFullness)"
        Write-Host "Metadata Fullness Stage: $($thresholds.metadataFullness)"
        Write-Host "Fullness: $($thresholds.fullness)"
        Write-Host "Stage 2 Block Threshold (Bytes): $($thresholds.stage2BlockThresholdBytes)"
        Write-Host "Stage 3 Block Threshold (Bytes): $($thresholds.stage3BlockThresholdBytes)"
        Write-Host "Stage 4 Block Threshold (Bytes): $($thresholds.stage4BlockThresholdBytes)"
        Write-Host "Stage 5 Block Threshold (Bytes): $($thresholds.stage5BlockThresholdBytes)"
        Write-Host "Used Cluster Bytes: $($thresholds.sumUsedClusterBytes)"

        # Check and display warnings if thresholds are exceeded
        $warnings = @()

        if ($thresholds.sumUsedClusterBytes -ge $thresholds.stage2BlockThresholdBytes) {
            $warnings += "Warning: Cluster is above Stage 2 Block Threshold!"
        }
        if ($thresholds.sumUsedClusterBytes -ge $thresholds.stage3BlockThresholdBytes) {
            $warnings += "Warning: Cluster is above Stage 3 Block Threshold!"
        }
        if ($thresholds.sumUsedClusterBytes -ge $thresholds.stage4BlockThresholdBytes) {
            $warnings += "❌ Error: Cluster is above Stage 4 Block Threshold!"
        }
        if ($thresholds.sumUsedClusterBytes -ge $thresholds.stage5BlockThresholdBytes) {
            $warnings += "🚨 Critical: Cluster is above Stage 5 Block Threshold! Immediate action required!"
        }

        if ($warnings.Count -gt 0) {
            $warnings | ForEach-Object { Write-Host $_ -ForegroundColor Red }
        } else {
            Write-Host "✅ Cluster usage is within safe limits." -ForegroundColor Green
        }
    } catch {
        Write-Host "🚨 Error retrieving cluster thresholds: $_" -ForegroundColor Red
    }
}

Retrieve-SolidFireClusterThresholds -IPAddress $IPAddress -Username $Username -Password $Password

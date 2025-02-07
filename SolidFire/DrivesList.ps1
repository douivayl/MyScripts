<#
.SYNOPSIS
    Retrieve and display drives from a SolidFire cluster.

.DESCRIPTION
    This script retrieves all available drives from a SolidFire cluster,
    displays them in a formatted table, and exports the details to a CSV file.

.PARAMETER IPAddress
    The management IP address of the SolidFire cluster.

.PARAMETER Username
    The username for SolidFire admin.

.PARAMETER Password
    The password for SolidFire admin.

.EXAMPLE
    .\Get-SolidFireClusterDrives.ps1 -IPAddress "10.10.10.1" -Username "admin" -Password "yourPassword"

    Retrieves and displays all drives in the cluster, checking drive status.

.EXAMPLE
    .\Get-SolidFireClusterDrives.ps1

    Prompts for credentials and IP address, then retrieves drive details.

.OUTPUTS
    The script will display output similar to this:

    DriveID NodeID Serial        CapacityGB Status   DriveType
    ------- ------ ------------- ---------- -------- ----------
    253     2      ABC123456789   960        Active   SSD
    254     3      XYZ987654321   1920       Active   SSD

    A CSV file is also saved in the current user's Documents directory.

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

function Retrieve-SolidFireClusterDrives {
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
    "method": "ListDrives",
    "params": {},
    "id": 1
}
"@

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $payload
        $drives = $response.result.drives

        if ($drives.Count -eq 0) {
            Write-Host "No drives found in the cluster."
        } else {
            $drivesFormatted = $drives | ForEach-Object {
                [PSCustomObject]@{
                    DriveID   = $_.driveID
                    NodeID    = $_.nodeID
                    Serial    = $_.serial
                    CapacityGB = [math]::Round($_.capacity / 1GB, 2)
                    Status    = $_.status
                    DriveType = $_.type
                }
            }

            $drivesFormatted | Format-Table -AutoSize

            $timestamp = (Get-Date -Format "yyyyMMddHHmm")
            $outputDir = "$env:USERPROFILE\Documents\SolidFireReports"
            $outputPath = Join-Path -Path $outputDir -ChildPath "ClusterDrives_$timestamp.csv"

            $drivesFormatted | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8
            Write-Host "✅ Drive details exported to: $outputPath" -ForegroundColor Green
        }
    } catch {
        Write-Host "🚨 Error retrieving cluster drives: $_" -ForegroundColor Red
    }
}

Retrieve-SolidFireClusterDrives -IPAddress $IPAddress -Username $Username -Password $Password

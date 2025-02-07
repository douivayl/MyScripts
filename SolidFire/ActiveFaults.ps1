<#
.SYNOPSIS
    Retrieve and display active faults from a SolidFire cluster.

.DESCRIPTION
    This script retrieves active faults from a SolidFire cluster,
    displays them in a formatted table, and exports the details to a CSV file.

.PARAMETER IPAddress
    The management IP address of the SolidFire cluster.

.PARAMETER Username
    The username for SolidFire admin.

.PARAMETER Password
    The password for SolidFire admin.

.EXAMPLE
    .\Get-SolidFireClusterFaults.ps1 -IPAddress "10.10.10.1" -Username "admin" -Password "yourPassword"

    Retrieves and displays current cluster faults, and exports the data to CSV.

.EXAMPLE
    .\Get-SolidFireClusterFaults.ps1

    Prompts for credentials and IP address, then retrieves cluster faults.

.OUTPUTS
    The script will display output similar to this:

    FaultID Severity Type      Node DriveID ErrorCode Details        Date  
    ------- -------- ----      ---- ------- --------- -------------- -----------
    101     Critical Hardware  2    17      SF-0001   Drive Failure  2024-01-30

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

function Retrieve-SolidFireClusterFaults {
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
    "method": "ListClusterFaults",
    "params": {
        "faultTypes": "current",
        "bestPractices": false
    },
    "id": 1
}
"@

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $payload
        $faults = $response.result.faults

        if ($faults.Count -eq 0) {
            Write-Host "No active faults found on the cluster."
        } else {
            $faultsFormatted = $faults | ForEach-Object {
                [PSCustomObject]@{
                    FaultID       = $_.clusterFaultID
                    Severity      = $_.severity
                    Type          = $_.type
                    Node          = $_.nodeID
                    DriveID       = $_.driveID
                    ErrorCode     = $_.code
                    Details       = $_.details
                    FaultSpecific = $_.data
                    Date          = Get-Date $_.date -Format "yyyy-MM-dd HH:mm"
                }
            }

            $faultsFormatted | Format-Table -AutoSize

            $timestamp = (Get-Date -Format "yyyyMMddHHmm")
            $outputDir = "$env:USERPROFILE\Documents\SolidFireReports"
            $outputPath = Join-Path -Path $outputDir -ChildPath "ClusterFaults_$timestamp.csv"

            $faultsFormatted | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8
            Write-Host "✅ Fault report exported to: $outputPath" -ForegroundColor Green
        }
    } catch {
        Write-Host "🚨 Error retrieving cluster faults: $_" -ForegroundColor Red
    }
}

Retrieve-SolidFireClusterFaults -IPAddress $IPAddress -Username $Username -Password $Password

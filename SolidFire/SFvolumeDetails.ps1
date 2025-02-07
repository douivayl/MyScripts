<#
.SYNOPSIS
    Retrieve and list SolidFire volumes with usage statistics.

.DESCRIPTION
    This script retrieves volume information and usage statistics from a SolidFire cluster.
    It displays the data in a formatted table and exports it to a CSV file.

.PARAMETER IPAddress
    The management IP address of the SolidFire cluster.

.PARAMETER Username
    The username for SolidFire admin.

.PARAMETER Password
    The password for SolidFire admin.

.EXAMPLE
    .\List-SolidFireVolumeStats.ps1 -IPAddress "10.10.10.1" -Username "admin" -Password "yourPassword"

    Retrieves volume statistics and exports them to a CSV file.

.EXAMPLE
    .\List-SolidFireVolumeStats.ps1

    Prompts for credentials and IP address, then retrieves the volume statistics.

.OUTPUTS
    The script will display output similar to this:

    VolumeID Name     Status   TotalSizeGB  UsedSizeGB  UsedPercentage  CreateTime           Access  
    -------- ----     ------   -----------  ----------  --------------  ----------           ------  
    1234     Vol_1    active   500          250         50 %            2024-01-29 10:30     readWrite
    5678     Vol_2    active   1000         300         30 %            2024-01-29 11:45     readWrite

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

function Retrieve-SolidFireVolumeStats {
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

    $payloadVolumes = @"
{
    "method": "ListVolumes",
    "params": {},
    "id": 1
}
"@

    try {
        $responseVolumes = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $payloadVolumes
        $volumes = $responseVolumes.result.volumes

        if ($volumes.Count -eq 0) {
            Write-Host "No volumes found on the cluster."
        } else {
            $volumeStatsFormatted = @()

            foreach ($volume in $volumes) {
                $volumeID = $volume.volumeID
                $volumeName = $volume.name
                $totalSizeGB = [math]::Round($volume.totalSize / 1GB, 2)

                $payloadStats = @"
{
    "method": "ListVolumeStats",
    "params": { "volumeIDs": [$volumeID] },
    "id": 2
}
"@

                try {
                    $responseStats = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $payloadStats
                    
                    if ($responseStats -and $responseStats.result -and $responseStats.result.volumeStats.Count -gt 0) {
                        $stats = $responseStats.result.volumeStats[0]
                        
                        $usedSizeGB = [math]::Round($stats.nonZeroBlocks * 4096 / 1GB, 2)
                        $usedPercentage = if ($totalSizeGB -gt 0) { [math]::Round(($usedSizeGB / $totalSizeGB) * 100, 2) } else { 0 }

                        $volumeStatsFormatted += [PSCustomObject]@{
                            VolumeID       = $volumeID
                            Name           = $volumeName
                            Status         = $volume.status
                            TotalSizeGB    = $totalSizeGB
                            UsedSizeGB     = $usedSizeGB
                            UsedPercentage = "$usedPercentage %"
                            CreateTime     = Get-Date $volume.createTime -Format "yyyy-MM-dd HH:mm"
                            Access         = $volume.access
                        }
                    } else {
                        Write-Host "No stats available for Volume ID $volumeID" -ForegroundColor Yellow
                    }
                } catch {
                    Write-Host "Error retrieving stats for Volume ID $volumeID: $_" -ForegroundColor Red
                }
            }

            if ($volumeStatsFormatted.Count -gt 0) {
                $volumeStatsFormatted | Format-Table -AutoSize

                $timestamp = (Get-Date -Format "yyyyMMddHHmm")
                $outputDir = "$env:USERPROFILE\Documents\SolidFireVolumes"
                $outputPath = Join-Path -Path $outputDir -ChildPath "VolumeStats_$timestamp.csv"

                $volumeStatsFormatted | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8
                Write-Host "✅ Volume statistics exported to: $outputPath" -ForegroundColor Green
            } else {
                Write-Host "No valid volume statistics retrieved." -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "🚨 Failed to retrieve volume statistics: $_" -ForegroundColor Red
    }
}

Retrieve-SolidFireVolumeStats -IPAddress $IPAddress -Username $Username -Password $Password

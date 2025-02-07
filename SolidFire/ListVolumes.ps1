<#
.SYNOPSIS
    Retrieve and list SolidFire volumes.

.DESCRIPTION
    This script retrieves volume information from a SolidFire cluster
    and displays it in a formatted table. It also exports the data to a CSV.

.PARAMETER IPAddress
    The management IP address of the SolidFire cluster.

.PARAMETER Username
    The username for SolidFire admin.

.PARAMETER Password
    The password for SolidFire admin.

.EXAMPLE
    .\List-SolidFireVolumes.ps1 -IPAddress "10.10.10.1" -Username "admin" -Password "yourPassword"

    Retrieves all volumes and exports them to a CSV.

.EXAMPLE
    .\List-SolidFireVolumes.ps1

    Prompts for credentials and IP address, then retrieves the volume list.

.OUTPUTS
    The script will display output similar to this:

    VolumeID Name     Status   SizeGB  CreateTime          Access  
    -------- ----     ------   ------  ----------          ------  
    1234     Vol_1    active   500     2024-01-29 10:30:00 readWrite
    5678     Vol_2    active   1000    2024-01-29 11:45:00 readWrite

    A CSV file is also saved in the current user's Documents directory.

.NOTES
   This script forces the use of TLS 1.2 and bypasses SSL certificate validation in order to work with my specific host for running the script.
   You may not need it at all, depending on your windows host.
#>


[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

param (
    [string]$IPAddress,
    [string]$Username,
    [string]$Password
)

function Retrieve-SolidFireVolumes {
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

    $body = @{
        "method" = "ListVolumes"
        "params" = @{}
        "id"     = 1
    } | ConvertTo-Json -Depth 10

    try {

        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $body
        $volumes = $response.result.volumes

        if ($volumes.Count -eq 0) {
            Write-Host "No volumes found on the cluster."
        } else {

            $volumesFormatted = $volumes | ForEach-Object {
                [PSCustomObject]@{
                    VolumeID   = $_.volumeID
                    Name       = $_.name
                    Status     = $_.status
                    SizeGB     = [math]::Round($_.totalSize / 1GB, 2)
                    CreateTime = Get-Date $_.createTime -Format "yyyy-MM-dd HH:mm"
                    Access     = $_.access
                }
            }

            $volumesFormatted | Format-Table -AutoSize

            $timestamp = (Get-Date -Format "yyyyMMddHHmm")
            $outputDir = "$env:USERPROFILE\Documents\SolidFireVolumes"
            $outputPath = Join-Path -Path $outputDir -ChildPath "VolumeList_$timestamp.csv"

            $volumesFormatted | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8
            Write-Host "✅ Volume list exported to: $outputPath" -ForegroundColor Green
        }
    } catch {
        Write-Host "🚨 Error retrieving volumes: $_" -ForegroundColor Red
    }
}

Retrieve-SolidFireVolumes -IPAddress $IPAddress -Username $Username -Password $Password

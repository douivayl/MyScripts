<#
.SYNOPSIS
    Retrieve and display SolidFire cluster capacity details.

.DESCRIPTION
    This script retrieves cluster capacity information from a SolidFire cluster.
    It displays the details in a formatted table and exports them to a CSV file.

.PARAMETER IPAddress
    The management IP address of the SolidFire cluster.

.PARAMETER Username
    The username for SolidFire admin.

.PARAMETER Password
    The password for SolidFire admin.

.EXAMPLE
    .\Get-SolidFireClusterCapacity.ps1 -IPAddress "10.10.10.1" -Username "admin" -Password "yourPassword"
    Retrieves and displays cluster capacity, and exports data to CSV.

.EXAMPLE
    .\Get-SolidFireClusterCapacity.ps1
    Prompts for credentials and IP address, then retrieves cluster capacity.

.OUTPUTS
    The script will display output similar to this:

    Total Block Capacity:   70.5 TB
    Used Block Capacity:    45.3 TB
    Free Block Capacity:    25.2 TB
    Metadata Used:          1.2 TB
    Snapshot Reserve Used:  0.8 TB
    Thin Provisioned Space: 100 TB

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

function Retrieve-SolidFireClusterCapacity {
    param (
        [string]$IPAddress,
        [string]$Username,
        [string]$Password
    )

    # Check if IPAddress, Username, and Password are provided as parameters; prompt otherwise
    if (-not $IPAddress) {
        $IPAddress = Read-Host "Enter the SolidFire API IP address"
    }

    if (-not $Username) {
        $Username = Read-Host "Enter your SolidFire username"
    }

    if (-not $Password) {
        $Password = Read-Host "Enter your SolidFire password"
    }

    # Prepare API URL and Authentication Header
    $apiUrl = "https://$IPAddress/json-rpc/11.0"
    $authInfo = "${Username}:${Password}"
    $authBase64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($authInfo))

    # Set the headers
    $headers = @{
        "Authorization" = "Basic $authBase64"
        "Content-Type"  = "application/json"
    }

    $payload = @"
{
    "method": "GetClusterCapacity",
    "params": {},
    "id": 1
}
"@

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $payload
        
        if ($response.result) {
            $clusterCap = $response.result.clusterCapacity

            $ConvertToTB = { param ($bytes) [math]::Round($bytes / 1TB, 2) }

            $TotalTB = &$ConvertToTB $clusterCap.maxUsedSpace
            $UsedTB = &$ConvertToTB $clusterCap.usedSpace
            $FreeTB = &$ConvertToTB ($clusterCap.maxUsedSpace - $clusterCap.usedSpace)
            $MetadataUsedTB = &$ConvertToTB $clusterCap.usedMetadataSpace
            $SnapshotReserveTB = &$ConvertToTB $clusterCap.usedMetadataSpaceInSnapshots
            $ThinProvisionedTB = &$ConvertToTB ($clusterCap.provisionedSpace - $clusterCap.maxUsedSpace)

            Write-Host "SolidFire Cluster Capacity Summary (TB):" -ForegroundColor Cyan
            Write-Host "--------------------------------------------"
            Write-Host "Total Block Capacity:   $TotalTB TB"
            Write-Host "Used Block Capacity:    $UsedTB TB"
            Write-Host "Free Block Capacity:    $FreeTB TB"
            Write-Host "Metadata Used:          $MetadataUsedTB TB"
            Write-Host "Snapshot Reserve Used:  $SnapshotReserveTB TB"
            Write-Host "Thin Provisioned Space: $ThinProvisionedTB TB"

            $capacityData = [PSCustomObject]@{
                TotalCapacityTB      = $TotalTB
                UsedCapacityTB       = $UsedTB
                FreeCapacityTB       = $FreeTB
                MetadataUsedTB       = $MetadataUsedTB
                SnapshotReserveTB    = $SnapshotReserveTB
                ThinProvisionedTB    = $ThinProvisionedTB
            }

            $timestamp = (Get-Date -Format "yyyyMMddHHmm")
            $outputDir = "$env:USERPROFILE\Documents"
            $outputPath = Join-Path -Path $outputDir -ChildPath "ClusterCapacity_$timestamp.csv"

            $capacityData | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8
            Write-Host "✅ Capacity report exported to: $outputPath" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to retrieve cluster capacity." -ForegroundColor Red
        }
    } catch {
        Write-Host "🚨 Error retrieving cluster capacity: $_" -ForegroundColor Red
    }
}

# Call the function to retrieve cluster capacity with the provided credentials
Retrieve-SolidFireClusterCapacity -IPAddress $IPAddress -Username $Username -Password $Password

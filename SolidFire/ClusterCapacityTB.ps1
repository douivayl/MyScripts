# Force PowerShell to Use TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Bypass SSL Certificate Validation (For Testing Only)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# Define API Endpoint & Credentials
$SolidFireAPI = "https://<MVIP>/json-rpc/10.0"  # Replace with the Management Virtual IP
$User = "admin"
$Password = "YourPassword"

# Prepare API Payload
$Payload = @{
    method = "GetClusterCapacity"
    params = @{}
    id = 1
} | ConvertTo-Json -Depth 10

# Call the API
try {
    $Response = Invoke-RestMethod -Uri $SolidFireAPI -Method Post -Body $Payload -ContentType "application/json" `
                -Credential (New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString $Password -AsPlainText -Force)))

    # Extract Capacity Details
    if ($Response.result) {
        $ClusterCap = $Response.result.clusterCapacity

        # Convert bytes to TB (1 TB = 1,099,511,627,776 bytes)
        $ConvertToTB = { param ($bytes) [math]::Round($bytes / 1TB, 2) }

        # Corrected property names
        $TotalTB = &$ConvertToTB $ClusterCap.maxUsedSpace
        $UsedTB = &$ConvertToTB $ClusterCap.usedSpace
        $FreeTB = &$ConvertToTB ($ClusterCap.maxUsedSpace - $ClusterCap.usedSpace)
        $MetadataUsedTB = &$ConvertToTB $ClusterCap.usedMetadataSpace
        $SnapshotReserveTB = &$ConvertToTB $ClusterCap.usedMetadataSpaceInSnapshots
        $ThinProvisionedTB = &$ConvertToTB ($ClusterCap.provisionedSpace - $ClusterCap.maxUsedSpace)

        # Display Results
        Write-Host "SolidFire Cluster Capacity Summary (TB):" -ForegroundColor Cyan
        Write-Host "--------------------------------------------"
        Write-Host "Total Block Capacity:   $TotalTB TB"
        Write-Host "Used Block Capacity:    $UsedTB TB"
        Write-Host "Free Block Capacity:    $FreeTB TB"
        Write-Host "Metadata Used:          $MetadataUsedTB TB"
        Write-Host "Snapshot Reserve Used:  $SnapshotReserveTB TB"
        Write-Host "Thin Provisioned Space: $ThinProvisionedTB TB"
    } else {
        Write-Host "Failed to retrieve cluster capacity." -ForegroundColor Red
    }
} catch {
    Write-Host "Error retrieving cluster capacity: $_" -ForegroundColor Red
}

# Export results to CSV

$CsvFilePath = "C:\SolidFire_Capacity_Report.csv"

$CapacityData = [PSCustomObject]@{
    TotalCapacityTB      = $TotalTB
    UsedCapacityTB       = $UsedTB
    FreeCapacityTB       = $FreeTB
    MetadataUsedTB       = $MetadataUsedTB
    SnapshotReserveTB    = $SnapshotReserveTB
    ThinProvisionedTB    = $ThinProvisionedTB
}

$CapacityData | Export-Csv -Path $CsvFilePath -NoTypeInformation -Encoding UTF8
Write-Host "Capacity report saved to $CsvFilePath" -ForegroundColor Green

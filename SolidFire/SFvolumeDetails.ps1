# Force PowerShell to Use TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Bypass SSL Certificate Validation (For Testing Only)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# Define the SolidFire API endpoint and credentials
$ClusterIP = "10.208.94.40"
$Username = "admin"
$Password = "milcalVDC!"
$ApiUrl = "https://$ClusterIP/json-rpc/10.0"

# Encode credentials for basic authentication
$AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${Password}"))
$Headers = @{
    "Authorization" = "Basic $AuthInfo"
    "Content-Type" = "application/json"
}

# Define JSON payload to get volume list
$PayloadVolumes = @"
{
    "method": "ListVolumes",
    "params": {},
    "id": 1
}
"@

# Make the API call to get volumes
try {
    $ResponseVolumes = Invoke-RestMethod -Uri $ApiUrl -Method Post -Headers $Headers -Body $PayloadVolumes
    $Volumes = $ResponseVolumes.result.volumes

    if ($Volumes.Count -eq 0) {
        Write-Host "No volumes found on the cluster."
    } else {
        # Prepare an array to store volume statistics
        $VolumeStatsFormatted = @()

        foreach ($Volume in $Volumes) {
            $VolumeID = $Volume.volumeID
            $VolumeName = $Volume.name
            $TotalSizeGB = [math]::Round($Volume.totalSize / 1GB, 2)

            # Fetch volume usage stats using ListVolumeStats
            $PayloadStats = @"
            {
                "method": "ListVolumeStats",
                "params": { "volumeIDs": [$VolumeID] },
                "id": 1
            }
            "@

            $ResponseStats = Invoke-RestMethod -Uri $ApiUrl -Method Post -Headers $Headers -Body $PayloadStats
            $Stats = $ResponseStats.result.volumeStats[0]

            # Extract used space in GB
            $UsedSizeGB = [math]::Round($Stats.nonZeroBlocks * 4096 / 1GB, 2)  # 4KB block size
            $UsedPercentage = if ($TotalSizeGB -gt 0) { [math]::Round(($UsedSizeGB / $TotalSizeGB) * 100, 2) } else { 0 }

            # Store the formatted output
            $VolumeStatsFormatted += [PSCustomObject]@{
                VolumeID       = $VolumeID
                Name           = $VolumeName
                Status         = $Volume.status
                TotalSizeGB    = $TotalSizeGB
                UsedSizeGB     = $UsedSizeGB
                UsedPercentage = "$UsedPercentage %"
                CreateTime     = Get-Date $Volume.createTime -Format "yyyy-MM-dd HH:mm:ss"
                Access         = $Volume.access
            }
        }

        # Display in table format
        $VolumeStatsFormatted | Format-Table -AutoSize

        # Save to a CSV file with timestamp
        $Timestamp = (Get-Date -Format "yyyyMMddHHmmss")
        $OutputDir = "$env:USERPROFILE\Documents\SolidFireVolumes"
        if (-not (Test-Path -Path $OutputDir)) {
            New-Item -ItemType Directory -Path $OutputDir
        }
        $OutputPath = Join-Path -Path $OutputDir -ChildPath "VolumeStats_$Timestamp.csv"
        $VolumeStatsFormatted | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        Write-Host "Volume statistics exported to $OutputPath"
    }
} catch {
    Write-Error "Failed to retrieve volume statistics: $_"
}

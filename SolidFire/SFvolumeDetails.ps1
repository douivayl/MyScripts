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

# Define the JSON payload for the API call
$Payload = @"
{
    "method": "ListVolumes",
    "params": {},
    "id": 1
}
"@

# Make the API call
try {
    $Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Headers $Headers -Body $Payload
    $Volumes = $Response.result.volumes

    # Display the volumes
    if ($Volumes.Count -eq 0) {
        Write-Host "No volumes found on the cluster."
    } else {
        # Format output for display and CSV
        $VolumesFormatted = $Volumes | ForEach-Object {
            $TotalSizeGB = [math]::Round($_.totalSize / 1GB, 2)
            $UsedSizeGB = [math]::Round($_.usedSpace / 1GB, 2)
            $UsedPercentage = if ($TotalSizeGB -gt 0) { [math]::Round(($UsedSizeGB / $TotalSizeGB) * 100, 2) } else { 0 }

            [PSCustomObject]@{
                VolumeID       = $_.volumeID
                Name           = $_.name
                Status         = $_.status
                TotalSizeGB    = $TotalSizeGB
                UsedSizeGB     = $UsedSizeGB
                UsedPercentage = "$UsedPercentage %"
                CreateTime     = Get-Date $_.createTime -Format "yyyy-MM-dd HH:mm:ss"
                Access         = $_.access
            }
        }

        # Display in table format
        $VolumesFormatted | Format-Table -AutoSize

        # Save to a CSV file with timestamp
        $Timestamp = (Get-Date -Format "yyyyMMddHHmmss")
        $OutputDir = "$env:USERPROFILE\Documents\SolidFireVolumes"
        if (-not (Test-Path -Path $OutputDir)) {
            New-Item -ItemType Directory -Path $OutputDir
        }
        $OutputPath = Join-Path -Path $OutputDir -ChildPath "VolumeList_$Timestamp.csv"
        $VolumesFormatted | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        Write-Host "Volume list exported to $OutputPath"
    }
} catch {
    Write-Error "Failed to retrieve volumes: $_"
}

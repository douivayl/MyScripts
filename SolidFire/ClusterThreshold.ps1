# Force TLS 1.2 and bypass SSL validation
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# SolidFire cluster API details
$ClusterIP = "10.208.94.40"
$Username = "admin"
$Password = "milcalVDC!"
$ApiUrl = "https://$ClusterIP/json-rpc/10.0"

# Authentication headers
$AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${Password}"))
$Headers = @{
    "Authorization" = "Basic $AuthInfo"
    "Content-Type" = "application/json"
}

# JSON payload for the GetClusterFullThreshold method
$Payload = @{
    method = "GetClusterFullThreshold"
    params = @{}
    id = 1
} | ConvertTo-Json -Depth 10 -Compress

# Make the API call
try {
    $Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Headers $Headers -Body $Payload
    $Thresholds = $Response.result

    # Display thresholds and check against current values
    Write-Host "Cluster Fullness Thresholds:" -ForegroundColor Cyan
    Write-Host "Block Fullness Stage: $($Thresholds.blockFullness)"
    Write-Host "Metadata Fullness Stage: $($Thresholds.metadataFullness)"
    Write-Host "Fullness: $($Thresholds.fullness)"
    Write-Host "Stage 2 Block Threshold (Bytes): $($Thresholds.stage2BlockThresholdBytes)"
    Write-Host "Stage 3 Block Threshold (Bytes): $($Thresholds.stage3BlockThresholdBytes)"
    Write-Host "Stage 4 Block Threshold (Bytes): $($Thresholds.stage4BlockThresholdBytes)"
    Write-Host "Stage 5 Block Threshold (Bytes): $($Thresholds.stage5BlockThresholdBytes)"
    Write-Host "Used Cluster Bytes: $($Thresholds.sumUsedClusterBytes)"

    # Check if thresholds are exceeded
    if ($Thresholds.sumUsedClusterBytes -ge $Thresholds.stage2BlockThresholdBytes) {
        Write-Host "Warning: Cluster is above Stage 2 Block Threshold!" -ForegroundColor Yellow
    }
    if ($Thresholds.sumUsedClusterBytes -ge $Thresholds.stage3BlockThresholdBytes) {
        Write-Host "Warning: Cluster is above Stage 3 Block Threshold!" -ForegroundColor Yellow
    }
    if ($Thresholds.sumUsedClusterBytes -ge $Thresholds.stage4BlockThresholdBytes) {
        Write-Host "Error: Cluster is above Stage 4 Block Threshold!" -ForegroundColor Red
    }
    if ($Thresholds.sumUsedClusterBytes -ge $Thresholds.stage5BlockThresholdBytes) {
        Write-Host "Critical: Cluster is above Stage 5 Block Threshold! Immediate action required!" -ForegroundColor Red
    }
} catch {
    Write-Error "Failed to retrieve cluster thresholds: $_"
}
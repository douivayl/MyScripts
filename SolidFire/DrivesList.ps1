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
$Payload = @{
    method = "ListDrives"
    params = @{}
    id = 1
} | ConvertTo-Json -Depth 10 -Compress

# Make the API call
try {
    $Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Headers $Headers -Body $Payload
    $Drives = $Response.result.drives

    # Display the drives with relevant details
    if ($Drives.Count -eq 0) {
        Write-Host "No drives found in the cluster."
    } else {
        $Drives | ForEach-Object {
            [PSCustomObject]@{
                DriveID   = $_.driveID
                NodeID    = $_.nodeID
                Serial    = $_.serial
                Capacity  = [math]::Round($_.capacity / 1GB, 2) # Convert bytes to GB
                Status    = $_.status
                DriveType = $_.type
            }
        } | Format-Table -AutoSize

        # Optionally, export to a CSV file
        $Timestamp = (Get-Date -Format "yyyyMMddHHmmss")
        $OutputPath = "$env:USERPROFILE\Documents\ClusterDrives_$Timestamp.csv"
        $Drives | ForEach-Object {
            [PSCustomObject]@{
                DriveID   = $_.driveID
                NodeID    = $_.nodeID
                Serial    = $_.serial
                Capacity  = [math]::Round($_.capacity / 1GB, 2) # Convert bytes to GB
                Status    = $_.status
                DriveType = $_.type
            }
        } | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        Write-Host "Drive details exported to $OutputPath"
    }
} catch {
    Write-Error "Failed to retrieve cluster drives: $_"
}
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
    method = "ListClusterFaults"
    params = @{
        faultTypes = "current"
        bestPractices = $false
    }
    id = 1
} | ConvertTo-Json -Depth 10 -Compress

try {
    # Make the API call
    $Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Headers $Headers -Body $Payload
    $Faults = $Response.result.faults

    # Filter out "bestPractice" severity faults
    $FilteredFaults = $Faults | Where-Object { $_.severity -ne "bestPractice" }

    # Display the faults
    if ($FilteredFaults.Count -eq 0) {
        Write-Host "No active alerts found on the cluster."
    } else {
        $FilteredFaults | ForEach-Object {
            [PSCustomObject]@{
                FaultID   = $_.clusterFaultID
                Severity  = $_.severity
                Type      = $_.type
                Node      = $_.nodeID
                DriveID   = $_.driveID
                ErrorCode = $_.code
                Details   = $_.details
                Date      = $_.date
            }
        } | Format-Table -AutoSize

        # Optionally, export to a CSV file
        $Timestamp = (Get-Date -Format "yyyyMMddHHmmss")
        $OutputDir = "$env:USERPROFILE\Documents\SolidFireClusterFaults"
        if (-not (Test-Path -Path $OutputDir)) {
            New-Item -ItemType Directory -Path $OutputDir
        }
        $OutputPath = Join-Path -Path $OutputDir -ChildPath "CurrentFaults_$Timestamp.csv"
        $FilteredFaults | ForEach-Object {
            [PSCustomObject]@{
                FaultID   = $_.clusterFaultID
                Severity  = $_.severity
                Type      = $_.type
                Node      = $_.nodeID
                DriveID   = $_.driveID
                ErrorCode = $_.code
                Details   = $_.details
                Date      = $_.date
            }
        } | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        Write-Host "Current alerts exported to $OutputPath"
    }
} catch {
    Write-Error "Failed to retrieve cluster faults: $_"
}
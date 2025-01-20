# Force PowerShell to Use TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Bypass SSL Certificate Validation (For Testing Only)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# Define the API endpoint and credentials
$SolidFireAPI = "https://10.208.94.40/json-rpc/10.0"
$User = "admin"
$Password = "milcalVDC!"

# Prepare the request payload for GetClusterHardwareInfo
$Payload = @{
    method = "GetClusterHardwareInfo"
    params = @{ }
    id = 1
} | ConvertTo-Json -Depth 10

# Make the API request
try {
    Write-Host "Retrieving cluster hardware information..." -ForegroundColor Yellow

    $Response = Invoke-RestMethod -Uri $SolidFireAPI -Method Post -Body $Payload -ContentType "application/json" -Credential (New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString $Password -AsPlainText -Force)))

    # Handle the response
    if ($Response.result) {
        Write-Host "Cluster Hardware Information:" -ForegroundColor Green
        foreach ($NodeID in $Response.result.nodes.Keys) {
            $Node = $Response.result.nodes[$NodeID]
            Write-Host "Node ID: $NodeID" -ForegroundColor Cyan
            Write-Host "  Chassis Serial: $($Node.chassisSerial)"
            Write-Host "  Node Serial: $($Node.nodeSerial)"
            Write-Host "  Drives:"
            foreach ($Drive in $Node.drives) {
                Write-Host "    Drive Serial: $($Drive.serial)" -ForegroundColor Gray
            }
            Write-Host "-----------------------------------"
        }
    } else {
        Write-Host "Request completed, but no result returned." -ForegroundColor Red
    }
} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}

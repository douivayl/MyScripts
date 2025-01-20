# Force PowerShell to Use TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Bypass SSL Certificate Validation (For Testing Only)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# Define the API endpoint and credentials
$SolidFireAPI = "https://10.208.94.40/json-rpc/10.0"
$User = "admin"
$Password = "milcalVDC!"

# Prepare the request payload for ListActiveNodes
$Payload = @{
    method = "ListActiveNodes"
    params = @{}
    id = 1
} | ConvertTo-Json -Depth 10

# Make the API request
try {
    Write-Host "Retrieving active nodes..." -ForegroundColor Yellow

    $Response = Invoke-RestMethod -Uri $SolidFireAPI -Method Post -Body $Payload -ContentType "application/json" -Credential (New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString $Password -AsPlainText -Force)))

    # Handle the response
    if ($Response.result) {
        Write-Host "Active Nodes:" -ForegroundColor Green
        foreach ($Node in $Response.result.nodes) {
            Write-Host "Node ID: $($Node.nodeID)" -ForegroundColor Cyan
            Write-Host "  Management IP (mip): $($Node.mip)"
            Write-Host "  Cluster IP (cip): $($Node.cip)"
            Write-Host "  Storage IP (sip): $($Node.sip)"
            Write-Host "-----------------------------------"
        }
    } else {
        Write-Host "Request completed, but no result returned." -ForegroundColor Red
    }
} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}

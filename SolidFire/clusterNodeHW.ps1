# Force PowerShell to Use TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Bypass SSL Certificate Validation (For Testing Only)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# Define the API endpoint and credentials
$SolidFireAPI = "https://10.208.94.40/json-rpc/10.0"  # Replace with your cluster's endpoint
$User = "admin"  # Replace with your username
$Password = "milcalVDC!"  # Replace with your password

# Prepare the request payload for GetHardwareInfo
$Payload = @{
    method = "GetHardwareInfo"
    params = @{
        force = $true  # Set to true to retrieve info for all nodes
    }
    id = 1
} | ConvertTo-Json -Depth 10

# Make the API request
try {
    Write-Host "Retrieving hardware information for all nodes..." -ForegroundColor Yellow

    $Response = Invoke-RestMethod -Uri $SolidFireAPI -Method Post -Body $Payload -ContentType "application/json" -Credential (New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString $Password -AsPlainText -Force)))

    # Output the entire JSON response directly to the console
    Write-Host "Raw JSON Response:" -ForegroundColor Green
    $Response | ConvertTo-Json -Depth 10 | Write-Output
} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}

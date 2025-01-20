# Force PowerShell to Use TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Bypass SSL Certificate Validation (For Testing Only)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# Define the API endpoint and credentials
$SolidFireAPI = "https://10.208.94.40/json-rpc/10.0"
$User = "admin"
$Password = "milcalVDC!"

# Specify the account ID
$AccountID = <AccountID>  # Replace with the account ID you want to query

# Prepare the request payload
$Payload = @{
    method = "ListVolumesForAccount"
    params = @{
        accountID = $AccountID
    }
    id = 1
} | ConvertTo-Json -Depth 10

# Make the API request
try {
    Write-Host "Retrieving volumes for account ID $AccountID " -ForegroundColor Yellow

    $Response = Invoke-RestMethod -Uri $SolidFireAPI -Method Post -Body $Payload -ContentType "application/json" -Credential (New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString $Password -AsPlainText -Force)))

    # Handle the response
    if ($Response.result.volumes) {
        Write-Host "Volumes for account ID $AccountID:" -ForegroundColor Green
        foreach ($Volume in $Response.result.volumes) {
            Write-Host "  Volume ID: $($Volume.volumeID)"
            Write-Host "  Name: $($Volume.name)"
            Write-Host "  Size: $([math]::Round($Volume.totalSize / 1GB, 2)) GB"
            Write-Host "  Status: $($Volume.status)"
            Write-Host "  IQN: $($Volume.iqn)"
            Write-Host "--------------------------------------"
        }
    } else {
        Write-Host "No volumes found for account ID $AccountID." -ForegroundColor Red
    }
} catch {
    Write-Host "An error occurred while retrieving volumes: $_" -ForegroundColor Red
}
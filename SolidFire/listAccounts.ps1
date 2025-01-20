# Force PowerShell to Use TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Bypass SSL Certificate Validation (For Testing Only)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# Define the API endpoint and credentials
$SolidFireAPI = "https://10.208.94.40/json-rpc/10.0"
$User = "admin"
$Password = "milcalVDC!"

# Prepare the request payload
$Payload = @{
    method = "ListAccounts"
    params = @{}
    id = 1
} | ConvertTo-Json -Depth 10

# Make the API request
$Response = Invoke-RestMethod -Uri $SolidFireAPI -Method Post -Body $Payload -ContentType "application/json" -Credential (New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString $Password -AsPlainText -Force)))

# Display account information
$Response.result.accounts | ForEach-Object { Write-Host "Account ID: $($_.accountID), Username: $($_.username)" }

# Force PowerShell to Use TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Bypass SSL Certificate Validation (For Testing Only)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }


# Prompt user for drive IDs
$DriveIDs = Read-Host "Enter the drive IDs to remove (comma-separated)" |
    ForEach-Object { $_ -split ',' | ForEach-Object { [int]($_.Trim()) } }

# Validate user input
if (-not $DriveIDs -or $DriveIDs.Count -eq 0) {
    Write-Host "No valid drive IDs entered. Exiting." -ForegroundColor Red
    exit 1
}

# Define the API endpoint and credentials
$SolidFireAPI = "https://10.208.94.40/json-rpc/10.0"
$User = "admin"
$Password = "milcalVDC!"

# Prepare the request payload
$Payload = @{
    method = "RemoveDrives"
    params = @{
        drives = $DriveIDs
    }
    id = 1
} | ConvertTo-Json -Depth 10

# Make the API request
try {
    Write-Host "Sending request to remove drives: $($DriveIDs -join ', ')" -ForegroundColor Yellow

    $Response = Invoke-RestMethod -Uri $SolidFireAPI -Method Post -Body $Payload -ContentType "application/json" -Credential (New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString $Password -AsPlainText -Force)))

    # Handle the response
    if ($Response.result) {
        Write-Host "Request successful. Async Handle: $($Response.result.asyncHandle)" -ForegroundColor Green
    } else {
        Write-Host "Request completed, but no result returned." -ForegroundColor Red
    }
} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red

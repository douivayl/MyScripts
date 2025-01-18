# Force PowerShell to Use TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Bypass SSL Certificate Validation (For Testing Only)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# Prompt user for a single drive ID
$DriveID = Read-Host "Enter the drive ID to remove"

# Validate user input
if (-not $DriveID -or $DriveID -notmatch '^\d+$') {
    Write-Host "Invalid drive ID entered. Exiting." -ForegroundColor Red
    exit 1
}

# Convert input to an integer array (even for a single value)
$DriveIDs = @([int]$DriveID)

# Define the API endpoint and credentials
$SolidFireAPI = "https://10.208.94.40/json-rpc/10.0"
$User = "admin"
$Password = "milcalVDC!"

# Prepare the request payload
$Payload = @(
    @{
        method = "RemoveDrives"
        params = @{
            drives = $DriveIDs # Ensure this is always an array
        }
        id = 1
    }
) | ConvertTo-Json -Depth 10

# Debug: Output the payload to confirm its structure
Write-Host "Payload: $($Payload | ConvertTo-Json -Depth 10)" -ForegroundColor Cyan

# Make the API request
try {
    Write-Host "Sending request to remove drive ID: $DriveID" -ForegroundColor Yellow

    $Response = Invoke-RestMethod -Uri $SolidFireAPI -Method Post -Body $Payload -ContentType "application/json" -Credential (New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString $Password -AsPlainText -Force)))

    # Handle the response
    if ($Response.result) {
        Write-Host "Request successful. Async Handle: $($Response.result.asyncHandle)" -ForegroundColor Green
    } else {
        Write-Host "Request completed, but no result returned." -ForegroundColor Red
    }
} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}

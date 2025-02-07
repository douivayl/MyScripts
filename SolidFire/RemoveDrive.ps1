<#
.SYNOPSIS
    Removes a SolidFire drive by its ID.

.DESCRIPTION
    This script removes a specified SolidFire drive using the API. The script prompts for the drive ID, validates the input, and sends the removal request.

.PARAMETER DriveID
    The ID of the drive to be removed.

.PARAMETER Username
    The username for SolidFire admin.

.PARAMETER Password
    The password for SolidFire admin.

.NOTES
    This script forces the use of TLS 1.2 and bypasses SSL certificate validation in order to work with my specific host for running the script. You may not need it at all, depending on your Windows host.

.EXAMPLE
    PS> .\Remove-SolidFireDrive.ps1
    Enter the drive ID to remove: 123
    Sends a request to remove the specified drive.
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# Prompt user for drive ID
$DriveID = Read-Host "Enter the drive ID to remove"

# Validate input
if (-not $DriveID -or $DriveID -notmatch '^\d+$') {
    Write-Host "Invalid drive ID entered. Exiting." -ForegroundColor Red
    exit 1
}

$DriveIDs = @([int]$DriveID)

# API credentials and endpoint
$ClusterIP = Read-Host "Enter the SolidFire cluster IP address"
$Username = Read-Host "Enter the SolidFire username"
$Password = Read-Host "Enter the SolidFire password"
$ApiUrl = "https://$ClusterIP/json-rpc/10.0"

# Authentication header
$AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${Password}"))
$Headers = @{
    "Authorization" = "Basic $AuthInfo"
    "Content-Type"  = "application/json"
}

# Prepare API payload
$Payload = @{
    method = "RemoveDrives"
    params = @{ drives = $DriveIDs }
    id     = 1
} | ConvertTo-Json -Depth 10

try {
    Write-Host "Sending request to remove drive ID: $DriveID" -ForegroundColor Yellow

    $Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Body $Payload -Headers $Headers

    if ($Response.result) {
        Write-Host "Request successful. Async Handle: $($Response.result.asyncHandle)" -ForegroundColor Green
    } else {
        Write-Host "Request completed, but no result returned." -ForegroundColor Red
    }
} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}

<#
.SYNOPSIS
    Add drives to a SolidFire cluster.

.DESCRIPTION
    This script adds one or more drives to a SolidFire cluster.
    The drive IDs must be specified either as parameters or interactively.

.PARAMETER IPAddress
    The management IP address of the SolidFire cluster.

.PARAMETER Username
    The username for SolidFire admin.

.PARAMETER Password
    The password for SolidFire admin.

.PARAMETER DriveIDs
    An array of drive IDs to be added to the cluster.

.EXAMPLE
    .\Add-SolidFireDrives.ps1 -IPAddress "10.10.10.1" -Username "admin" -Password "yourPassword" -DriveIDs 253, 254

    Adds drives with IDs 253 and 254 to the cluster.

.EXAMPLE
    .\Add-SolidFireDrives.ps1

    Prompts for credentials, IP address, and drive IDs, then adds them to the cluster.

.OUTPUTS
    The script will display the API response confirming the drives were added.

.NOTES
    This script forces the use of TLS 1.2 and bypasses SSL certificate validation in order to work with my specific host for running the script.
    You may not need it at all, depending on your Windows host.
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

param (
    [string]$IPAddress,
    [string]$Username,
    [string]$Password,
    [int[]]$DriveIDs
)

function Add-SolidFireDrives {
    param (
        [string]$IPAddress,
        [string]$Username,
        [string]$Password,
        [int[]]$DriveIDs
    )

    if (-not $IPAddress) {
        $IPAddress = Read-Host "Enter the SolidFire API IP address"
    }
    if (-not $Username) {
        $Username = Read-Host "Enter your SolidFire username"
    }
    if (-not $Password) {
        $Password = Read-Host "Enter your SolidFire password" -AsSecureString
        $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
        )
    }
    if (-not $DriveIDs) {
        $DriveInput = Read-Host "Enter the Drive IDs to add (comma-separated)"
        $DriveIDs = $DriveInput -split "," | ForEach-Object { $_.Trim() -as [int] }
    }

    $apiUrl = "https://$IPAddress/json-rpc/11.0"
    $authInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${Password}"))
    $headers = @{
        "Authorization" = "Basic $authInfo"
        "Content-Type"  = "application/json"
    }

    $drivesToAdd = $DriveIDs | ForEach-Object { @{ driveID = $_ } }

    $payload = @{
        "method" = "AddDrives"
        "params" = @{
            "drives" = $drivesToAdd
        }
        "id" = 1
    } | ConvertTo-Json -Depth 10 -Compress

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $payload
        Write-Host "✅ API Response:" -ForegroundColor Cyan
        $response | ConvertTo-Json -Depth 10
    } catch {
        Write-Host "🚨 Error adding drives: $_" -ForegroundColor Red
    }
}

Add-SolidFireDrives -IPAddress $IPAddress -Username $Username -Password $Password -DriveIDs $DriveIDs

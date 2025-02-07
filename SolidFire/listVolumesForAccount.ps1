<#
.SYNOPSIS
    Retrieves SolidFire volumes associated with a specific account ID.

.DESCRIPTION
    This script connects to a SolidFire cluster using the provided API credentials and retrieves all volumes associated with a specified account ID.

.PARAMETER ClusterIP
    The IP address of the SolidFire cluster.

.PARAMETER Username
    The username for SolidFire admin.

.PARAMETER Password
    The password for SolidFire admin.

.PARAMETER AccountID
    The account ID for which volumes need to be retrieved.

.EXAMPLE
    .\ListVolumesForAccount.ps1 -ClusterIP "192.168.1.100" -Username "admin" -Password "password" -AccountID 123

.NOTES
    This script forces the use of TLS 1.2 and bypasses SSL certificate validation to work with the specific host. This may not be required depending on your Windows host.
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

param (
    [string]$ClusterIP,
    [string]$Username,
    [SecureString]$Password,
    [int]$AccountID
)

if (-not $ClusterIP) { $ClusterIP = Read-Host "Enter the SolidFire cluster IP" }
if (-not $Username) { $Username = Read-Host "Enter your SolidFire username" }
if (-not $Password) { $Password = Read-Host "Enter your SolidFire password" -AsSecureString }
if (-not $AccountID) { $AccountID = Read-Host "Enter the Account ID" }

$ApiUrl = "https://$ClusterIP/json-rpc/10.0"
$SecurePassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
$AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${SecurePassword}"))
$Headers = @{
    "Authorization" = "Basic $AuthInfo"
    "Content-Type"  = "application/json"
}

$Payload = @{
    method = "ListVolumesForAccount"
    params = @{ accountID = $AccountID }
    id     = 1
} | ConvertTo-Json -Depth 10

try {
    Write-Host "Retrieving volumes for account ID $AccountID..." -ForegroundColor Yellow

    $Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Body $Payload -Headers $Headers

    if ($Response.result.volumes) {
        Write-Host "Volumes for account ID ${AccountID}:" -ForegroundColor Green
        foreach ($Volume in $Response.result.volumes) {
            [PSCustomObject]@{
                VolumeID = $Volume.volumeID
                Name     = $Volume.name
                SizeGB   = [math]::Round($Volume.totalSize / 1GB, 2)
                Status   = $Volume.status
                IQN      = $Volume.iqn
            } | Format-Table -AutoSize
        }
    } else {
        Write-Host "No volumes found for account ID $AccountID." -ForegroundColor Red
    }
} catch {
    Write-Host "An error occurred while retrieving volumes: $_" -ForegroundColor Red
}

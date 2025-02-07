<#
.SYNOPSIS
    Retrieves the status of an asynchronous operation from a SolidFire cluster.

.DESCRIPTION
    This script queries a SolidFire cluster to get the status of an asynchronous operation
    using the provided asyncHandle. It supports secure API calls and handles response errors gracefully.

.PARAMETER IPAddress
    The management IP address of the SolidFire cluster.

.PARAMETER Username
    The username for SolidFire admin.

.PARAMETER Password
    The password for SolidFire admin.

.PARAMETER AsyncHandle
    The handle identifying the asynchronous operation.

.EXAMPLE
    .\Get-SolidFireAsyncResult.ps1 -IPAddress "192.168.0.1" -Username "admin" -Password "password" -AsyncHandle 107

.NOTES
    This script forces the use of TLS 1.2 and bypasses SSL certificate validation to work with specific hosts.
    You may not need these settings depending on your Windows host.
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

param (
    [string]$IPAddress,
    [string]$Username,
    [SecureString]$Password,
    [int]$AsyncHandle
)

if (-not $IPAddress) { $IPAddress = Read-Host "Enter the SolidFire API IP address" }
if (-not $Username) { $Username = Read-Host "Enter your SolidFire username" }
if (-not $Password) { $Password = Read-Host -AsSecureString "Enter your SolidFire password" }
if (-not $AsyncHandle) { $AsyncHandle = Read-Host "Enter the asyncHandle for the operation" -AsInt }

$ApiUrl = "https://$IPAddress/json-rpc/10.0"
$AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)))}"))
$Headers = @{
    "Authorization" = "Basic $AuthInfo"
    "Content-Type" = "application/json"
}

$Payload = @{
    method = "GetAsyncResult"
    params = @{ asyncHandle = $AsyncHandle }
    id = 1
} | ConvertTo-Json -Depth 10 -Compress

try {
    $Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Headers $Headers -Body $Payload
    $Status = $Response.result.status

    Write-Host "Async operation status: $Status"

    switch ($Status) {
        "complete" {
            if ($Response.result.error) {
                Write-Host "The operation completed with errors:" -ForegroundColor Red
                Write-Host "Error Name: $($Response.result.error.name)"
                Write-Host "Error Message: $($Response.result.error.message)"
            } else {
                Write-Host "The operation completed successfully with the following result:" -ForegroundColor Green
                $Response.result.result | Format-List
            }
        }
        "running" {
            Write-Host "The operation is still running. Check again later." -ForegroundColor Yellow
        }
        default {
            Write-Host "The operation status is unknown or unexpected. Details:" -ForegroundColor Red
            $Response.result | Format-List
        }
    }

} catch {
    Write-Error "Failed to retrieve async result: $_"
}

<#
.SYNOPSIS
    Retrieves active nodes from a SolidFire cluster.

.DESCRIPTION
    This script connects to a SolidFire cluster API to retrieve information about active nodes, including their Management IP, Cluster IP, and Storage IP addresses.

.PARAMETER ClusterIP
    The management IP address of the SolidFire cluster.

.PARAMETER Username
    The username for SolidFire admin.

.PARAMETER Password
    The password for SolidFire admin.

.EXAMPLE
    .\ListActiveNodes.ps1 -ClusterIP "192.168.1.1" -Username "admin" -Password "password"

.NOTES
    This script forces the use of TLS 1.2 and bypasses SSL certificate validation in order to work with my specific host for running the script. You may not need it at all, depending on your Windows host.
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

param (
    [string]$ClusterIP,
    [string]$Username,
    [SecureString]$Password
)

if (-not $ClusterIP) {
    $ClusterIP = Read-Host "Enter the SolidFire Cluster IP"
}
if (-not $Username) {
    $Username = Read-Host "Enter your SolidFire username"
}
if (-not $Password) {
    $Password = Read-Host "Enter your SolidFire password" -AsSecureString
}

$ApiUrl = "https://$ClusterIP/json-rpc/10.0"
$SecurePassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
$AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${SecurePassword}"))
$Headers = @{
    "Authorization" = "Basic $AuthInfo"
    "Content-Type" = "application/json"
}

$Payload = @{
    method = "ListActiveNodes"
    params = @{}
    id = 1
} | ConvertTo-Json -Depth 10

try {
    Write-Host "Retrieving active nodes..." -ForegroundColor Yellow

    $Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Headers $Headers -Body $Payload

    if ($Response.result) {
        Write-Host "Active Nodes:" -ForegroundColor Green
        $Response.result.nodes | ForEach-Object {
            [PSCustomObject]@{
                NodeID       = $_.nodeID
                ManagementIP = $_.mip
                ClusterIP    = $_.cip
                StorageIP    = $_.sip
            }
        } | Format-Table -AutoSize
    } else {
        Write-Host "Request completed, but no result returned." -ForegroundColor Red
    }
} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}

<#
.SYNOPSIS
    Retrieve hardware information for all nodes in a SolidFire cluster.

.DESCRIPTION
    This script retrieves detailed hardware information for all nodes in a SolidFire cluster.
    The response is formatted as JSON and displayed in the console.

.PARAMETER IPAddress
    The management IP address of the SolidFire cluster.

.PARAMETER Username
    The username for SolidFire admin.

.PARAMETER Password
    The password for SolidFire admin.

.EXAMPLE
    .\Get-SolidFireHardwareInfo.ps1 -IPAddress "10.10.10.1" -Username "admin" -Password "yourPassword"

    Retrieves and displays hardware information for all nodes.

.EXAMPLE
    .\Get-SolidFireHardwareInfo.ps1

    Prompts for credentials and IP address, then retrieves the hardware information.

.OUTPUTS
    The script will display output similar to this:

    Retrieving hardware information for all nodes...
    {
        "result": {
            "nodes": [
                {
                    "nodeID": 1,
                    "chassisType": "SF9605",
                    "serial": "ABC12345",
                    "cpu": "Intel Xeon E5",
                    "memoryGB": 256
                }
            ]
        }
    }

.NOTES
    This script forces the use of TLS 1.2 and bypasses SSL certificate validation in order to work with my specific host for running the script.
    You may not need it at all, depending on your Windows host.
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

param (
    [string]$IPAddress,
    [string]$Username,
    [string]$Password
)

function Retrieve-SolidFireHardwareInfo {
    param (
        [string]$IPAddress,
        [string]$Username,
        [string]$Password
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

    $apiUrl = "https://$IPAddress/json-rpc/11.0"
    $authInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${Password}"))
    $headers = @{
        "Authorization" = "Basic $authInfo"
        "Content-Type"  = "application/json"
    }

    $payload = @"
{
    "method": "GetHardwareInfo",
    "params": {
        "force": true
    },
    "id": 1
}
"@

    try {
        Write-Host "Retrieving hardware information for all nodes..." -ForegroundColor Yellow
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $payload

        Write-Host "✅ Hardware Information:" -ForegroundColor Cyan
        $response | ConvertTo-Json -Depth 10 | Write-Output
    } catch {
        Write-Host "🚨 Error retrieving hardware information: $_" -ForegroundColor Red
    }
}

Retrieve-SolidFireHardwareInfo -IPAddress $IPAddress -Username $Username -Password $Password

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

Node ID: 4
Serial Number: XXXXX
Model: XXXXXX
------------------------------------
Node ID: 2
Serial Number: XXXXX
Model: XXXXXX
------------------------------------

.NOTES
    This script forces the use of TLS 1.2 and bypasses SSL certificate validation in order to work with my specific host for running the script.
    You may not need it at all, depending on your Windows host.
#>

param (
    [string]$IPAddress,
    [string]$Username,
    [string]$Password
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

function Retrieve-SolidFireNodeInfo {
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
        $Password = Read-Host "Enter your SolidFire password"
    }

    $apiUrl = "https://$IPAddress/json-rpc/11.0"
   

    $authInfo = "${Username}:${Password}"
    $authBase64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($authInfo))


    $headers = @{
        "Authorization" = "Basic $authBase64"
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

        foreach ($node in $response.result.nodes) {
            $nodeID = $node.nodeID
            $serialNumber = $node.result.hardwareInfo.serial
            $model = $node.result.hardwareInfo.platform.nodeType

            Write-Host "Node ID: $nodeID"
            Write-Host "Serial Number: $serialNumber"
            Write-Host "Model: $model"
            Write-Host "------------------------------------"
        }

    } catch {
        Write-Host "🚨 Error retrieving hardware information: $_" -ForegroundColor Red
    }
}

if (-not $IPAddress -or -not $Username -or -not $Password) {
    Write-Host "One or more parameters are missing. Please provide values manually."
    Retrieve-SolidFireNodeInfo -IPAddress $IPAddress -Username $Username -Password $Password
} else {
    Retrieve-SolidFireNodeInfo -IPAddress $IPAddress -Username $Username -Password $Password
}
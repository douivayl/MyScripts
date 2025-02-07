<#
.SYNOPSIS
    Retrieve and display SolidFire accounts.

.DESCRIPTION
    This script connects to a SolidFire cluster using the JSON-RPC API to list all accounts.
    It supports secure credential input and exports the account details to a CSV file.

.PARAMETER ClusterIP
    The management IP address of the SolidFire cluster.

.PARAMETER Username
    The username for SolidFire admin.

.PARAMETER Password
    The password for SolidFire admin.

.NOTES
    This script forces the use of TLS 1.2 and bypasses SSL certificate validation to work with the specific host for running the script. You may not need it at all, depending on your Windows host.

.EXAMPLE
    .\ListAccounts.ps1
    Prompts for the necessary information and lists all accounts.

.EXAMPLE
    .\ListAccounts.ps1 -ClusterIP "192.168.1.100" -Username "admin" -Password "yourPassword"
    Lists accounts using provided credentials.
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

param (
    [string]$ClusterIP,
    [string]$Username,
    [SecureString]$Password
)

if (-not $ClusterIP) {
    $ClusterIP = Read-Host "Enter the SolidFire cluster management IP address"
}

if (-not $Username) {
    $Username = Read-Host "Enter your SolidFire username"
}

if (-not $Password) {
    $Password = Read-Host "Enter your SolidFire password" -AsSecureString
}

$SolidFireAPI = "https://$ClusterIP/json-rpc/10.0"
$Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)

$Payload = @{
    method = "ListAccounts"
    params = @{}
    id = 1
} | ConvertTo-Json -Depth 10

try {
    $Response = Invoke-RestMethod -Uri $SolidFireAPI -Method Post -Body $Payload -ContentType "application/json" -Credential $Credential

    if ($Response.result.accounts) {
        $Accounts = $Response.result.accounts | ForEach-Object {
            [PSCustomObject]@{
                AccountID = $_.accountID
                Username  = $_.username
            }
        }

        $Accounts | Format-Table -AutoSize

        $Timestamp = Get-Date -Format "yyyyMMddHHmm"
        $OutputPath = "$env:USERPROFILE\Documents\SolidFireAccounts_$Timestamp.csv"
        $Accounts | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

        Write-Host "Account details exported to $OutputPath" -ForegroundColor Green
    } else {
        Write-Host "No accounts found." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Failed to retrieve accounts: $_" -ForegroundColor Red
}

<#
.SYNOPSIS
    Retrieves and exports SolidFire group snapshot details.

.DESCRIPTION
    This script connects to a SolidFire cluster, retrieves the list of group snapshots,
    and exports the snapshot details to a CSV file in the user's Documents folder.

.PARAMETER ClusterIP
    The management IP address of the SolidFire cluster.

.PARAMETER Username
    The username for SolidFire admin.

.PARAMETER Password
    The password for SolidFire admin.

.NOTES
    This script forces the use of TLS 1.2 and bypasses SSL certificate validation
    in order to work with specific hosts. This may not be required on all systems.

.EXAMPLE
    .\ListGroupSnapshots.ps1
    Prompts for SolidFire cluster IP, username, and password, then exports snapshot details.

.EXAMPLE
    .\ListGroupSnapshots.ps1 -ClusterIP "192.168.1.100" -Username "admin" -Password "password"
    Retrieves and exports group snapshot details using provided credentials.
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

param (
    [string]$ClusterIP,
    [string]$Username,
    [string]$Password
)

if (-not $ClusterIP) {
    $ClusterIP = Read-Host "Enter the SolidFire cluster IP"
}
if (-not $Username) {
    $Username = Read-Host "Enter the SolidFire username"
}
if (-not $Password) {
    $Password = Read-Host -AsSecureString "Enter the SolidFire password"
    $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
}

$ApiUrl = "https://$ClusterIP/json-rpc/10.0"
$Base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${Password}"))
$TimeStamp = (Get-Date -Format "yyyyMMdd_HHmm")

$Headers = @{
    "Content-Type" = "application/json"
    "Authorization" = "Basic $Base64AuthInfo"
}

$Body = @{
    method = "ListGroupSnapshots"
    params = @{}
    id = 1
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Headers $Headers -Body $Body

    if ($response.result.groupSnapshots) {
        $groupSnapshots = $response.result.groupSnapshots | ForEach-Object {
            [PSCustomObject]@{
                "Snapshot ID"        = $_.groupSnapshotID
                "Retain Until"       = if ($_.members[0].expirationTime -ne "") { $_.members[0].expirationTime } else { "No Expiration" }
                "Create Time"        = $_.createTime
                "Name"               = $_.name
                "Volumes Protected"  = $_.members.Count
            }
        }

        $OutputFile = "$env:USERPROFILE\Documents\GroupSnapshots_$TimeStamp.csv"
        $groupSnapshots | Format-Table -AutoSize
        $groupSnapshots | Export-Csv -Path $OutputFile -NoTypeInformation -Force

        Write-Host "Snapshot details exported to $OutputFile" -ForegroundColor Green
    } else {
        Write-Host "No group snapshots found." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error retrieving group snapshots: $_" -ForegroundColor Red
}

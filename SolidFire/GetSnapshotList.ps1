<#
.SYNOPSIS
    Retrieve and export a list of SolidFire snapshots.

.DESCRIPTION
    This script connects to a SolidFire cluster using the provided management IP, credentials, and retrieves a list of snapshots. The results are displayed in the console and exported to a CSV file in the current user's Documents directory.

.PARAMETER ClusterIP
    The management IP address of the SolidFire cluster.

.PARAMETER Username
    The username for SolidFire admin.

.PARAMETER Password
    The password for SolidFire admin.

.EXAMPLE
    .\ListSnapshots.ps1
    Prompts for the required information and lists the snapshots.

    .\ListSnapshots.ps1 -ClusterIP "192.168.1.100" -Username "admin" -Password "YourPassword"
    Retrieves snapshots using the provided credentials and IP.

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
    $ClusterIP = Read-Host "Enter the SolidFire Cluster Management IP"
}
if (-not $Username) {
    $Username = Read-Host "Enter your SolidFire username"
}
if (-not $Password) {
    $Password = Read-Host "Enter your SolidFire password" -AsSecureString
}

$ApiUrl = "https://$ClusterIP/json-rpc/10.0"
$SecurePassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
$Credential = New-Object System.Management.Automation.PSCredential ($Username, (ConvertTo-SecureString $SecurePassword -AsPlainText -Force))

$Payload = @{
    method = "ListSnapshots"
    params = @{}
    id = 1
} | ConvertTo-Json -Depth 10

try {
    $Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Body $Payload -ContentType "application/json" -Credential $Credential

    if ($Response.result -and $Response.result.snapshots) {
        $Snapshots = $Response.result.snapshots | Select-Object snapshotID, volumeID, name, createTime
        $Snapshots | Format-Table -AutoSize

        $CsvFilePath = "$env:USERPROFILE\Documents\SolidFire_Snapshots_$(Get-Date -Format 'yyyyMMddHHmm').csv"
        $Snapshots | Export-Csv -Path $CsvFilePath -NoTypeInformation -Encoding UTF8

        Write-Host "Snapshot list successfully exported to $CsvFilePath" -ForegroundColor Green
    } else {
        Write-Host "No snapshots found." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error retrieving snapshots: $_" -ForegroundColor Red
}

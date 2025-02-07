<#
.SYNOPSIS
    List SolidFire volumes and display key details.

.DESCRIPTION
    This script connects to a SolidFire cluster and retrieves a list of volumes, displaying their key properties such as name, ID, and status.

.PARAMETER ApiUrl
    The URL of the SolidFire cluster API endpoint.

.PARAMETER Username
    The username for SolidFire admin.

.PARAMETER Password
    The password for SolidFire admin.

.EXAMPLE
    .\ListVolumes.ps1

    Prompts for API URL, username, and password, then lists volumes.

.NOTES
    This script forces the use of TLS 1.2 and bypasses SSL certificate validation to work with the specific host environment. You may not need these settings depending on your Windows host.
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

param (
    [string]$ApiUrl,
    [string]$Username,
    [SecureString]$Password
)

if (-not $ApiUrl) {
    $ApiUrl = Read-Host "Enter the SolidFire API URL (e.g., https://<MVIP>/json-rpc/10.0)"
}
if (-not $Username) {
    $Username = Read-Host "Enter your SolidFire username"
}
if (-not $Password) {
    $Password = Read-Host -AsSecureString "Enter your SolidFire password"
}

$Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:$(ConvertFrom-SecureString $Password -AsPlainText)"))
$Headers = @{
    "Content-Type"  = "application/json"
    "Authorization" = "Basic $Auth"
}

$Body = @{
    method = "ListVolumes"
    params = @{}
    id     = 1
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Body $Body -Headers $Headers

    if ($response.result.volumes) {
        $response.result.volumes | Select-Object Name, VolumeID, scsiNAADeviceID, scsiEUIDeviceID, status, @{Name="TotalSizeGB"; Expression={[math]::Round($_.totalSize / 1GB, 2)}} | Format-Table -AutoSize

        $OutputPath = "$env:USERPROFILE\Documents\SolidFire_Volumes_$(Get-Date -Format yyyyMMddHHmm).csv"
        $response.result.volumes | Select-Object Name, VolumeID, scsiNAADeviceID, scsiEUIDeviceID, status, @{Name="TotalSizeGB"; Expression={[math]::Round($_.totalSize / 1GB, 2)}} | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        Write-Host "Volume list exported to $OutputPath" -ForegroundColor Green
    } else {
        Write-Output "No volumes found or API call failed." -ForegroundColor Yellow
    }
} catch {
    Write-Host "An error occurred while retrieving volumes: $_" -ForegroundColor Red
}

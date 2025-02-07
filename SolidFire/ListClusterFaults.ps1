<#
.SYNOPSIS
    Retrieve and export current cluster faults from a SolidFire cluster.

.DESCRIPTION
    This script connects to a SolidFire cluster using the JSON-RPC API to retrieve a list of current cluster faults. 
    It filters out faults with "bestPractice" severity and exports the remaining faults to a CSV file in the user's Documents directory.

.PARAMETER ClusterIP
    The IP address of the SolidFire cluster management endpoint.

.PARAMETER Username
    The username for SolidFire admin authentication.

.PARAMETER Password
    The password for SolidFire admin authentication.

.EXAMPLE
    .\ListClusterFaults.ps1
    Prompts for the required information and exports the current cluster faults to a CSV file.

.NOTES
    This script forces the use of TLS 1.2 and bypasses SSL certificate validation in order to work with specific host requirements. 
    You may not need it at all, depending on your Windows host.
#>

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

$ClusterIP = Read-Host "Enter the SolidFire Cluster IP"
$Username = Read-Host "Enter the SolidFire Username"
$Password = Read-Host -AsSecureString "Enter the SolidFire Password"
$ApiUrl = "https://$ClusterIP/json-rpc/10.0"

$AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:$([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)))"))
$Headers = @{
    "Authorization" = "Basic $AuthInfo"
    "Content-Type"  = "application/json"
}

$Payload = @{
    method = "ListClusterFaults"
    params = @{
        faultTypes    = "current"
        bestPractices = $false
    }
    id = 1
} | ConvertTo-Json -Depth 10 -Compress

try {
    $Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Headers $Headers -Body $Payload
    $Faults = $Response.result.faults

    $FilteredFaults = $Faults | Where-Object { $_.severity -ne "bestPractice" }

    if ($FilteredFaults.Count -eq 0) {
        Write-Host "No active alerts found on the cluster."
    } else {
        $FormattedFaults = $FilteredFaults | ForEach-Object {
            [PSCustomObject]@{
                FaultID   = $_.clusterFaultID
                Severity  = $_.severity
                Type      = $_.type
                Node      = $_.nodeID
                DriveID   = $_.driveID
                ErrorCode = $_.code
                Details   = $_.details
                Date      = $_.date
            }
        }

        $FormattedFaults | Format-Table -AutoSize

        $Timestamp = (Get-Date -Format "yyyyMMddHHmm")
        $OutputDir = "$env:USERPROFILE\Documents\SolidFireClusterFaults"
        if (-not (Test-Path -Path $OutputDir)) {
            New-Item -ItemType Directory -Path $OutputDir | Out-Null
        }
        $OutputPath = Join-Path -Path $OutputDir -ChildPath "CurrentFaults_$Timestamp.csv"
        $FormattedFaults | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        Write-Host "Current alerts exported to $OutputPath"
    }
} catch {
    Write-Error "Failed to retrieve cluster faults: $_"
}

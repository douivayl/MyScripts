# Force PowerShell to Use TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Bypass SSL Certificate Validation (For Testing Only)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# Define API Endpoint and Credentials
$ApiUrl = "https://10.208.174.40/json-rpc/10.0"
$Username = "admin"
$Password = "fraschVDC!"

# Create Headers
$Base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${Password}"))

$TimeStamp = (Get-Date -Format "yyyMMdd_HHmmss")

$Headers = @{
    "Content-Type" = "application/json"
    "Authorization" = "Basic $Base64AuthInfo"
}

# Create API Request Body for ListGroupSnapshots
$Body = @{
    method = "ListGroupSnapshots"
    params = @{}
    id = 1
} | ConvertTo-Json -Depth 10

# Make API Call
$response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Headers $Headers -Body $Body

# Process Response
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

    # Display and Export to CSV
    $OutputFile = "$env:USERPROFILE\Documents\GroupSnapshots_$TimeStamp.csv"
    $groupSnapshots | Format-Table -AutoSize
    $groupSnapshots | Export-Csv -Path $OutputFile -NoTypeInformation -Force

    Write-Host "Snapshot details exported to $OutputFile"
} else {
    Write-Host "No group snapshots found."
}
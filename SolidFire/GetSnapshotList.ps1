# Force PowerShell to Use TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Bypass SSL Certificate Validation (For Testing Only)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# Define API Endpoint & Credentials
$SolidFireAPI = "https://<MVIP>/json-rpc/10.0"
$User = "admin"
$Password = "YourPassword"

# Prepare API Payload
$Payload = @{
    method = "ListSnapshots"
    params = @{}
    id = 1
} | ConvertTo-Json -Depth 10

# Call the API
try {
    $Response = Invoke-RestMethod -Uri $SolidFireAPI -Method Post -Body $Payload -ContentType "application/json" -Credential (New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString $Password -AsPlainText -Force)))
    
    # Output Snapshots
    if ($Response.result -and $Response.result.snapshots) {
        $Response.result.snapshots | Format-Table snapshotID, volumeID, name, createTime
    } else {
        Write-Host "No snapshots found." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Error retrieving snapshots: $_" -ForegroundColor Red
}

if ($Response.result -and $Response.result.snapshots) {
    $CsvFilePath = "C:\SolidFire_Snapshots.csv"  # Modify path as needed

    # Write CSV Header
    "snapshotID,volumeID,name,createTime" | Out-File -FilePath $CsvFilePath -Encoding utf8 -Force

    # Append Each Snapshot as a Line
    foreach ($Snapshot in $Response.result.snapshots) {
        "$($Snapshot.snapshotID),$($Snapshot.volumeID),$($Snapshot.name),$($Snapshot.createTime)" | Out-File -FilePath $CsvFilePath -Append -Encoding utf8
    }

    Write-Host "Snapshot list successfully written line by line to $CsvFilePath" -ForegroundColor Green
} else {
    Write-Host "No snapshots found to export." -ForegroundColor Yellow
}

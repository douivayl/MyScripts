# Force PowerShell to Use TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Bypass SSL Certificate Validation (For Testing Only)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# Define API Endpoint & Credentials
$SolidFireAPI = "https://<MVIP>/json-rpc/10.0"  # Replace <MVIP> with Management Virtual IP
$User = "admin"
$Password = "YourPassword"

# Function to delete a group snapshot by ID
function Delete-SolidFireGroupSnapshot {
    param (
        [int]$GroupSnapshotID
    )

    $Payload = @{
        method = "DeleteGroupSnapshot"
        params = @{
            groupSnapshotID = $GroupSnapshotID
        }
        id = 1
    } | ConvertTo-Json -Depth 10

    try {
        $Response = Invoke-RestMethod -Uri $SolidFireAPI -Method Post -Body $Payload -ContentType "application/json" `
            -Credential (New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString $Password -AsPlainText -Force)))

        if ($Response.result) {
            Write-Host "Group Snapshot ID $GroupSnapshotID deleted successfully." -ForegroundColor Green
        } else {
            Write-Host "Failed to delete Group Snapshot ID $GroupSnapshotID." -ForegroundColor Red
        }
    } catch {
        Write-Host "Error deleting Group Snapshot ID $GroupSnapshotID: $_" -ForegroundColor Red
    }
}

# Ask user for Group Snapshot ID(s)
$GroupSnapshotIDs = Read-Host "Enter Group Snapshot ID(s) to delete (comma-separated)"
$GroupSnapshotList = $GroupSnapshotIDs -split "," | ForEach-Object { $_.Trim() }

# Delete each group snapshot one by one
foreach ($ID in $GroupSnapshotList) {
    $CleanID = ($ID -replace '\D', '') -as [int]  # Remove non-digits and convert to integer

    if ($CleanID -gt 0) {  
        Delete-SolidFireGroupSnapshot -GroupSnapshotID $CleanID
    } else {
        Write-Host "Invalid Group Snapshot ID: $ID" -ForegroundColor Yellow
    }
}

Write-Host "Group snapshot deletion process completed!" -ForegroundColor Cyan

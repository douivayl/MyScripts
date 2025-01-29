# Force PowerShell to Use TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Bypass SSL Certificate Validation (For Testing Only)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# Define API Endpoint & Credentials
$SolidFireAPI = "https://<MVIP>/json-rpc/10.0"  # Replace <MVIP> with the Management Virtual IP
$User = "admin"
$Password = "YourPassword"

# Function to delete a snapshot by ID
function Delete-SolidFireSnapshot {
    param (
        [int]$SnapshotID
    )

    $Payload = @{
        method = "DeleteSnapshot"
        params = @{
            snapshotID = $SnapshotID
        }
        id = 1
    } | ConvertTo-Json -Depth 10

    try {
        $Response = Invoke-RestMethod -Uri $SolidFireAPI -Method Post -Body $Payload -ContentType "application/json" -Credential (New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString $Password -AsPlainText -Force)))

        if ($Response.result) {
            Write-Host "Snapshot ID $SnapshotID deleted successfully." -ForegroundColor Green
        } else {
            Write-Host "Failed to delete Snapshot ID $SnapshotID." -ForegroundColor Red
        }
    } catch {
        Write-Host "Error deleting Snapshot ID $SnapshotID: $_" -ForegroundColor Red
    }
}

# Ask user for Snapshot ID(s)
$SnapshotIDs = Read-Host "Enter Snapshot ID(s) to delete (comma-separated)"
$SnapshotList = $SnapshotIDs -split "," | ForEach-Object { $_.Trim() }

# Delete each snapshot one by one
foreach ($ID in $SnapshotList) {
    if ($ID -match '^\d+$') {
        Delete-SolidFireSnapshot -SnapshotID [int]$ID
    } else {
        Write-Host "Invalid Snapshot ID: $ID" -ForegroundColor Yellow
    }
}

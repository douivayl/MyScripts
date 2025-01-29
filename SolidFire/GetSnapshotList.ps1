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

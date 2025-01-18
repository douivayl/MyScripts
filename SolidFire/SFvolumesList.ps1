# Force PowerShell to Use TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Bypass SSL Certificate Validation (For Testing Only)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# Define API URL
$ApiUrl = "https://10.208.174.40/json-rpc/10.0"

# Define Credentials
$Username = "admin"
$Password = "fraschVDC!"

# Create Basic Authentication Header
$Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${Password}"))

# Define Headers
$Headers = @{
    "Content-Type"  = "application/json"
    "Authorization" = "Basic $Auth"
}

# Define Request Body
$Body = '{"method": "ListVolumes", "params": {}, "id": 1}'

# Send API Request
$response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Body $Body -Headers $Headers

# Extract and Display Volumes
if ($response.result.volumes) {
    $response.result.volumes | Select-Object Name, VolumeID, scsiNAADeviceID, scsiEUIDeviceID, status, totalSize | Format-Table -AutoSize
} else {
    Write-Output "No volumes found or API call failed."
}
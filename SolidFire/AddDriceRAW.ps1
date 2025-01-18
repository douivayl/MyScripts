# Force PowerShell to Use TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Bypass SSL Certificate Validation
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# Define the SolidFire API endpoint and credentials
$ClusterIP = "10.208.94.40"
$Username = "admin"
$Password = "milcalVDC!"
$ApiUrl = "https://$ClusterIP/json-rpc/10.0"

# Encode credentials for basic authentication
$AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${Password}"))
$Headers = @{
    "Authorization" = "Basic $AuthInfo"
    "Content-Type" = "application/json"
}

# Drives to be added
$DrivesToAdd = @(
    @{ driveID = 253 }
)

# Define the JSON payload for the API call
$Payload = @{
    method = "AddDrives"
    params = @{
        drives = $DrivesToAdd
    }
    id = 1
} | ConvertTo-Json -Depth 10 -Compress

# Make the API call and display the raw response
$Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Headers $Headers -Body $Payload
$Response | ConvertTo-Json -Depth 10
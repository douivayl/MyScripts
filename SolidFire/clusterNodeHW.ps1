# Force PowerShell to Use TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Bypass SSL Certificate Validation (For Testing Only)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

# Define the API endpoint and credentials
$SolidFireAPI = "https://10.208.94.40/json-rpc/10.0"  # Replace with your cluster's endpoint
$User = "admin"  # Replace with your username
$Password = "milcalVDC!"  # Replace with your password

# Prepare the request payload for GetHardwareInfo
$Payload = @{
    method = "GetHardwareInfo"
    params = @{
        force = $true  # Retrieve info for all nodes
    }
    id = 1
} | ConvertTo-Json -Depth 10

# Make the API request
try {
    Write-Host "Retrieving hardware information for all nodes..." -ForegroundColor Yellow

    $Response = Invoke-RestMethod -Uri $SolidFireAPI -Method Post -Body $Payload -ContentType "application/json" -Credential (New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString $Password -AsPlainText -Force)))

    # Handle the response
    if ($Response.result.hardwareInfo) {
        Write-Host "Hardware Information for Nodes:" -ForegroundColor Green

        $HardwareInfo = $Response.result.hardwareInfo

        # Iterate over the hardwareInfo object to list all attributes
        foreach ($Key in $HardwareInfo.PSObject.Properties.Name) {
            $Value = $HardwareInfo.$Key

            # Handle nested objects and arrays
            if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
                Write-Host "$Key: (Complex Object or Array)" -ForegroundColor Cyan
                $Value | ConvertTo-Json -Depth 10 | Write-Output
            } else {
                Write-Host "$Key: $Value"
            }
        }
    } else {
        Write-Host "No hardware information returned in the response." -ForegroundColor Red
    }
} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}

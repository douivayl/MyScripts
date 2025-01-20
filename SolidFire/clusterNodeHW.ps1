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
    params = @{}  # No additional parameters needed
    id = 1
} | ConvertTo-Json -Depth 10

# Make the API request
try {
    Write-Host "Retrieving hardware information for the node..." -ForegroundColor Yellow

    $Response = Invoke-RestMethod -Uri $SolidFireAPI -Method Post -Body $Payload -ContentType "application/json" -Credential (New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString $Password -AsPlainText -Force)))

    # Handle the response
    if ($Response.result.hardwareInfo) {
        Write-Host "Hardware Information:" -ForegroundColor Green

        # Extract high-level information
        $HardwareInfo = $Response.result.hardwareInfo
        Write-Host "Board Serial: $($HardwareInfo.boardSerial)"
        Write-Host "Chassis Serial: $($HardwareInfo.chassisSerial)"
        Write-Host "Node Slot: $($HardwareInfo.nodeSlot)"
        Write-Host "UUID: $($HardwareInfo.uuid)"
        Write-Host "-----------------------------------"

        # Display drive information
        Write-Host "Drives Information:" -ForegroundColor Cyan
        foreach ($Drive in $HardwareInfo.driveHardware) {
            Write-Host "  Drive Slot: $($Drive.slot)"
            Write-Host "  Drive Serial: $($Drive.serial)"
            Write-Host "  Drive Vendor: $($Drive.vendor)"
            Write-Host "  Drive Size (GB): $([math]::Round($Drive.size / 1GB, 2))"
            Write-Host "  Drive Health: $($Drive.lifeRemainingPercent)% Life Remaining"
            Write-Host "  Power-On Hours: $($Drive.powerOnHours)"
            Write-Host "-----------------------------------"
        }

        # Display network information
        Write-Host "Network Interfaces:" -ForegroundColor Cyan
        foreach ($Interface in $HardwareInfo.networkInterfaces.GetEnumerator()) {
            Write-Host "  Interface: $($Interface.Key)"
            Write-Host "  Details: $($Interface.Value)"
        }
    } else {
        Write-Host "No hardware information returned." -ForegroundColor Red
    }
} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}

<# 
.SYNOPSIS
    Checks WSUS server from registry and whether updates are pending.

.DESCRIPTION
    This script reads the WSUS server configuration from the registry and checks if there are any updates pending that require a restart.

.EXAMPLE
    .\Test-WUAState.ps1
    This command runs the script to check WSUS configuration and pending updates.

.NOTES
    Author: Andreas Zogg
    Date: 01.12.2025
    
.LINK
#>

# Read WSUS server from registry
$wuRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
try {
    $wsusServer = (Get-ItemProperty -Path $wuRegPath -ErrorAction Stop).WUServer
    $wsusStatusServer = (Get-ItemProperty -Path $wuRegPath -ErrorAction Stop).WUStatusServer

    Write-Host "WSUS Server: $wsusServer"
    Write-Host "WSUS Status Server: $wsusStatusServer"
} catch {
    Write-Host "No WSUS server configured in the registry." -ForegroundColor Yellow
}

# Check pending updates
$pendingPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
if (Test-Path $pendingPath) {
    Write-Host "Updates are installed that require a restart!" -ForegroundColor Red
} else {
    Write-Host "No pending updates with restart requirement found." -ForegroundColor Green
}

# Optional: additional status values
$volatilePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"
try {
    $volatile = (Get-ItemProperty -Path $volatilePath -ErrorAction Stop).UpdateExeVolatile
    if ($volatile -ne $null) {
        Write-Host "UpdateExeVolatile value: $volatile"
    }
} catch {
    Write-Host "No UpdateExeVolatile value found."
}

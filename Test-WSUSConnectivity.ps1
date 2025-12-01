<# 
.SYNOPSIS
    Counts the number of updates available from WSUS for this server.

.DESCRIPTION
    This script connects to the WSUS server configured on this machine and counts the number of software updates that are available but not yet installed.

.EXAMPLE
    .\Test-WSUSConnectivity.ps1
    This command runs the script to count available updates from WSUS.

.NOTES
    Author: Andreas Zogg
    Date: 01.12.2025

.LINK
#>

# Start Windows Update session
try {
    $updateSession  = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()

    # Only updates that are not yet installed
    $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software'")

    # Output count
    $pendingCount = $searchResult.Updates.Count
    Write-Host "There are $pendingCount updates available from WSUS for this server." -ForegroundColor Yellow

    # Optional: list of titles
    foreach ($update in $searchResult.Updates) {
        Write-Host "- $($update.Title)"
    }
} catch {
    Write-Host "Error connecting to WSUS or searching for updates: $($_.Exception.Message)" -ForegroundColor Red
}

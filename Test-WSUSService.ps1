#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Monitors the Windows Update Service (WSUS) and restarts it if necessary
.DESCRIPTION
    This script checks the status of the Windows Update Service and starts it
    if it's not running. It logs all actions to the Windows Event Log.
.NOTES
    Author: Andreas Zogg
    Date: 02.12.2025
    Requires: Administrator privileges
#>

# Event Log Parameter
$LogName = "Application"
$Source = "WSUS-Monitor"

try {
    # Check if Event Source exists, create it if not
    if (-not [System.Diagnostics.EventLog]::SourceExists($Source)) {
        New-EventLog -LogName $LogName -Source $Source -ErrorAction SilentlyContinue
    }
    
    # Windows Update Service Name
    $ServiceName = "wuauserv"
    
    # Query Service Status
    $Service = Get-Service -Name $ServiceName -ErrorAction Stop
    
    Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - WSUS Service Status: $($Service.Status)"
    
    # Check Service Status
    if ($Service.Status -ne "Running") {
        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - WSUS Service is not active. Attempting to start..."
        
        # Event Log entry for Service start attempt
        Write-EventLog -LogName $LogName -Source $Source -EventId 1001 -EntryType Warning -Message "Windows Update Service (wuauserv) was stopped and is being restarted."
        
        # Start Service
        Start-Service -Name $ServiceName -ErrorAction Stop
        
        # Wait briefly and check again
        Start-Sleep -Seconds 5
        $ServiceAfterStart = Get-Service -Name $ServiceName
        
        if ($ServiceAfterStart.Status -eq "Running") {
            Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - WSUS Service started successfully."
            Write-EventLog -LogName $LogName -Source $Source -EventId 1002 -EntryType Information -Message "Windows Update Service (wuauserv) was started successfully."
        } else {
            Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Error: WSUS Service could not be started."
            Write-EventLog -LogName $LogName -Source $Source -EventId 1003 -EntryType Error -Message "Windows Update Service (wuauserv) could not be started. Status: $($ServiceAfterStart.Status)"
        }
    } else {
        Write-Output "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - WSUS Service is already running."
        # Only log on first run or after restart
        $LastCheck = Get-ItemProperty -Path "HKLM:\SOFTWARE\WSUSMonitor" -Name "LastSuccessfulCheck" -ErrorAction SilentlyContinue
        if (-not $LastCheck -or (Get-Date).AddMinutes(-30) -gt [DateTime]$LastCheck.LastSuccessfulCheck) {
            Write-EventLog -LogName $LogName -Source $Source -EventId 1000 -EntryType Information -Message "Windows Update Service (wuauserv) is running normally."
        }
    }
    
    # Registry entry for last successful check
    if (-not (Test-Path "HKLM:\SOFTWARE\WSUSMonitor")) {
        New-Item -Path "HKLM:\SOFTWARE\WSUSMonitor" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\WSUSMonitor" -Name "LastSuccessfulCheck" -Value (Get-Date).ToString()
    
} catch {
    $ErrorMessage = "Error monitoring WSUS Service: $($_.Exception.Message)"
    Write-Error $ErrorMessage
    
    try {
        Write-EventLog -LogName $LogName -Source $Source -EventId 1004 -EntryType Error -Message $ErrorMessage
    } catch {
        # If Event Log also fails, write to a file
        $LogFile = "$env:TEMP\WSUS-Monitor-Error.log"
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $ErrorMessage" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    }
    
    exit 1
}
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Creates a Scheduled Task to monitor the Windows Update Service
.DESCRIPTION
    This script creates a Windows Scheduled Task that runs the Monitor-WSUSService.ps1 
    script every 15 minutes to monitor the WSUS Service.
.PARAMETER ScriptPath
    Path to the source Test-WSUSService.ps1 script. Default is the current directory.
.PARAMETER TargetPath
    Target directory where the script will be copied. Default is c:\admin\scripts.
.EXAMPLE
    .\Setup-WSUSMonitoringTask.ps1
    .\Setup-WSUSMonitoringTask.ps1 -TargetPath "C:\Scripts"
.NOTES
    Author: Andreas Zogg
    Date: 02.12.2025
    Requires: Administrator privileges
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ScriptPath = "$PSScriptRoot\Test-WSUSService.ps1",
    
    [Parameter(Mandatory=$false)]
    [string]$TargetPath = "c:\admin\scripts"
)

try {
    # Check if the source monitoring script exists
    if (-not (Test-Path $ScriptPath)) {
        throw "The Test-WSUSService.ps1 script was not found: $ScriptPath"
    }
    
    Write-Host "Source monitoring script: $ScriptPath" -ForegroundColor Green
    
    # Create target directory if it doesn't exist
    if (-not (Test-Path $TargetPath)) {
        Write-Host "Creating target directory: $TargetPath" -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
    }
    
    # Copy script to target location
    $TargetScriptPath = Join-Path $TargetPath "Test-WSUSService.ps1"
    Copy-Item -Path $ScriptPath -Destination $TargetScriptPath -Force
    Write-Host "Script copied to: $TargetScriptPath" -ForegroundColor Green
    
    # Use the copied script for the scheduled task
    $ScriptPath = $TargetScriptPath
    
    # Task Parameters
    $TaskName = "WSUS-Service-Monitor"
    $TaskDescription = "Monitors the Windows Update Service every 15 minutes and restarts it if necessary"
    
    # Check if task already exists
    $ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($ExistingTask) {
        Write-Host "Scheduled Task '$TaskName' already exists." -ForegroundColor Yellow
        $Response = Read-Host "Do you want to replace it? (y/n)"
        if ($Response -notmatch '^[yYjJ]') {
            Write-Host "Cancelled." -ForegroundColor Yellow
            return
        }
        
        # Delete existing task
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "Existing task has been removed." -ForegroundColor Yellow
    }
    
    # Task Action - PowerShell execution (using copied script)
    $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""
    
    # Task Trigger - Every 15 minutes
    $Trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration ([TimeSpan]::MaxValue) -At (Get-Date) -Once
    
    # Task Settings
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable:$false -DontStopOnIdleEnd
    
    # Task Principal - Run as SYSTEM
    $Principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # Register task
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Description $TaskDescription
    
    Write-Host "`nScheduled Task '$TaskName' was created successfully!" -ForegroundColor Green
    Write-Host "The task runs every 15 minutes and monitors the Windows Update Service." -ForegroundColor Green
    
    # Display task details
    Write-Host "`n=== Task Details ===" -ForegroundColor Cyan
    Write-Host "Name: $TaskName"
    Write-Host "Description: $TaskDescription"
    Write-Host "Execution: Every 15 minutes"
    Write-Host "User: NT AUTHORITY\SYSTEM"
    Write-Host "Script Location: $ScriptPath"
    Write-Host "Target Directory: $TargetPath"
    
    # Test first execution
    Write-Host "`n=== Test First Execution ===" -ForegroundColor Cyan
    $TestResponse = Read-Host "Do you want to run the task once for testing? (y/n)"
    if ($TestResponse -match '^[yYjJ]') {
        Start-ScheduledTask -TaskName $TaskName
        Write-Host "Task has been started. Check the Event Log for results." -ForegroundColor Green
        
        # Wait briefly and show task status
        Start-Sleep -Seconds 3
        $TaskInfo = Get-ScheduledTask -TaskName $TaskName | Get-ScheduledTaskInfo
        Write-Host "Task Status: $($TaskInfo.LastTaskResult)" -ForegroundColor Yellow
        Write-Host "Last Run: $($TaskInfo.LastRunTime)" -ForegroundColor Yellow
    }
    
    Write-Host "`n=== Management ===" -ForegroundColor Cyan
    Write-Host "Show task: Get-ScheduledTask -TaskName '$TaskName'"
    Write-Host "Stop task: Stop-ScheduledTask -TaskName '$TaskName'"
    Write-Host "Delete task: Unregister-ScheduledTask -TaskName '$TaskName'"
    Write-Host "Event Logs: Get-WinEvent -LogName Application | Where-Object {`$_.ProviderName -eq 'WSUS-Monitor'}"
    
} catch {
    Write-Error "Error creating the Scheduled Task: $($_.Exception.Message)"
    exit 1
}

# Helper function to display task logs
function Show-WSUSMonitorLogs {
    <#
    .SYNOPSIS
    Displays the Event Logs of the WSUS Monitor
    #>
    try {
        $Events = Get-WinEvent -LogName Application -ErrorAction Stop | 
                  Where-Object {$_.ProviderName -eq 'WSUS-Monitor'} | 
                  Select-Object -First 20
        
        if ($Events) {
            Write-Host "`n=== Last 20 WSUS Monitor Events ===" -ForegroundColor Cyan
            $Events | Format-Table TimeCreated, Id, LevelDisplayName, Message -AutoSize
        } else {
            Write-Host "No WSUS Monitor Events found." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Error retrieving Event Logs: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nNote: Use 'Show-WSUSMonitorLogs' to display the monitor logs." -ForegroundColor Cyan
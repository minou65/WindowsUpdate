# WindowsUpdate

PowerShell scripts for testing and monitoring Windows Update and WSUS connectivity.

## Scripts

### Test-WSUSConnectivity.ps1

Counts the number of updates available from WSUS for this server.

**Description:**  
This script connects to the WSUS server configured on this machine and counts the number of software updates that are available but not yet installed. It lists all available update titles.

**Usage:**
```powershell
.\Test-WSUSConnectivity.ps1
```

**Features:**
- Connects to Windows Update Service
- Searches for uninstalled software updates
- Displays count of available updates
- Lists all update titles
- Error handling for connectivity issues

---

### Test-WUAState.ps1

Checks WSUS server configuration from registry and whether updates are pending.

**Description:**  
This script reads the WSUS server configuration from the Windows registry and checks if there are pending updates that require a system restart.

**Usage:**
```powershell
.\Test-WUAState.ps1
```

**Features:**
- Reads WSUS server and status server from registry
- Checks for pending updates requiring restart
- Displays UpdateExeVolatile status values
- Color-coded output for quick status assessment

**Output Colors:**
- **Yellow:** WSUS configuration information or warnings
- **Red:** Updates requiring restart are pending
- **Green:** No pending updates with restart requirements

---

## Requirements

- Windows PowerShell 5.1 or later
- Windows Update Agent
- Appropriate permissions to read registry keys
- WSUS server configured (for Test-WSUSConnectivity.ps1)

## Author

Andreas Zogg

## Date

01.12.2025

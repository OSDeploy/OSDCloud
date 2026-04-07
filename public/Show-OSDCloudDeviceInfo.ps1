<#
.SYNOPSIS
Displays comprehensive WinPE and device hardware information during OS deployment startup.

.DESCRIPTION
Gathers and displays detailed hardware and environment information in Windows PE including system specifications, device identifiers, processor details, memory configuration, disk drives, and network adapters. Initializes the OSDCloud device environment and exports hardware WMI information to log files in the temporary directory. Validates system memory requirements and provides warnings if minimum specifications are not met.

.PARAMETER None
This function does not accept any parameters.

.EXAMPLE
Show-OSDCloudDeviceInfo
Displays comprehensive WinPE and device information including hardware specifications and device identifiers.

.OUTPUTS
None. This function displays system information to the console and exports hardware data to log files but does not return objects.

.NOTES
This function is designed for use in Windows PE startup environments and performs the following operations:

Information Displayed:
- OSDCloud PowerShell Module version
- WinPE version, architecture, and computer name
- Device manufacturer and model
- BIOS information
- Processor name and logical core count
- Total physical memory in GB
- Disk drive models and device IDs
- Network adapter names and MAC addresses

Note: Serial number and UUID output are suppressed for privacy reasons.

System Requirements:
- Minimum 6 GB of physical memory recommended
- Issues warning if memory is less than 6 GB

Log Files Created:
- Stores device information in $env:TEMP\osdcloud-logs directory
- Win32_DiskDrive.txt: Complete disk drive information
- Win32_NetworkAdapter.txt: Complete network adapter information

Functions Called:
- Get-OSDCloudModuleVersion: Retrieves current OSDCloud module version
- Initialize-OSDCloudDevice: Populates $global:OSDCloudDevice with hardware details

The function updates the window title to '[OSDCloud] - WinPE and Device Information' to indicate the current operation status.
#>
function Show-OSDCloudDeviceInfo {
    [CmdletBinding()]
    param ()
    #=================================================
    $Error.Clear()
    $host.ui.RawUI.WindowTitle = "[$(Get-Date -format s)] OSDCloud WinPE and Device Information"
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    #=================================================
    $osdCloudModuleVersion = (Get-OSDCloudModuleVersion).ToString()
    Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] OSDCloud PowerShell Module $osdCloudModuleVersion"
    Initialize-OSDCloudDevice
    #=================================================
    # Create the log path if it does not already exist
    $logsPath = Join-Path -Path $env:TEMP -ChildPath 'osdcloud-logs'
    if (-not (Test-Path -Path $logsPath)) {
        New-Item -Path $logsPath -ItemType Directory -Force | Out-Null
    }
    #=================================================
    # Gather hardware information
    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -Property Name, TotalPhysicalMemory
    $operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -Property Version, OSArchitecture
    $processors = Get-CimInstance -ClassName Win32_Processor -Property Name, NumberOfLogicalProcessors
    #=================================================
    # Device Details
    Write-Host -ForegroundColor DarkGray "WinPE $($operatingSystem.Version) $($operatingSystem.OSArchitecture) $($computerSystem.Name)"
    Write-Host -ForegroundColor DarkGray "Manufacturer: $($global:OSDCloudDevice.OSDManufacturer)"
    Write-Host -ForegroundColor DarkGray "Model: $($global:OSDCloudDevice.OSDModel)"
    Write-Host -ForegroundColor DarkGray "BIOS: $($global:OSDCloudDevice.BiosVersion)"
    Write-Host -ForegroundColor DarkGray "BIOS Release Date: $($global:OSDCloudDevice.BiosReleaseDate)"

    foreach ($item in $processors) {
        Write-Host -ForegroundColor DarkGray "Processor: $($item.Name) [$($item.NumberOfLogicalProcessors) Logical]"
    }

    $totalMemoryGB = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB)
    Write-Host -ForegroundColor DarkGray "Memory: $totalMemoryGB GB"
    if ($totalMemoryGB -lt 6) {
        Write-Warning "OSDCloud WinPE requires at least 6 GB of memory to function properly. Errors are expected."
    }

    # Win32_DiskDrive
    $diskDrives = Get-CimInstance -ClassName Win32_DiskDrive | Select-Object -Property *
    $diskDrives | Out-File -FilePath (Join-Path -Path $logsPath -ChildPath 'Win32_DiskDrive.txt') -Width 4096 -Force
    foreach ($item in $diskDrives) {
        Write-Host -ForegroundColor DarkGray "Disk: $($item.Model) [$($item.DeviceID)]"
    }

    # Win32_NetworkAdapter
    $networkAdapters = Get-CimInstance -ClassName Win32_NetworkAdapter | Select-Object -Property *
    $networkAdapters | Out-File -FilePath (Join-Path -Path $logsPath -ChildPath 'Win32_NetworkAdapter.txt') -Width 4096 -Force
    foreach ($item in $networkAdapters.Where({ $null -ne $_.GUID })) {
        Write-Host -ForegroundColor DarkGray "NetAdapter: $($item.Name) [$($item.MACAddress)]"
    }
    #=================================================
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    #=================================================
}
New-Alias -Name Show-PEStartupDeviceInfo -Value Show-OSDCloudDeviceInfo -Description 'Backward compatibility alias' -Force
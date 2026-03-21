<#
.SYNOPSIS
Displays comprehensive WinPE and device hardware information during OS deployment startup.

.DESCRIPTION
Gathers and displays detailed hardware and environment information in Windows PE including system specifications, device identifiers, processor details, memory configuration, disk drives, and network adapters. Initializes the OSDCloud device environment and exports hardware WMI information to log files in the temporary directory. Validates system memory requirements and provides warnings if minimum specifications are not met.

.PARAMETER None
This function does not accept any parameters.

.EXAMPLE
Show-PEStartupDeviceInfo
Displays comprehensive WinPE and device information including hardware specifications and device identifiers.

.OUTPUTS
None. This function displays system information to the console and exports hardware data to log files but does not return objects.

.NOTES
This function is designed for use in Windows PE startup environments and performs the following operations:

Information Displayed:
- OSDCloud PowerShell Module version
- WinPE version, architecture, and computer name
- Device manufacturer, model, and serial number
- UUID and BIOS information
- Processor name and logical core count
- Total physical memory in GB
- Disk drive models and device IDs
- Network adapter names and MAC addresses

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
function Show-PEStartupDeviceInfo {
    [CmdletBinding()]
    param ()
    #=================================================
    $Error.Clear()
    $host.ui.RawUI.WindowTitle = "[$(Get-Date -format s)] OSDCloud WinPE and Device Information"
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    #=================================================
    # Modules
    $OSDCloudModuleVersion = (Get-OSDCloudModuleVersion).ToString()
    Write-Host -ForegroundColor DarkCyan "OSDCloud PowerShell Module $OSDCloudModuleVersion"
    Initialize-OSDCloudDevice
    #=================================================
    # Create the log path if it does not already exist
    $LogsPath = "$env:TEMP\osdcloud-logs"
    if (-not (Test-Path -Path $LogsPath)) {
        New-Item -Path $LogsPath -ItemType Directory -Force | Out-Null
    }
    #=================================================
    # Export Hardware Information
    $classWin32ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property *
    $classWin32OperatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -Property *
    $classWin32Processor = Get-CimInstance -ClassName Win32_Processor | Select-Object -Property *
    #=================================================
    # Device Details
    Write-Host -ForegroundColor DarkGray "WinPE" $classWin32OperatingSystem.Version $classWin32OperatingSystem.OSArchitecture $classWin32ComputerSystem.Name
    Write-Host -ForegroundColor DarkGray "Manufacturer:" $global:OSDCloudDevice.OSDManufacturer
    Write-Host -ForegroundColor DarkGray "Model:" $global:OSDCloudDevice.OSDModel
    # Write-Host -ForegroundColor DarkGray "SN:" $global:OSDCloudDevice.SerialNumber
    # Write-Host -ForegroundColor DarkGray "UUID:" $global:OSDCloudDevice.UUID
    # Write-Host -ForegroundColor DarkGray "OSD Product:" $global:OSDCloudDevice.OSDProduct
    Write-Host -ForegroundColor DarkGray "BIOS:" $global:OSDCloudDevice.BiosVersion
    Write-Host -ForegroundColor DarkGray "BIOS Release Date:" $global:OSDCloudDevice.BiosReleaseDate
    # Write-Host -ForegroundColor DarkGray 'SystemFamily:' $classWin32ComputerSystem.SystemFamily
    # Write-Host -ForegroundColor DarkGray "BaseBoardProduct:" $global:OSDCloudDevice.BaseBoardProduct
    # Write-Host -ForegroundColor DarkGray "SystemSKUNumber:" $global:OSDCloudDevice.SystemSKUNumber

    # Win32_Processor
    foreach ($Item in $classWin32Processor) {
        Write-Host -ForegroundColor DarkGray "Processor:" $($Item.Name) "[$($Item.NumberOfLogicalProcessors) Logical]"
    }
    $TotalMemory = $([math]::Round($classWin32ComputerSystem.TotalPhysicalMemory / 1024 / 1024 / 1024))
    Write-Host -ForegroundColor DarkGray "Memory:" $TotalMemory 'GB'
    if ($TotalMemory -lt 6) {
        Write-Warning "OSDCloud WinPE requires at least 6 GB of memory to function properly. Errors are expected."
    }

    # Win32_DiskDrive
    $Win32DiskDrive = Get-CimInstance -ClassName Win32_DiskDrive | Select-Object -Property *
    $Win32DiskDrive | Out-File $LogsPath\Win32_DiskDrive.txt -Width 4096 -Force
    foreach ($Item in $Win32DiskDrive) {
        Write-Host -ForegroundColor DarkGray "Disk: $($Item.Model) [$($Item.DeviceID)]"
    }

    # Win32_NetworkAdapter
    $Win32NetworkAdapter = Get-CimInstance -ClassName Win32_NetworkAdapter | Select-Object -Property *
    $Win32NetworkAdapter | Out-File $LogsPath\Win32_NetworkAdapter.txt -Width 4096 -Force
    $Win32NetworkAdapterGuid = $Win32NetworkAdapter | Where-Object { $null -ne $_.GUID }
    if ($Win32NetworkAdapterGuid) {
        foreach ($Item in $Win32NetworkAdapterGuid) {
            Write-Host -ForegroundColor DarkGray "NetAdapter: $($Item.Name) [$($Item.MACAddress)]"
        }
    }

    if (Get-Command -Name Get-SecureBootUEFI -ErrorAction SilentlyContinue) {
        $WinUEFIca2023 = [System.Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI DB).Bytes) -match 'Windows UEFI CA 2023'
        if ($WinUEFIca2023) {
            Write-Host -ForegroundColor Green "Windows UEFI CA 2023 is present."
        }
        else {
            Write-Host -ForegroundColor DarkGray "Windows UEFI CA 2023 is not present."
        }
        $MsUEFIca2023 = [System.Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI DB).Bytes) -match 'Microsoft UEFI CA 2023'
        if ($MsUEFIca2023) {
            Write-Host -ForegroundColor Green "Microsoft UEFI CA 2023 is present."
        }
        else {
            Write-Host -ForegroundColor DarkGray "Microsoft UEFI CA 2023 is not present."
        }
        $MsKEKca2023 = [System.Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI KEK).Bytes) -match 'Microsoft Corporation KEK 2K CA 2023'
        if ($MsKEKca2023) {
            Write-Host -ForegroundColor Green "Microsoft Corporation KEK 2K CA 2023 is present."
        }
        else {
            Write-Host -ForegroundColor DarkGray "Microsoft Corporation KEK 2K CA 2023 is not present."
        }
    }

    #=================================================
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    #=================================================
}
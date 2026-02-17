function Show-PEStartupDeviceInfo {
    [CmdletBinding()]
    param ()
    #=================================================
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    $Error.Clear()
    $host.ui.RawUI.WindowTitle = "[$(Get-Date -format s)] OSDCloud WinPE and Device Information"
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
    Write-Host -ForegroundColor DarkGray "SN:" $global:OSDCloudDevice.SerialNumber
    Write-Host -ForegroundColor DarkGray "UUID:" $global:OSDCloudDevice.UUID
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
    #=================================================
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    #=================================================
}
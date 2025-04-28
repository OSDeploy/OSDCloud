function Use-PEStartupDeviceInfo {
    [CmdletBinding()]
    param ()
    #=================================================
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Start"
    $Error.Clear()
    $host.ui.RawUI.WindowTitle = '[OSDCloud] Device Information'
    #=================================================
    Write-Host -ForegroundColor DarkCyan "[$((Get-Date).ToString('HH:mm:ss'))] Gathering Device Information"

    # Create the log path if it does not already exist
    $LogsPath = "$env:TEMP\osdcloud-logs"
    if (-NOT (Test-Path -Path $LogsPath)) {
        New-Item -Path $LogsPath -ItemType Directory -Force | Out-Null
    }

    # Export Hardware Information
    $Win32Battery = Get-CimInstance -ClassName Win32_Battery | Select-Object -Property *
    $Win32Battery | Out-File $LogsPath\Win32_Battery.txt -Width 4096 -Force
    $Win32BaseBoard = Get-CimInstance -ClassName Win32_BaseBoard | Select-Object -Property *
    $Win32BaseBoard | Out-File $LogsPath\Win32_BaseBoard.txt -Width 4096 -Force
    $Win32BIOS = Get-CimInstance -ClassName Win32_BIOS | Select-Object -Property *
    $Win32BIOS | Out-File $LogsPath\Win32_BIOS.txt -Width 4096 -Force
    $Win32ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property *
    $Win32ComputerSystem | Out-File $LogsPath\Win32_ComputerSystem.txt -Width 4096 -Force
    $Win32OperatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -Property *
    $Win32OperatingSystem | Out-File $LogsPath\Win32_OperatingSystem.txt -Width 4096 -Force
    $Win32Processor = Get-CimInstance -ClassName Win32_Processor | Select-Object -Property *
    $Win32Processor | Out-File $LogsPath\Win32_Processor.txt -Width 4096 -Force
    $Win32PnPEntityError = Get-CimInstance -ClassName Win32_PnPEntity | Select-Object -Property * | Where-Object { $_.Status -eq 'Error' } | Sort-Object HardwareID -Unique | Sort-Object Name
    $Win32PnPEntityError | Out-File $LogsPath\Win32_PnPEntityError.txt -Width 4096 -Force

    # OSD Ready
    $OSDVersion = (Get-Module -Name OSD -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version
    Write-Host -ForegroundColor DarkCyan "[$((Get-Date).ToString('HH:mm:ss'))] OSD PowerShell Module $OSDVersion Ready"

    # Device Details
    Write-Host ''
    Write-Host -ForegroundColor DarkGray 'WinPE' $Win32OperatingSystem.Version $Win32OperatingSystem.OSArchitecture
    Write-Host -ForegroundColor DarkGray 'ComputerName:' $Win32ComputerSystem.Name
    #Write-Host -ForegroundColor DarkGray 'SystemFamily:' $Win32ComputerSystem.SystemFamily
    Write-Host -ForegroundColor DarkGray 'BIOS:' $Win32BIOS.SMBIOSBIOSVersion $Win32BIOS.ReleaseDate
    Write-Host -ForegroundColor DarkGray 'BaseBoard Product:' $Win32BaseBoard.Product
    if (($Win32ComputerSystem.SystemSKUNumber) -and ($Win32ComputerSystem.SystemSKUNumber -ne 'None')) {
        Write-Host -ForegroundColor DarkGray 'ComputerSystem SystemSKUNumber:' $Win32ComputerSystem.SystemSKUNumber
    }

    # Win32_Processor
    foreach ($Item in $Win32Processor) {
        Write-Host -ForegroundColor DarkGray 'Processor:' $($Item.Name) "[$($Item.NumberOfLogicalProcessors) Logical]"
    }
    $TotalMemory = $([math]::Round($Win32ComputerSystem.TotalPhysicalMemory / 1024 / 1024 / 1024))
    Write-Host -ForegroundColor DarkGray 'Memory:' $TotalMemory 'GB'
    if ($TotalMemory -lt 6) {
        Write-Warning "[$((Get-Date).ToString('HH:mm:ss'))] OSDCloud WinPE requires at least 6 GB of memory to function properly. Errors are expected."
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

    # Start backup PowerShell Session (minimized)
    Write-Host -ForegroundColor Green 'Manufacturer:' $Win32ComputerSystem.Manufacturer
    Write-Host -ForegroundColor Green 'Model:' $Win32ComputerSystem.Model
    Write-Host -ForegroundColor Green 'SerialNumber:' $Win32BIOS.SerialNumber
    # TPM
    try {
        $Win32Tpm = Get-CimInstance -Namespace 'ROOT\cimv2\Security\MicrosoftTpm' -ClassName Win32_Tpm | Select-Object -Property *
        $Win32Tpm | Out-File $LogsPath\Win32_Tpm.txt -Width 4096 -Force

        if ($null -eq $Win32Tpm) {
            Write-Host -ForegroundColor Red 'TPM and Autopilot: Not Supported'
            #Write-Host -ForegroundColor Red "Autopilot: Not Supported"
            Start-Sleep -Seconds 5
        }
        elseif ($Win32Tpm.SpecVersion) {
            if ($null -eq $Win32Tpm.SpecVersion) {
                Write-Host -ForegroundColor Red 'TPM: Unable to detect the TPM Version'
                Write-Host -ForegroundColor Red 'Autopilot: Not Supported'
                Start-Sleep -Seconds 5
            }

            $majorVersion = $Win32Tpm.SpecVersion.Split(',')[0] -as [int]
            if ($majorVersion -lt 2) {
                Write-Host -ForegroundColor Red 'TPM: Version is less than 2.0'
                Write-Host -ForegroundColor Red 'Autopilot: Not Supported'
                Start-Sleep -Seconds 5
            }
            else {
                Write-Host -ForegroundColor Green "TPM 2.0 ($($Win32Tpm.ManufacturerIdTxt), $($Win32Tpm.ManufacturerVersion)) and Autopilot: Supported"
                #Write-Host -ForegroundColor DarkGray "TPM IsActivated: $($Win32Tpm.IsActivated_InitialValue)"
                #Write-Host -ForegroundColor DarkGray "TPM IsEnabled: $($Win32Tpm.IsEnabled_InitialValue)"
                #Write-Host -ForegroundColor DarkGray "TPM IsOwned: $($Win32Tpm.IsOwned_InitialValue)"
                #Write-Host -ForegroundColor DarkGray "TPM Manufacturer: $($Win32Tpm.ManufacturerIdTxt)"
                #Write-Host -ForegroundColor DarkGray "TPM Manufacturer Version: $($Win32Tpm.ManufacturerVersion)"
                #Write-Host -ForegroundColor DarkGray "TPM SpecVersion: $($Win32Tpm.SpecVersion)"
            }
        }
        else {
            Write-Host -ForegroundColor Red 'TPM: Not Supported'
            Write-Host -ForegroundColor Red 'Autopilot: Not Supported'
        }
    }
    catch {
    }
    #=================================================
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Done"
    #=================================================
}
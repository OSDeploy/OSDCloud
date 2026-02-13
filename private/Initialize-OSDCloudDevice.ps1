function Initialize-OSDCloudDevice {
    [CmdletBinding()]
    param ()
    #=================================================
    $Error.Clear()
    #=================================================
    # Create the log path if it does not already exist
    $LogsPath = "$env:TEMP\osdcloud-logs"
    if (-not (Test-Path -Path $LogsPath)) {
        New-Item -Path $LogsPath -ItemType Directory -Force | Out-Null
    }
    ipconfig | Out-File $LogsPath\ipconfig.txt -Width 4096 -Force
    #=================================================
    # Create WMI Log Files
    $WmiLogsPath = "$env:TEMP\osdcloud-logs-wmi"
    if (-not (Test-Path -Path $WmiLogsPath)) {
        New-Item -Path $WmiLogsPath -ItemType Directory -Force | Out-Null
    }
    #=================================================
    # Win32_BaseBoard
    $classWin32BaseBoard = Get-CimInstance -ClassName Win32_BaseBoard | Select-Object -Property *
    $classWin32BaseBoard | Out-File $WmiLogsPath\Win32_BaseBoard.txt -Width 4096 -Force
    #=================================================
    # Win32_Battery
    $classWin32Battery = Get-CimInstance -ClassName Win32_Battery | Select-Object -Property *
    if ($classWin32Battery) {
        $classWin32Battery | Out-File $WmiLogsPath\Win32_Battery.txt -Width 4096 -Force
    }
    #=================================================
    # Win32_BIOS
    $classWin32BIOS = Get-CimInstance -ClassName Win32_BIOS | Select-Object -Property *
    $classWin32BIOS | Out-File $WmiLogsPath\Win32_BIOS.txt -Width 4096 -Force
    #=================================================
    # CIM_ComputerSystem
    $classCimComputerSystem = Get-CimInstance -ClassName Cim_ComputerSystem | Select-Object -Property *
    $classCimComputerSystem | Out-File $WmiLogsPath\Cim_ComputerSystem.txt -Width 4096 -Force
    #=================================================
    # Win32_ComputerSystem
    $classWin32ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property *
    $classWin32ComputerSystem | Out-File $WmiLogsPath\Win32_ComputerSystem.txt -Width 4096 -Force
    #=================================================
    # Win32_ComputerSystemProduct
    $classWin32ComputerSystemProduct = Get-CimInstance -ClassName Win32_ComputerSystemProduct | Select-Object -Property *
    $classWin32ComputerSystemProduct | Out-File $WmiLogsPath\Win32_ComputerSystemProduct.txt -Width 4096 -Force
    #=================================================
    # Details
    $BaseBoardProduct = $classWin32BaseBoard.Product.Trim()
    $ComputerSystemSKU = $classCimComputerSystem.SystemSKUNumber
    $ComputerSystemFamily = $classWin32ComputerSystem.SystemFamily.Trim()
    $ComputerManufacturer = $classWin32ComputerSystem.Manufacturer.Trim()
    $ComputerManufacturerAlias = $classWin32ComputerSystem.Manufacturer.Trim()
    $ComputerModel = $classWin32ComputerSystem.Model.Trim()
    $ComputerModelAlias = $classWin32ComputerSystem.Model.Trim()
    $ComputerProduct = $classWin32ComputerSystemProduct.Version.Trim()
    $ComputerProductAlias = $classWin32ComputerSystemProduct.Version.Trim()
    #=================================================
    # Normalize Aliases for Known Manufacturers and Models
    switch -Regex ($ComputerManufacturerAlias) {
        'Dell' {
            $ComputerManufacturerAlias = 'Dell'
            $ComputerProductAlias = $ComputerSystemSKU
            break
        }
        'Lenovo' {
            $ComputerManufacturerAlias = 'Lenovo'
            $ComputerModelAlias = $ComputerProduct
            if (-not [string]::IsNullOrWhiteSpace($ComputerModel) -and $ComputerModel.Length -ge 4) {
                $ComputerProductAlias = $ComputerModel.Substring(0, 4)
            }
            else {
                $ComputerProductAlias = $ComputerModel
            }
            break
        }
        'Hewlett|Packard|^HP$' {
            $ComputerManufacturerAlias = 'HP'
            $ComputerProductAlias = $BaseBoardProduct
            break
        }
        'Microsoft' {
            $ComputerManufacturerAlias = 'Microsoft'
            $ComputerProductAlias = $ComputerSystemSKU
            break
        }
        'Panasonic' { $ComputerManufacturerAlias = 'Panasonic'; break }
        'to be filled' { $ComputerManufacturerAlias = 'OEM'; break }
    }

    if ([string]::IsNullOrWhiteSpace($ComputerManufacturerAlias) -or $ComputerManufacturerAlias -match '^to be filled$') {
        $ComputerManufacturerAlias = 'OEM'
    }
    if ([string]::IsNullOrWhiteSpace($ComputerModelAlias) -or $ComputerModelAlias -match '^to be filled$') {
        $ComputerModelAlias = 'OEM'
    }
    if ([string]::IsNullOrWhiteSpace($ComputerProductAlias)) {
        $ComputerProductAlias = 'Unknown'
    }
    #=================================================
    # Disk Information
    $Win32DiskDrive = Get-CimInstance -ClassName Win32_DiskDrive | Select-Object -Property *
    $Win32DiskDrive | Out-File $WmiLogsPath\Win32_DiskDrive.txt -Width 4096 -Force

    foreach ($Item in $Win32DiskDrive) {
        Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Disk: $($Item.Model) [$($Item.DeviceID)]"
    }
    #=================================================
    # Win32_Environment
    $Win32Environment = Get-CimInstance -ClassName Win32_Environment | Select-Object -Property * | Sort-Object Name
    $Win32Environment | Where-Object { $_.SystemVariable -eq $true } | Select-Object -Property Name, VariableValue | Out-File $WmiLogsPath\Win32_Environment-System.txt -Width 4096 -Force
    #=================================================
    # Win32_NetworkAdapter
    $Win32NetworkAdapter = Get-CimInstance -ClassName Win32_NetworkAdapter | Select-Object -Property *
    $Win32NetworkAdapter | Out-File $WmiLogsPath\Win32_NetworkAdapter.txt -Width 4096 -Force

    $Win32NetworkAdapterGuid = $Win32NetworkAdapter | Where-Object { $null -ne $_.GUID }
    if ($Win32NetworkAdapterGuid) {
        foreach ($Item in $Win32NetworkAdapterGuid) {
            Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] NetAdapter: $($Item.Name) [$($Item.MACAddress)]"
        }
    }
    #=================================================
    # Win32_NetworkAdapterConfiguration
    $Win32NetworkAdapterConfiguration = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true } | Select-Object -Property *
    $Win32NetworkAdapterConfiguration | Out-File $WmiLogsPath\Win32_NetworkAdapterConfiguration.txt -Width 4096 -Force

    foreach ($Item in $Win32NetworkAdapterConfiguration) {
        Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] NetAdapterConfig: $($Item.IPAddress) [$($Item.Description)]"
    }
    $NetIPAddress = @()
    $NetMacAddress = @()
    $NetGateways = @()
    $Win32NetworkAdapterConfiguration | ForEach-Object {
        $_.IPAddress | ForEach-Object { $NetIPAddress += $_ }
        $_.MacAddress | ForEach-Object { $NetMacAddress += $_ }
        $_.DefaultIPGateway | ForEach-Object { $NetGateways += $_ }
    }
    #=================================================
    # Win32_OperatingSystem
    $Win32OperatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -Property *
    $Win32OperatingSystem | Out-File $WmiLogsPath\Win32_OperatingSystem.txt -Width 4096 -Force
    #=================================================
    # Win32_PnPEntityError
    $Win32PnPEntityError = Get-CimInstance -ClassName Win32_PnPEntity | Select-Object -Property * | Where-Object { $_.Status -eq 'Error' } | Sort-Object HardwareID -Unique | Sort-Object Name
    $Win32PnPEntityError | Out-File $WmiLogsPath\Win32_PnPEntityError.txt -Width 4096 -Force
    #=================================================
    # Win32_Processor
    $Win32Processor = Get-CimInstance -ClassName Win32_Processor | Select-Object -Property *
    $Win32Processor | Out-File $WmiLogsPath\Win32_Processor.txt -Width 4096 -Force
    foreach ($Item in $Win32Processor) {
        Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Processor: $($Item.Name) [$($Item.NumberOfLogicalProcessors) Logical]"
    }
    #=================================================
    # Win32_SystemEnclosure
    $Win32SystemEnclosure = Get-CimInstance -ClassName Win32_SystemEnclosure | Select-Object -Property *
    $Win32SystemEnclosure | Out-File $WmiLogsPath\Win32_SystemEnclosure.txt -Width 4096 -Force
    #=================================================
    # Win32_SystemTimeZone
    $Win32SystemTimeZone = Get-CimInstance -ClassName Win32_SystemTimeZone | Select-Object -Property *
    $Win32SystemTimeZone | Out-File $WmiLogsPath\Win32_SystemTimeZone.txt -Width 4096 -Force
    #=================================================
    # Win32_TimeZone
    $Win32TimeZone = Get-CimInstance -ClassName Win32_TimeZone | Select-Object -Property *
    $Win32TimeZone | Out-File $WmiLogsPath\Win32_TimeZone.txt -Width 4096 -Force
    #=================================================
    # IsOnBattery
    [System.Boolean]$IsOnBattery = ($classWin32Battery.BatteryStatus -contains 1)
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] IsOnBattery: $IsOnBattery"
    #=================================================
    # IsUEFI
    [System.Boolean]$IsUEFI = $false
    if ($env:firmware_type -eq 'UEFI') {
        $IsUEFI = $true
    }
    if ($env:firmware_type -eq 'Legacy') {
        $IsUEFI = $false
    }
    elseif ($IsWinPE) {
        Start-Process -WindowStyle Hidden -FilePath wpeutil.exe -ArgumentList ('updatebootinfo') -Wait
        $IsUEFI = (Get-ItemProperty -Path HKLM:\System\CurrentControlSet\Control).PEFirmwareType -eq 2
    }
    else {
        if ($null -eq (Get-ItemProperty HKLM:\System\CurrentControlSet\Control\SecureBoot\State -ErrorAction SilentlyContinue)) {
            $IsUEFI = $false
        }
        else {
            $IsUEFI = $true
        }
    }
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] IsUEFI: $IsUEFI"
    #=================================================
    # IsVM
    [System.Boolean]$IsVM = $false
    $vmDetectionSources = @(
        $classWin32ComputerSystem.Model,
        $classWin32ComputerSystem.Manufacturer,
        $classWin32ComputerSystem.SystemFamily,
        $classWin32ComputerSystemProduct.Name,
        $classWin32ComputerSystemProduct.Vendor,
        $classWin32ComputerSystemProduct.Version
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    $vmPattern = '(?i)(virtual machine|vmware|hyper-v|hyperv|kvm|qemu|xen|virtualbox|bhyve|parallels|gce|google compute engine|amazon ec2|azure|bochs|openstack|ovirt|rhev|kubevirt|ahv|nutanix)'
    [System.Boolean]$IsVM = ($vmDetectionSources -join ' ') -match $vmPattern
    #=================================================
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] ComputerProductAlias: $ComputerProductAlias"
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] ComputerSystemSKU: $($classWin32ComputerSystem.SystemSKUNumber)"
    #=================================================
    # ChassisType
    $IsDesktop = $false
    $IsLaptop = $false
    $IsServer = $false
    $IsSFF = $false
    $IsTablet = $false
    $ChassisType = $Win32SystemEnclosure | ForEach-Object {
        if ($_.ChassisTypes[0] -in "8", "9", "10", "11", "12", "14", "18", "21") { $IsLaptop = $true; "Laptop" }
        if ($_.ChassisTypes[0] -in "3", "4", "5", "6", "7", "15", "16") { $IsDesktop = $true; "Desktop" }
        if ($_.ChassisTypes[0] -in "23") { $IsServer = $true; "Server" }
        if ($_.ChassisTypes[0] -in "34", "35", "36") { $IsSFF = $true; "Small Form Factor" }
        if ($_.ChassisTypes[0] -in "13", "31", "32", "30") { $IsTablet = $true; "Tablet" }
    }
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] ChassisType: $($ChassisType)"
    #=================================================
    # TotalPhysicalMemoryGB
    $TotalPhysicalMemoryGB = [math]::Round(
        $classWin32ComputerSystem.TotalPhysicalMemory / 1GB,
        0,
        [System.MidpointRounding]::AwayFromZero
    )
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Memory: $TotalPhysicalMemoryGB GB"
    if ($TotalPhysicalMemoryGB -lt 6) {
        Write-Warning "[$(Get-Date -format s)] OSDCloud Workflow requires at least 8 GB of memory to function properly. Errors are expected."
    }
    #=================================================
    $Win32Tpm = @{}
    try {
        $Win32Tpm = Get-CimInstance -Namespace 'ROOT\cimv2\Security\MicrosoftTpm' -ClassName Win32_Tpm -ErrorAction Stop
        $Win32Tpm | Out-File $WmiLogsPath\Win32_Tpm.txt -Width 4096 -Force
    
        $DeviceTpmIsActivated = $($Win32Tpm.IsActivated_InitialValue)
        $DeviceTpmIsEnabled = $($Win32Tpm.IsEnabled_InitialValue)
        $DeviceTpmIsOwned = $($Win32Tpm.IsOwned_InitialValue)
        $DeviceTpmManufacturerIdTxt = $($Win32Tpm.ManufacturerIdTxt)
        $DeviceTpmManufacturerVersion = $($Win32Tpm.ManufacturerVersion)
        $DeviceTpmSpecVersion = $($Win32Tpm.SpecVersion)
    }
    catch {}
    #=================================================
    #   Pass Variables to OSDCloudDevice
    #=================================================
    $global:OSDCloudDevice = $null
    $global:OSDCloudDevice = [ordered]@{
        ComputerName              = $classWin32ComputerSystem.Name
        BaseBoardProduct          = [System.String]$BaseBoardProduct
        BiosReleaseDate           = [System.String]$classWin32BIOS.ReleaseDate
        BiosVersion               = [System.String]$classWin32BIOS.SMBIOSBIOSVersion
        ChassisType               = [System.String]$ChassisType
        ComputerManufacturer      = [System.String]$ComputerManufacturer
        ComputerManufacturerAlias = [System.String]$ComputerManufacturerAlias
        ComputerModel             = [System.String]$ComputerModel
        ComputerModelAlias        = [System.String]$ComputerModelAlias
        ComputerProduct           = [System.String]$ComputerProduct
        ComputerProductAlias      = [System.String]$ComputerProductAlias
        ComputerSystemFamily      = [System.String]$ComputerSystemFamily
        ComputerSystemSKU         = [System.String]$ComputerSystemSKU
        IsAutopilotReady          = [System.Boolean]$false
        IsDesktop                 = [System.Boolean]$IsDesktop
        IsLaptop                  = [System.Boolean]$IsLaptop
        IsOnBattery               = [System.Boolean]$IsOnBattery
        IsServer                  = [System.Boolean]$IsServer
        IsSFF                     = [System.Boolean]$IsSFF
        IsTablet                  = [System.Boolean]$IsTablet
        IsTpmReady                = [System.Boolean]$false
        IsVM                      = [System.Boolean]$IsVM
        IsUEFI                    = [System.Boolean]$IsUEFI
        NetGateways               = $NetGateways
        NetIPAddress              = $NetIPAddress
        NetMacAddress             = $NetMacAddress
        OSArchitecture            = $Win32OperatingSystem.OSArchitecture
        OSVersion                 = $Win32OperatingSystem.Version
        ProcessorArchitecture     = $env:PROCESSOR_ARCHITECTURE
        SerialNumber              = ($classWin32BIOS.SerialNumber).Trim()
        TimeZone                  = $Win32TimeZone.StandardName
        TotalPhysicalMemoryGB     = $TotalPhysicalMemoryGB
        TpmIsActivated            = $DeviceTpmIsActivated
        TpmIsEnabled              = $DeviceTpmIsEnabled
        TpmIsOwned                = $DeviceTpmIsOwned
        TpmManufacturerIdTxt      = $DeviceTpmManufacturerIdTxt
        TpmManufacturerVersion    = $DeviceTpmManufacturerVersion
        TpmSpecVersion            = $DeviceTpmSpecVersion
        UUID                      = $classWin32ComputerSystemProduct.UUID
    }
    #=================================================
    if ($null -eq $Win32Tpm) {
        Write-Host -ForegroundColor Yellow "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] TPM is not supported on this device."
        Write-Host -ForegroundColor Yellow "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Autopilot is not supported on this device."
    }
    elseif ($Win32Tpm.SpecVersion) {
        if ($null -eq $Win32Tpm.SpecVersion) {
            Write-Host -ForegroundColor Yellow "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] TPM did not contain a readable version on this device."
            Write-Host -ForegroundColor Yellow "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Autopilot is not supported on this device."
        }

        $majorVersion = $Win32Tpm.SpecVersion.Split(',')[0] -as [int]
        if ($majorVersion -lt 2) {
            Write-Host -ForegroundColor Yellow "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] TPM version is lower than 2.0 on this device."
            Write-Host -ForegroundColor Yellow "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Autopilot is not supported on this device."
        }
        else {
            $global:OSDCloudDevice.IsAutopilotReady = $true
            $global:OSDCloudDevice.IsTpmReady = $true
            Write-Host -ForegroundColor DarkGreen "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] TPM 2.0 is supported on this device."
            Write-Host -ForegroundColor DarkGreen "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Autopilot is supported on this device."
        }
    }
    else {
        Write-Host -ForegroundColor Yellow "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] TPM is not supported on this device."
        Write-Host -ForegroundColor Yellow "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Autopilot is not supported on this device."
    }
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
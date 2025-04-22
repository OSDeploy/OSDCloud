function Initialize-OSDCloudGather {
    [CmdletBinding()]
    param ()
    #=================================================
    $Error.Clear()
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Start"
    $ModuleName = $($MyInvocation.MyCommand.Module.Name)
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] ModuleName: $ModuleName"
    $ModuleBase = $($MyInvocation.MyCommand.Module.ModuleBase)
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] ModuleBase: $ModuleBase"
    $ModuleVersion = $($MyInvocation.MyCommand.Module.Version)
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] ModuleVersion: $ModuleVersion"
    #=================================================
    #region Device Properties
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Gathering Device Information"

    # Create the log path if it does not already exist
    $LogsPath = "$env:TEMP\osdcloud-logs"
    if (-NOT (Test-Path -Path $LogsPath)) {
        New-Item -Path $LogsPath -ItemType Directory -Force | Out-Null
    }

    # Export Driver Error Information
    $Win32PnPEntityError = Get-CimInstance -ClassName Win32_PnPEntity | Select-Object -Property * | Where-Object { $_.Status -eq 'Error' } | Sort-Object HardwareID -Unique | Sort-Object Name
    $Win32PnPEntityError | Out-File $LogsPath\Win32_PnPEntityError.txt -Width 4096 -Force

    # Operating System Information
    $Win32OperatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -Property *
    $Win32OperatingSystem | Out-File $LogsPath\Win32_OperatingSystem.txt -Width 4096 -Force

    # Computer System Information
    $Win32ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property *
    $Win32ComputerSystem | Out-File $LogsPath\Win32_ComputerSystem.txt -Width 4096 -Force
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] ComputerName: $($Win32ComputerSystem.Name)"
    $IsWinPE = $false
    $IsWinOS = $false
    $IsClientOS = $false
    $IsServerOS = $false
    $IsServerCoreOS = $false
    if ($env:SystemDrive -eq 'X:') {
        $IsWinPE = $true
    }
    else {
        if ($Win32ComputerSystem.Roles -match 'Server_NT' -or $Win32ComputerSystem.Roles -match 'LanmanNT') {
            $IsWinOS = $true
            $IsServerOS = $true
            if (!(Test-Path "$($env:windir)\explorer.exe")) {
                $IsServerCoreOS = $true
            }
        }
        else {
            $IsWinOS = $true
            $IsClientOS = $true
        }
    }
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] IsWinPE: [$IsWinPE]"
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] IsWinOS: [$IsWinOS]"
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] IsClientOS: [$IsClientOS]"
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] IsServerOS: [$IsServerOS]"
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] IsServerCoreOS: [$IsServerCoreOS]"

    # Virtual Machine Information
    [System.Boolean]$IsVM = ($Win32ComputerSystem.Model -match 'Virtual') -or ($Win32ComputerSystem.Model -match 'VMware')
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] IsVM: $IsVM"

    # Processor Information
    $Architecture = $Env:PROCESSOR_ARCHITECTURE
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Architecture: $Architecture"

    # Battery Information
    $Win32Battery = Get-CimInstance -ClassName Win32_Battery | Select-Object -Property *
    $Win32Battery | Out-File $LogsPath\Win32_Battery.txt -Width 4096 -Force
    [System.Boolean]$IsOnBattery = ($Win32Battery.BatteryStatus -contains 1)
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] IsOnBattery: $IsOnBattery"
    
    # Bios Information
    $Win32BIOS = Get-CimInstance -ClassName Win32_BIOS | Select-Object -Property *
    $Win32BIOS | Out-File $LogsPath\Win32_BIOS.txt -Width 4096 -Force
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Bios Version: $($Win32BIOS.SMBIOSBIOSVersion)"
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Bios ReleaseDate: $($Win32BIOS.ReleaseDate)"

    $Win32BaseBoard = Get-CimInstance -ClassName Win32_BaseBoard | Select-Object -Property *
    $Win32BaseBoard | Out-File $LogsPath\Win32_BaseBoard.txt -Width 4096 -Force
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Bios BaseBoard Product: $($Win32BaseBoard.Product)"

    # Computer Hardware Information
    if (!($ComputerManufacturer)) {
        $ComputerManufacturer = Get-MyComputerManufacturer -Brief
    }
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] ComputerManufacturer: $ComputerManufacturer"

    if (!($ComputerModel)) {
        $ComputerModel = Get-MyComputerModel -Brief
    }
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] ComputerModel: $ComputerModel"

    if (!($ComputerProduct)) {
        $ComputerProduct = Get-MyComputerProduct
    }
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] ComputerProduct: $ComputerProduct"
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] ComputerSystemSKU: $($Win32ComputerSystem.SystemSKUNumber)"

    $IsDesktop = $false
    $IsLaptop = $false
    $IsServer = $false
    $IsSFF = $false
    $IsTablet = $false
    $Win32SystemEnclosure = (Get-CimInstance -ClassName Win32_SystemEnclosure) | ForEach-Object {
        if ($_.ChassisTypes[0] -in "8", "9", "10", "11", "12", "14", "18", "21") { $IsLaptop = $true; "Laptop" }
        if ($_.ChassisTypes[0] -in "3", "4", "5", "6", "7", "15", "16") { $IsDesktop = $true; "Desktop" }
        if ($_.ChassisTypes[0] -in "23") { $IsServer = $true; "Server" }
        if ($_.ChassisTypes[0] -in "34", "35", "36") { $IsSFF = $true; "Small Form Factor" }
        if ($_.ChassisTypes[0] -in "13", "31", "32", "30") { $IsTablet = $true; "Tablet" }
    }
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] ChassisType: $($Win32SystemEnclosure)"

    # Disk Information
    $Win32DiskDrive = Get-CimInstance -ClassName Win32_DiskDrive | Select-Object -Property *
    $Win32DiskDrive | Out-File $LogsPath\Win32_DiskDrive.txt -Width 4096 -Force
    foreach ($Item in $Win32DiskDrive) {
        Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Disk: $($Item.Model) [$($Item.DeviceID)]"
    }

    # BDE Information
    if ($IsWinPE) {
        $IsBDE = $false
    }
    else {
        $IsBDE = $false
        $BitlockerEncryptionType = $null
        $BitlockerEncryptionMethod = $null
        $EncryptionMethods = @{
            0 = "UNSPECIFIED"
            1 = 'AES_128_WITH_DIFFUSER'
            2 = "AES_256_WITH_DIFFUSER"
            3 = 'AES_128'
            4 = "AES_256"
            5 = 'HARDWARE_ENCRYPTION'
            6 = "AES_256"
            7 = "XTS_AES_256" 
        }
        $EncryptedVolumes = Get-Ciminstance -Namespace 'ROOT\cimv2\Security\MicrosoftVolumeEncryption' -ClassName Win32_EncryptableVolume -ErrorAction SilentlyContinue | Select-Object -Property *
        if ($EncryptedVolumes) {
            foreach ($EncryptedVolume in $EncryptedVolumes) {
                if ($EncryptedVolume.ProtectionStatus -ne 0) {
                    $EncryptionMethod = Get-CimInstance -Namespace 'ROOT\cimv2\Security\MicrosoftVolumeEncryption' -ClassName Win32_EncryptableVolume -Filter "PersistentVolumeID like `"$($EncryptedVolume.PersistentVolumeID)`"" -ErrorAction SilentlyContinue  | Invoke-CimMethod -MethodName GetEncryptionMethod
                    if ($EncryptionMethods.ContainsKey([int]$EncryptionMethod.EncryptionMethod)) {
                        $BitlockerEncryptionMethod = $EncryptionMethods[[int]$EncryptionMethod.EncryptionMethod]
                    }
                    $EncryptionType = Get-CimInstance -Namespace 'ROOT\cimv2\Security\MicrosoftVolumeEncryption' -ClassName Win32_EncryptableVolume -Filter "PersistentVolumeID like `"$($EncryptedVolume.PersistentVolumeID)`"" -ErrorAction SilentlyContinue  | Invoke-CimMethod -MethodName GetConversionStatus
                    if ($EncryptionType.ReturnValue -eq 0) {
                        if ($EncryptionType.EncryptionFlags -eq 1) {
                            $BitlockerEncryptionType = "Used Space Only Encrypted"
                        }
                        else {
                            $BitlockerEncryptionType = "Full Disk Encryption"
                        }
                    }
                    else {
                        $BitlockerEncryptionType = "Unknown"
                    }
                    $IsBDE = $true
                }
                # TODO - Add to InitializeOSDCloudGather
                #$BitlockerEncryptionMethod
                #$BitlockerEncryptionType
            }
        }
    }

    # Memory Information
    $TotalPhysicalMemoryGB = $([math]::Round($Win32ComputerSystem.TotalPhysicalMemory / 1024 / 1024 / 1024))
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Memory: $TotalPhysicalMemoryGB GB"
    if ($TotalPhysicalMemoryGB -lt 6) {
        Write-Warning "[$(Get-Date -format G)] OSDCloud Workflow requires at least 8 GB of memory to function properly. Errors are expected."
    }

    # Network Adapter Configuration Information
    $Win32NetworkAdapterConfiguration = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true } | Select-Object -Property *
    $Win32NetworkAdapterConfiguration | Out-File $LogsPath\Win32_NetworkAdapterConfiguration.txt -Width 4096 -Force
    foreach ($Item in $Win32NetworkAdapterConfiguration) {
        Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] NetAdapterConfig: $($Item.IPAddress) [$($Item.Description)]"
    }
    $ipList = @()
    $macList = @()
    $gwList = @()
    $Win32NetworkAdapterConfiguration | ForEach-Object {
        $_.IPAddress | ForEach-Object { $ipList += $_ }
        $_.MacAddress | ForEach-Object { $macList += $_ }
        $_.DefaultIPGateway | ForEach-Object { $gwList += $_ }
    }

    # Network Adapter Information
    $Win32NetworkAdapter = Get-CimInstance -ClassName Win32_NetworkAdapter | Select-Object -Property *
    $Win32NetworkAdapter | Out-File $LogsPath\Win32_NetworkAdapter.txt -Width 4096 -Force
    $Win32NetworkAdapterGuid = $Win32NetworkAdapter | Where-Object { $null -ne $_.GUID }
    if ($Win32NetworkAdapterGuid) {
        foreach ($Item in $Win32NetworkAdapterGuid) {
            Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] NetAdapter: $($Item.Name) [$($Item.MACAddress)]"
        }
    }
    
    # Processor Information
    $Win32Processor = Get-CimInstance -ClassName Win32_Processor | Select-Object -Property *
    $Win32Processor | Out-File $LogsPath\Win32_Processor.txt -Width 4096 -Force
    foreach ($Item in $Win32Processor) {
        Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Processor: $($Item.Name) [$($Item.NumberOfLogicalProcessors) Logical]"
    }

    $SerialNumber = Get-MyBiosSerialNumber
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] SerialNumber: $SerialNumber"

    #endregion
    #=================================================
    $Win32Tpm = @{}
    try {
        $Win32Tpm = Get-CimInstance -Namespace 'ROOT\cimv2\Security\MicrosoftTpm' -ClassName Win32_Tpm -ErrorAction Stop
        
        $DeviceTpmIsActivated = $($Win32Tpm.IsActivated_InitialValue)
        $DeviceTpmIsEnabled = $($Win32Tpm.IsEnabled_InitialValue)
        $DeviceTpmIsOwned = $($Win32Tpm.IsOwned_InitialValue)
        $DeviceTpmManufacturerIdTxt = $($Win32Tpm.ManufacturerIdTxt)
        $DeviceTpmManufacturerVersion = $($Win32Tpm.ManufacturerVersion)
        $DeviceTpmSpecVersion = $($Win32Tpm.SpecVersion)
    }
    catch {}
    #=================================================
    #   Pass Variables to InitializeOSDCloudGather
    #=================================================
    $global:InitializeOSDCloudGather = $null
    $global:InitializeOSDCloudGather = [ordered]@{
        Architecture                = $Architecture
        BiosReleaseDate             = $Win32BIOS.ReleaseDate
        BiosVersion                 = $Win32BIOS.SMBIOSBIOSVersion
        ComputerManufacturer        = [System.String]$ComputerManufacturer
        ComputerModel               = [System.String]$ComputerModel
        ComputerName                = $Win32ComputerSystem.Name
        ComputerProduct             = [System.String]$ComputerProduct
        ComputerSystemSKUNumber     = $Win32ComputerSystem.SystemSKUNumber
        ChassisType                 = $Win32SystemEnclosure
        IsWinPE                     = $IsWinPE
        IsWinOS                     = $IsWinOS
        IsClientOS                  = $IsClientOS
        IsServerOS                  = $IsServerOS
        IsServerCoreOS              = $IsServerCoreOS
        IsVM                        = [System.Boolean]$IsVM
        IsDesktop                   = [System.Boolean]$IsDesktop
        IsLaptop                    = [System.Boolean]$IsLaptop
        IsServer                    = [System.Boolean]$IsServer
        IsSFF                       = [System.Boolean]$IsSFF
        IsTablet                    = [System.Boolean]$IsTablet
        IsAutopilotReady            = [System.Boolean]$false
        IsOnBattery                 = [System.Boolean]$IsOnBattery
        IsTpmReady                  = [System.Boolean]$false
        IsBDE                       = $IsBDE
        NetworkAdapter              = $Win32NetworkAdapter
        NetworkAdapterConfiguration = $Win32NetworkAdapterConfiguration
        IPAddress                   = $ipList
        MacAddress                  = $macList
        Gateways                    = $gwList
        OSArchitecture              = $Win32OperatingSystem.OSArchitecture
        OSVersion                   = $Win32OperatingSystem.Version
        SerialNumber                = $SerialNumber
        TotalPhysicalMemoryGB       = $TotalPhysicalMemoryGB
        TpmIsActivated              = $DeviceTpmIsActivated
        TpmIsEnabled                = $DeviceTpmIsEnabled
        TpmIsOwned                  = $DeviceTpmIsOwned
        TpmManufacturerIdTxt        = $DeviceTpmManufacturerIdTxt
        TpmManufacturerVersion      = $DeviceTpmManufacturerVersion
        TpmSpecVersion              = $DeviceTpmSpecVersion
        Win32Tpm                    = $Win32Tpm
    }
    #=================================================
    if ($null -eq $Win32Tpm) {
        Write-Host -ForegroundColor Yellow "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] TPM is not supported on this device."
            Write-Host -ForegroundColor Yellow "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Autopilot is not supported on this device."
    }
    elseif ($Win32Tpm.SpecVersion) {
        if ($null -eq $Win32Tpm.SpecVersion) {
            Write-Host -ForegroundColor Yellow "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] TPM did not contain a readable version on this device."
            Write-Host -ForegroundColor Yellow "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Autopilot is not supported on this device."
        }

        $majorVersion = $Win32Tpm.SpecVersion.Split(',')[0] -as [int]
        if ($majorVersion -lt 2) {
            Write-Host -ForegroundColor Yellow "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] TPM version is lower than 2.0 on this device."
            Write-Host -ForegroundColor Yellow "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Autopilot is not supported on this device."
        }
        else {
            $global:InitializeOSDCloudGather.IsAutopilotReady = $true
            $global:InitializeOSDCloudGather.IsTpmReady = $true
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] TPM 2.0 is supported on this device."
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Autopilot is supported on this device."
        }
    }
    else {
        Write-Host -ForegroundColor Yellow "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] TPM is not supported on this device."
            Write-Host -ForegroundColor Yellow "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Autopilot is not supported on this device."
    }
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
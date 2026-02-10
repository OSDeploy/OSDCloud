function Invoke-OSDCloudWorkflowTask {
    [CmdletBinding()]
    param (
        [switch]
        $Test
    )
    #=================================================
    $Error.Clear()
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    $ModuleName = $($MyInvocation.MyCommand.Module.Name)
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] ModuleName: $ModuleName"
    $ModuleBase = $($MyInvocation.MyCommand.Module.ModuleBase)
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] ModuleBase: $ModuleBase"
    $ModuleVersion = $($MyInvocation.MyCommand.Module.Version)
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] ModuleVersion: $ModuleVersion"
    #=================================================
    # Set global variables
    [System.String]$global:Architecture = $OSDCloudDevice.ProcessorArchitecture
    [System.Boolean]$global:IsOnBattery = $OSDCloudDevice.IsOnBattery
    [System.Boolean]$global:IsVM = $OSDCloudDevice.IsVM
    [System.Boolean]$global:IsWinPE = $($env:SystemDrive -eq 'X:')
    #=================================================
    $global:OSDCloudWorkflowInvoke = $null
    $global:OSDCloudWorkflowInvoke = [ordered]@{
        Architecture          = $global:Architecture
        ComputerChassisType   = $OSDCloudDevice.ChassisType
        ComputerManufacturer  = $OSDCloudDevice.ComputerManufacturer
        ComputerModel         = $OSDCloudDevice.ComputerModel
        ComputerProduct       = $OSDCloudDevice.ComputerProduct
        ComputerSerialNumber  = $OSDCloudDevice.SerialNumber
        ComputerUUID          = (Get-WmiObject -Class Win32_ComputerSystemProduct).UUID
        DriverPackName        = $OSDCloudWorkflowInit.DriverPackName
        DriverPackObject      = $OSDCloudWorkflowInit.DriverPackObject
        IsOnBattery           = $global:IsOnBattery
        IsVM                  = $global:IsVM
        IsWinPE               = $global:IsWinPE
        LogsPath              = "$env:TEMP\osdcloud-logs"
        OperatingSystem       = $OSDCloudWorkflowInit.OperatingSystem
        OperatingSystemObject = $OSDCloudWorkflowInit.OperatingSystemObject
        TimeEnd               = $null
        TimeSpan              = $null
        TimeStart             = [datetime](Get-Date)
    }
    #=================================================
    #region OSDCloud Live Analytics
    $eventName = 'osdcloud_deploy_test'
    function Send-OSDCloudLiveEvent {
        param(
            [Parameter(Mandatory)]
            [string]$EventName,
            [Parameter(Mandatory)]
            [string]$ApiKey,
            [Parameter(Mandatory)]
            [string]$DistinctId,
            [Parameter()]
            [hashtable]$Properties
        )

        try {
            $payload = [ordered]@{
                api_key     = $ApiKey
                event       = $EventName
                properties  = $Properties + @{
                    distinct_id = $DistinctId
                }
                timestamp   = (Get-Date).ToString('o')
            }

            $body = $payload | ConvertTo-Json -Depth 4 -Compress
            Invoke-RestMethod -Method Post `
                -Uri 'https://us.i.posthog.com/capture/' `
                -Body $body `
                -ContentType 'application/json' `
                -TimeoutSec 2 `
                -ErrorAction Stop | Out-Null

            Write-Verbose "[$(Get-Date -format s)] [OSDCloud] Event sent: $EventName"
        } catch {
            Write-Verbose "[$(Get-Date -format s)] [OSDCloud] Failed to send event: $($_.Exception.Message)"
        }
    }
    # UUID
    $deviceUUID = $global:OSDCloudWorkflowInvoke.ComputerUUID
    # Convert the UUID to a hash value to protect user privacyand ensure a consistent identifier across events
    $deviceUUIDHash = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($deviceUUID))).Replace("-", "")
    [string]$distinctId = $deviceUUIDHash
    if ([string]::IsNullOrWhiteSpace($distinctId)) {
        $distinctId = [System.Guid]::NewGuid().ToString()
    }
    # Device
    $deviceManufacturer = (Get-CimInstance -ClassName CIM_ComputerSystem -ErrorAction Stop).Manufacturer
    $deviceManufacturer = $deviceManufacturer -as [string]
    if ([string]::IsNullOrWhiteSpace($deviceManufacturer)) {
        $deviceManufacturer = 'OEM'
    } else {
        $deviceManufacturer = $deviceManufacturer.Trim()
    }
    $deviceModel = ((Get-CimInstance -ClassName CIM_ComputerSystem).Model).Trim()
    $deviceModel = $deviceModel -as [string]
    if ([string]::IsNullOrWhiteSpace($deviceModel)) {
        $deviceModel = 'OEM'
    } elseif ($deviceModel -match 'OEM|to be filled') {
        $deviceModel = 'OEM'
    }
    $deviceProduct = ((Get-CimInstance -ClassName Win32_BaseBoard).Product).Trim()
    $deviceSystemSKU = ((Get-CimInstance -ClassName CIM_ComputerSystem).SystemSKUNumber).Trim()
    $deviceVersion = ((Get-CimInstance -ClassName Win32_ComputerSystemProduct).Version).Trim()
    if ($deviceManufacturer -match 'Dell') {
        $deviceManufacturer = 'Dell'
        $deviceModelId = $deviceSystemSKU
    }
    if ($deviceManufacturer -match 'Hewlett|Packard|\bHP\b') {
        $deviceManufacturer = 'HP'
        $deviceModelId = $deviceProduct
    }
    if ($deviceManufacturer -match 'Lenovo') {
        $deviceManufacturer = 'Lenovo'
        $deviceModel = $deviceVersion
        $deviceModelId = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty Model).SubString(0, 4)
    }
    if ($deviceManufacturer -match 'Microsoft') {
        $deviceManufacturer = 'Microsoft'
        # Surface_Book or Surface_Pro_3
        $deviceModelId = $deviceSystemSKU
        # Surface Book or Surface Pro 3
        # $deviceProduct
    }
    if ($deviceManufacturer -match 'Panasonic') { $deviceManufacturer = 'Panasonic' }
    if ($deviceManufacturer -match 'OEM|to be filled') { $deviceManufacturer = 'OEM' }
    # Win32_ComputerSystem
    $deviceSystemFamily = ((Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Ignore).SystemFamily).Trim()
    # Win32_OperatingSystem
    # $osCaption = (Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Ignore).Caption
    # $osVersion = (Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Ignore).Version

    $computerInfo = Get-ComputerInfo -ErrorAction Ignore
    if ($env:SystemDrive -eq 'X:') {
        $deploymentPhase = 'WinPE'
        $osName = 'Microsoft WindowsPE'
    }
    else {
        $deploymentPhase = 'Windows'
        $osName = [string]$computerInfo.OsName
    }
    $eventProperties = @{
        deploymentPhase             = [string]$deploymentPhase
        deviceManufacturer          = [string]$deviceManufacturer
        deviceModel                 = [string]$deviceModel
        deviceModelId               = [string]$deviceModelId
        deviceProduct               = [string]$deviceProduct
        deviceVersion               = [string]$deviceVersion
        deviceSystemFamily          = [string]$deviceSystemFamily
        deviceSystemSKU             = [string]$deviceSystemSKU
        deviceSystemType            = [string]$computerInfo.CsPCSystemType
        biosFirmwareType            = [string]$computerInfo.BiosFirmwareType
        biosReleaseDate             = [string]$computerInfo.BiosReleaseDate
        biosSMBIOSBIOSVersion       = [string]$computerInfo.BiosSMBIOSBIOSVersion
        keyboardName                = [string](Get-CimInstance -ClassName Win32_Keyboard | Select-Object -ExpandProperty Name)
        keyboardLayout              = [string](Get-CimInstance -ClassName Win32_Keyboard | Select-Object -ExpandProperty Layout)
        winArchitecture             = [string]$env:PROCESSOR_ARCHITECTURE
        winBuildLabEx               = [string]$computerInfo.WindowsBuildLabEx
        winBuildNumber              = [string]$computerInfo.OsBuildNumber
        winCountryCode              = [string]$computerInfo.OsCountryCode
        winEditionId                = [string]$computerInfo.WindowsEditionId
        winInstallationType         = [string]$computerInfo.WindowsInstallationType
        winLanguage                 = [string]$computerInfo.OsLanguage
        winName                     = [string]$osName
        winTimeZone                 = [string]$computerInfo.TimeZone
        winVersion                  = [string]$computerInfo.OsVersion
        osdcloudModuleVersion       = [string]$ModuleVersion
        osdcloudWorkflowName        = [string]$global:OSDCloudWorkflowInit.WorkflowName
        osdcloudWorkflowTaskName    = [string]$global:OSDCloudWorkflowInit.WorkflowTaskName
        osdcloudDriverPackName      = [string]$global:OSDCloudWorkflowInit.DriverPackName
        osdcloudOSName              = [string]$global:OSDCloudWorkflowInit.OperatingSystemObject.OSName
        osdcloudOSVersion           = [string]$global:OSDCloudWorkflowInit.OperatingSystemObject.OSVersion
        osdcloudOSActivationStatus  = [string]$global:OSDCloudWorkflowInit.OperatingSystemObject.OSActivation
        osdcloudOSBuild             = [string]$global:OSDCloudWorkflowInit.OperatingSystemObject.OSBuild
        osdcloudOSBuildVersion      = [string]$global:OSDCloudWorkflowInit.OperatingSystemObject.OSBuildVersion
        osdcloudOSLanguageCode      = [string]$global:OSDCloudWorkflowInit.OperatingSystemObject.OSLanguageCode
    }
    $postApi = 'phc_2h7nQJCo41Hc5C64B2SkcEBZOvJ6mHr5xAHZyjPl3ZK'
    Send-OSDCloudLiveEvent -EventName $eventName -ApiKey $postApi -DistinctId $distinctId -Properties $eventProperties
    #=================================================
    if ($null -ne $global:OSDCloudWorkflowInit.WorkflowObject) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)]"
        
        foreach ($step in $global:OSDCloudWorkflowInit.WorkflowObject.steps) {
            # Set the current step in the global variable
            $global:OSDCloudWorkflowCurrentStep = $step
            #=================================================
            # Should we skip this step? (support both 'skip' and legacy 'disable')
            if (($step.skip -eq $true) -or ($step.disable -eq $true)) {
                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [Skip:True] $($step.name)"
                continue
            }
            #=================================================
            # Can we test this step in full Windows OS (not WinPE)?
            if (($global:IsWinPE -ne $true) -and ($step.testinfullos -ne $true)) {
                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [Skip:FullOS] $($step.name)"
                continue
            }
            #=================================================
            # Can we pause before this step?
            if ($step.pause -eq $true) {
                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [Pause:True] $($step.name)"
                Pause
            }
            #=================================================
            # Command or ScriptBlock
            $command = $null
            $commandline = $null
            if ($step.command) {
                $command = $step.command

                if (($command -is [string]) -and ($command.Contains(" "))) {
                    $commandline = $command
                }
                elseif (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
                    Write-Host -ForegroundColor DarkRed "[$(Get-Date -format s)] [Step command does not exist] $($step.command)"
                    continue
                }
            }
            elseif ($step.scriptblock) {
                $command = [scriptblock]::Create($step.scriptblock)
            }
            else {
                Write-Host -ForegroundColor DarkRed "[$(Get-Date -format s)] [Step does not contain a command] $($step.name)"
                continue
            }
            #=================================================
            # Arguments
            $arguments = @()
            if ($step.args) {
                # Only process if args is an array of strings, not an empty object
                if ($step.args -is [array]) {
                    [array]$arguments = @($step.args)
                    $arguments = $arguments | Where-Object { $_ -is [string] } | ForEach-Object { $_.Trim() } # Trim whitespace from arguments
                    $arguments = $arguments | Where-Object { $_ -ne "" } # Remove empty arguments
                }
            }
            #=================================================
            # Parameters
            $parameters = $null
            if ($step.parameters) {
                $parameters = $null
                $parameters = [ordered]@{}
                ($step.parameters).psobject.properties | ForEach-Object { $parameters[$_.Name] = $_.Value }
    
                if ($parameters.Count -eq 0) {
                    $parameters = $null
                }
            }

            # Execute
            if ($step.scriptblock) {
                Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] $($step.name) [ScriptBlock:$($step.scriptblock)]"
                if ($Test) { continue }
                & $command
            } elseif ($commandline) {
                Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] $($step.name)"
                if ($Test) { continue }
                # Parse the command line into a command and arguments to avoid Invoke-Expression
                $parseErrors = $null
                $tokens = [System.Management.Automation.PSParser]::Tokenize($commandline, [ref]$parseErrors)

                if ($parseErrors -and $parseErrors.Count -gt 0) {
                    Write-Error "Failed to parse command line for step '$($step.name)': $commandline"
                    continue
                }

                if (-not $tokens -or $tokens.Count -eq 0) {
                    Write-Error "Empty or invalid command line for step '$($step.name)': $commandline"
                    continue
                }

                # First token is the command; subsequent CommandArgument tokens are arguments
                $exeToken = $tokens | Where-Object { $_.Type -eq 'Command' } | Select-Object -First 1
                if (-not $exeToken) {
                    Write-Error "No executable command found in command line for step '$($step.name)': $commandline"
                    continue
                }

                $exe = $exeToken.Content
                $cmdArgs = @()
                foreach ($tok in $tokens) {
                    if ($tok -eq $exeToken) { continue }
                    if ($tok.Type -eq 'CommandArgument') {
                        $cmdArgs += $tok.Content
                    }
                }

                & $exe @cmdArgs
            } elseif ($command -and ($arguments.Count -ge 1) -and ($parameters.Count -ge 1)) {
                Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] $($step.name) [Arguments:$arguments]"
                ($parameters | Out-String).Trim()
                if ($Test) { continue }
                & $command @parameters @arguments
            } elseif ($command -and ($arguments.Count -ge 1)) {
                Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] $($step.name) [Arguments:$arguments]"
                if ($Test) { continue }
                & $command @arguments
            } elseif ($command -and ($parameters.Count -ge 1)) {
                Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] $($step.name)"
                ($parameters | Out-String).Trim()
                if ($Test) { continue }
                & $command @parameters
            } elseif ($command) {
                Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] $($step.name)"
                if ($Test) { continue }
                & $command
            } else {
                Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] No command to execute."
                continue
            }
        }
        # End of workflow steps
        Write-Host -ForegroundColor Green "[$(Get-Date -format s)] Workflow Task execution done."
        #=================================================
        # End the function
        $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
        Write-Verbose -Message $Message; Write-Debug -Message $Message
        #=================================================
    }
}
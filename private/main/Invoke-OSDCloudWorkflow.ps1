function Invoke-OSDCloudWorkflow {
    [CmdletBinding()]
    param (
        [switch]$Test
    )
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
    # OSDCloudWorkflowGather
    if (-not $global:OSDCloudWorkflowGather) {
        Initialize-OSDCloudWorkflowGather
    }
    #=================================================
    # OSDCloudWorkflowOS
    if (-not $global:OSDCloudWorkflowOS) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Importing OS Defaults $ModuleVersion"
        Initialize-OSDCloudWorkflowOS
    }
    #=================================================
    # OSDCloudWorkflowUser
    if (-not $global:OSDCloudWorkflowUser) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Importing User Settings $ModuleVersion"
        Initialize-OSDCloudWorkflowUser
    }
    #=================================================
    # OSDCloudWorkflowSteps
    if (-not $global:OSDCloudWorkflowSteps) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Importing Workflow Steps $ModuleVersion"
        Initialize-OSDCloudWorkflowSteps
    }
    #=================================================
    [System.String]$global:Architecture = $OSDCloudWorkflowGather.Architecture
    [System.Boolean]$global:IsOnBattery = $OSDCloudWorkflowGather.IsOnBattery
    [System.Boolean]$global:IsVM = $OSDCloudWorkflowGather.IsVM
    [System.Boolean]$global:IsWinPE = $($env:SystemDrive -eq 'X:')
    #=================================================
    $global:OSDCloudWorkflowInvoke = $null
    $global:OSDCloudWorkflowInvoke = [ordered]@{
        Architecture          = $global:Architecture
        ComputerChassisType   = $OSDCloudWorkflowGather.ChassisType
        ComputerManufacturer  = $OSDCloudWorkflowGather.ComputerManufacturer
        ComputerModel         = $OSDCloudWorkflowGather.ComputerModel
        ComputerProduct       = $OSDCloudWorkflowGather.ComputerProduct
        ComputerSerialNumber  = $OSDCloudWorkflowGather.SerialNumber
        ComputerUUID          = (Get-WmiObject -Class Win32_ComputerSystemProduct).UUID
        DriverPackName        = $OSDCloudWorkflowFrontend.DriverPackName
        DriverPackObject      = $OSDCloudWorkflowFrontend.DriverPackObject
        IsOnBattery           = $global:IsOnBattery
        IsVM                  = $global:IsVM
        IsWinPE               = $global:IsWinPE
        LogsPath              = "$env:TEMP\osdcloud-logs"
        OperatingSystem       = $OSDCloudWorkflowFrontend.OperatingSystem
        OperatingSystemObject = $OSDCloudWorkflowFrontend.OperatingSystemObject
        TimeEnd               = $null
        TimeSpan              = $null
        TimeStart             = [datetime](Get-Date)
    }
    #=================================================
    if ($null -ne $global:OSDCloudWorkflowSteps) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Starting OSDCloud Workflow"
        
        foreach ($step in $global:OSDCloudWorkflowSteps.steps) {
            # Set the current step in the global variable
            $global:OSDCloudWorkflowCurrentStep = $step

            # Skip the step if the skip condition is met
            if ($step.rules.skip -eq $true) {
                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($step.command)][Skip:True]"
                continue
            }       

            # Steps should only run in WinPE, but some steps can be configured to run in full OS
            if (($global:IsWinPE -ne $true) -and ($step.rules.runinfullos -ne $true)) {
                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($step.command)][Skip:FullOS]"
                continue
            }
            
            # Test the command
            if ($step.command) {
                $command = $step.command
                if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
                    Write-Host -ForegroundColor DarkRed "[$(Get-Date -format G)][Step command does not exist]"
                    continue
                }
            } else {
                Write-Host -ForegroundColor DarkRed "[$(Get-Date -format G)][Step does not contain a command]"
                continue
            }

            # Arguments
            if ($step.arguments) {
                [array]$arguments = @($step.arguments)
                $arguments = $arguments | ForEach-Object { $_.Trim() } # Trim whitespace from arguments
                $arguments = $arguments | Where-Object { $_ -ne "" } # Remove empty arguments
            }

            if ($step.parameters) {
                $parameters = $null
                $parameters = [ordered]@{}
                ($step.parameters).psobject.properties | ForEach-Object { $parameters[$_.Name] = $_.Value }
    
                if ($parameters.Count -eq 0) {
                    $parameters = $null
                }
            }

            # Execute
            
            if ($command -and ($arguments.Count -ge 1) -and ($parameters.Count -ge 1)) {
                Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format G)][$($step.command)][Arguments:$arguments]"
                ($parameters | Out-String).Trim()
                if ($Test) { continue }
                & $command @parameters @arguments
            } elseif ($command -and ($arguments.Count -ge 1)) {
                Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format G)][$($step.command)][Arguments:$arguments]"
                if ($Test) { continue }
                & $command @arguments
            } elseif ($command -and ($parameters.Count -ge 1)) {
                Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format G)][$($step.command)]"
                ($parameters | Out-String).Trim()
                if ($Test) { continue }
                & $command @parameters
            } elseif ($command) {
                Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format G)][$($step.command)]"
                if ($Test) { continue }
                & $command
            } else {
                Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format G)] No command to execute."
                continue
            }
            <#
                try {
                }
                catch {
                    Write-Host -ForegroundColor DarkRed "Error executing step: $($step.name). Error: $_"
                }
            #>
        }
        # End of workflow steps
        Write-Host "Workflow execution completed."
        #=================================================
        # End the function
        $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
        Write-Verbose -Message $Message; Write-Debug -Message $Message
        #=================================================
    }
}
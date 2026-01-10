function Invoke-OSDCloudWorkflow {
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
    [System.String]$global:Architecture = $OSDCloudWorkflowDevice.ProcessorArchitecture
    [System.Boolean]$global:IsOnBattery = $OSDCloudWorkflowDevice.IsOnBattery
    [System.Boolean]$global:IsVM = $OSDCloudWorkflowDevice.IsVM
    [System.Boolean]$global:IsWinPE = $($env:SystemDrive -eq 'X:')
    #=================================================
    $global:OSDCloudWorkflowInvoke = $null
    $global:OSDCloudWorkflowInvoke = [ordered]@{
        Architecture          = $global:Architecture
        ComputerChassisType   = $OSDCloudWorkflowDevice.ChassisType
        ComputerManufacturer  = $OSDCloudWorkflowDevice.ComputerManufacturer
        ComputerModel         = $OSDCloudWorkflowDevice.ComputerModel
        ComputerProduct       = $OSDCloudWorkflowDevice.ComputerProduct
        ComputerSerialNumber  = $OSDCloudWorkflowDevice.SerialNumber
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
    if ($null -ne $global:OSDCloudWorkflowInit.WorkflowObject) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Starting OSDCloud Workflow"
        
        foreach ($step in $global:OSDCloudWorkflowInit.WorkflowObject.steps) {
            # Set the current step in the global variable
            $global:OSDCloudWorkflowCurrentStep = $step

            # Skip the step if the skip condition is met
            if ($step.rules.skip -eq $true) {
                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($step.command)][Skip:True]"
                continue
            }

            # Steps should only run in WinPE, but some steps can be configured to run in full OS
            if (($global:IsWinPE -ne $true) -and ($step.rules.runinfullos -ne $true)) {
                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($step.command)][Skip:FullOS]"
                continue
            }

            # Delay
            if ($step.rules.delay -eq $true) {
                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($step.command)][Delay:True]"
                Start-Sleep -Seconds 10
            }
            
            # Test the command
            if ($step.command) {
                $command = $step.command
                if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
                    Write-Host -ForegroundColor DarkRed "[$(Get-Date -format s)] [Step command does not exist]"
                    continue
                }
            } else {
                Write-Host -ForegroundColor DarkRed "[$(Get-Date -format s)] [Step does not contain a command]"
                continue
            }

            # Arguments
            if ($step.args) {
                [array]$arguments = @($step.args)
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
                Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] [$($step.command)][Arguments:$arguments]"
                ($parameters | Out-String).Trim()
                if ($Test) { continue }
                & $command @parameters @arguments
            } elseif ($command -and ($arguments.Count -ge 1)) {
                Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] [$($step.command)][Arguments:$arguments]"
                if ($Test) { continue }
                & $command @arguments
            } elseif ($command -and ($parameters.Count -ge 1)) {
                Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] [$($step.command)]"
                ($parameters | Out-String).Trim()
                if ($Test) { continue }
                & $command @parameters
            } elseif ($command) {
                Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] [$($step.command)]"
                if ($Test) { continue }
                & $command
            } else {
                Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] No command to execute."
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
        Write-Host -ForegroundColor Green "[$(Get-Date -format s)] Workflow execution done."
        #=================================================
        # End the function
        $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
        Write-Verbose -Message $Message; Write-Debug -Message $Message
        #=================================================
    }
}
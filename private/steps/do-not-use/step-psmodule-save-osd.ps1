function step-powershell-savemodule-osd {
    [CmdletBinding()]
    param ()
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudWorkflowCurrentStep
    #=================================================
    #region Main
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)]"
    $PowerShellSavePath = 'C:\Program Files\WindowsPowerShell'

    if (-not (Test-Path "$PowerShellSavePath\Configuration")) {
        New-Item -Path "$PowerShellSavePath\Configuration" -ItemType Directory -Force | Out-Null
    }
    if (-not (Test-Path "$PowerShellSavePath\Modules")) {
        New-Item -Path "$PowerShellSavePath\Modules" -ItemType Directory -Force | Out-Null
    }
    if (-not (Test-Path "$PowerShellSavePath\Scripts")) {
        New-Item -Path "$PowerShellSavePath\Scripts" -ItemType Directory -Force | Out-Null
    }

    try {
        Save-Module -Name OSD -Path "$PowerShellSavePath\Modules" -Force -ErrorAction Stop
    }
    catch {
        Write-Warning "[$(Get-Date -format G)] Unable to Save-Module OSD to $PowerShellSavePath\Modules"
    }
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
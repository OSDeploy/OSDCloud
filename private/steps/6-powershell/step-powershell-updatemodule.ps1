function step-powershell-updatemodule {
    [CmdletBinding()]
    param ()
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudWorkflowCurrentStep
    #=================================================
    #region Main
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

    $ExistingModules = Get-ChildItem -Path "$PowerShellSavePath\Modules" -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer -eq $true } | Select-Object -ExpandProperty Name

    foreach ($Name in $ExistingModules) {
        $FindModule = Find-Module -Name $Name -ErrorAction SilentlyContinue
        if ($null -eq $FindModule) {
            # Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Unable to update $Name"
            continue
        }

        try {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Save-Module -Name $Name -Path `"$PowerShellSavePath\Modules`" -Force"
            Save-Module -Name $Name -Path "$PowerShellSavePath\Modules" -Force -ErrorAction Stop
        }
        catch {
            Write-Warning "[$(Get-Date -format s)] Save-Module failed: $Name"
        }
    }
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
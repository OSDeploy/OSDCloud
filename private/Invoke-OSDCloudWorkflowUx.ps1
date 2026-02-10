function Invoke-OSDCloudWorkflowUx {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name = 'default',

        $Path = "$($MyInvocation.MyCommand.Module.ModuleBase)\workflow"
    )
    #=================================================
    # Get module details
    $ModuleBase = $($MyInvocation.MyCommand.Module.ModuleBase)
    $ModuleVersion = $($MyInvocation.MyCommand.Module.Version)
    #=================================================
    if (-not ($global:OSDCloudInitialize)) {
        Initialize-DeployOSDCloud
    }

    $WorkflowSettingsUxPath = Join-Path $Path (Join-Path $Name 'ux')
    $WorkflowSettingsUxDefaultPath = Join-Path $Path (Join-Path 'default' 'ux')

    $OSDCloudUxPath = Join-Path -Path $WorkflowSettingsUxPath -ChildPath "MainWindow.ps1"
    if (-not (Test-Path $OSDCloudUxPath)) {
        $OSDCloudUxPath = Join-Path -Path $WorkflowSettingsUxDefaultPath -ChildPath "MainWindow.ps1"
    }

    if (-not (Test-Path $OSDCloudUxPath)) {
        Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Unable to locate $OSDCloudUxPath"
        break
    }

    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] $OSDCloudUxPath"
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Launching OSDCloud $ModuleVersion"

    . $OSDCloudUxPath
    #=================================================
}
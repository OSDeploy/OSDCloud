function Invoke-OSDCloudWorkflowUx {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [System.String]
        $WorkflowName = 'default',

        [System.String]
        $WorkflowsRootPath = "$($MyInvocation.MyCommand.Module.ModuleBase)\workflow"
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
    # Workflows Root Path must exist, there is no fallback
    if (-not (Test-Path $WorkflowsRootPath)) {
        Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Unable to find OSDCloud Workflows Root Path"
        Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] $WorkflowsRootPath"
        throw
    }
    #=================================================
    $workflowDefaultUxPath = Join-Path $WorkflowsRootPath (Join-Path 'default' 'ux')
    $workflowUxPath = Join-Path $WorkflowsRootPath (Join-Path $WorkflowName 'ux')

    $currentUxPath = $null
    if (Test-Path "$workflowDefaultUxPath\MainWindow.ps1") {
        $currentUxPath = Join-Path -Path $workflowDefaultUxPath -ChildPath "MainWindow.ps1"
    }
    if (Test-Path "$workflowUxPath\MainWindow.ps1") {
        $currentUxPath = Join-Path -Path $workflowUxPath -ChildPath "MainWindow.ps1"
    }

    if (-not $currentUxPath) {
        Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Unable to locate a valid Workflow Ux MainWindow.ps1"
        Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Checked $workflowUxPath and $workflowDefaultUxPath"
        throw
    }

    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] $currentUxPath"
    . $currentUxPath
    #=================================================
}
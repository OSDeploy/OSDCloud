function Invoke-OSDCloudWorkflowUx {
    [CmdletBinding()]
    param ()
    #=================================================
    # Get module details
    $ModuleBase = $($MyInvocation.MyCommand.Module.ModuleBase)
    $ModuleVersion = $($MyInvocation.MyCommand.Module.Version)
    #=================================================
    if (-not ($global:OSDCloudWorkflowInit)) {
        Initialize-OSDCloudWorkflow
    }
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Launching OSDCloud $ModuleVersion"
    $OSDCloudUxPath = Join-Path -Path $ModuleBase -ChildPath "projects\OSDCloud\MainWindow.ps1"

    if (-not (Test-Path $OSDCloudUxPath)) {
        Write-Error "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Unable to locate $OSDCloudUxPath"
        return
    }
    . $OSDCloudUxPath
    #=================================================
}
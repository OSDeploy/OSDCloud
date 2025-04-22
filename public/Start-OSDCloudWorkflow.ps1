function Start-OSDCloudWorkflow {
    [CmdletBinding()]
    param ()
    #=================================================
    # Start the function
    $Error.Clear()
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message
    #=================================================
    # Get module details
    $ModuleName = $($MyInvocation.MyCommand.Module.Name)
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] ModuleName: $ModuleName"
    $ModuleBase = $($MyInvocation.MyCommand.Module.ModuleBase)
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] ModuleBase: $ModuleBase"
    $ModuleVersion = $($MyInvocation.MyCommand.Module.Version)
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] ModuleVersion: $ModuleVersion"
    #=================================================
    # Initialize OSDCloud environment
    try {
        Initialize-OSDCloud
    } catch {
        Write-Error "Failed to initialize OSDCloud: $_"
        return
    }
    #=================================================
    # Display global workflow initialization details
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Global OSDCloudWorkflowInit"
    $OSDCloudWorkflowInit
    #=================================================
    # Launch the frontend
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Launching frontend $ModuleVersion"
    $global:OSDCloudWorkflowFrontend = $null
    $FrontendPath = Join-Path -Path $ModuleBase -ChildPath "projects\OSDCloud\MainWindow.ps1"
    if (-Not (Test-Path $FrontendPath)) {
        Write-Error "Frontend script not found at $FrontendPath"
        return
    }
    . $FrontendPath
    #=================================================
    #Initialize-OSDCloudWorkflowSteps -Path

    # Ensure workflow frontend is initialized before invoking workflow
    if ($null -ne $global:OSDCloudWorkflowFrontend.TimeStart) {
        try {
            Invoke-OSDCloudWorkflow
        } catch {
            Write-Error "Failed to invoke OSDCloud workflow: $_"
        }
    } else {
        Write-Warning "Workflow frontend not initialized. Skipping workflow invocation."
    }
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
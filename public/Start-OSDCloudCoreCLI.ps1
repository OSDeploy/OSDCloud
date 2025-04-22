function Start-OSDCloudCoreCLI {
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
        Initialize-OSDCloudWorkflow
    } catch {
        Write-Error "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Failed to initialize OSDCloud Workflow: $_"
        return
    }
    #=================================================
    # Display global workflow initialization details
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] InitializeOSDCloudWorkflow"
    $InitializeOSDCloudWorkflow
    #=================================================
    # Invoke-OSDCloudWorkflow
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Invoke-OSDCloudWorkflow"
    Invoke-OSDCloudWorkflow
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
function Start-OSDCloudWorkflowCLI {
    [CmdletBinding()]
    param ()
    #=================================================
    # Initialize OSDCloudWorkflow
    if (-not ($global:OSDCloudWorkflowInit)) {
        Initialize-OSDCloudWorkflow
    }
    #=================================================
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Invoke-OSDCloudWorkflow"
    $global:OSDCloudWorkflowInit.TimeStart = Get-Date
    $OSDCloudWorkflowInit | Out-Host
    Invoke-OSDCloudWorkflow
    #=================================================
}
function Start-OSDCloudWorkflow {
    [CmdletBinding()]
    param ()
    #=================================================
    # Initialize OSDCloudWorkflow
    if (-not ($global:OSDCloudWorkflowInit)) {
        Initialize-OSDCloudWorkflow
    }
    #=================================================
    # Prevents the workflow from starting unless the Start button is clicked in the Ux
    $global:OSDCloudWorkflowInit.TimeStart = $null
    #=================================================
    # OSDCloudWorkflowUx
    Invoke-OSDCloudWorkflowUx
    #=================================================
    # Ensure workflow frontend is triggered before invoking workflow
    if ($null -ne $global:OSDCloudWorkflowInit.TimeStart) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Invoke-OSDCloudWorkflow"
        $OSDCloudWorkflowInit | Out-Host
        try {
            Invoke-OSDCloudWorkflow
        } catch {
            Write-Error "Failed to invoke OSDCloud workflow: $_"
        }
    } else {
        Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] OSDCloud Workflow was not started."
    }
    #=================================================
}
function Deploy-OSDCloudGUI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
        [System.String]
        $WorkflowName = 'default'
    )
    #=================================================
    # Initialize OSDCloudWorkflow
    Initialize-OSDCloudDeploy -WorkflowName $WorkflowName
    #=================================================
    # Prevents the workflow from starting unless the Start button is clicked in the Ux
    $global:OSDCloudDeploy.TimeStart = $null
    #=================================================
    # OSDCloudWorkflowUx
    Invoke-OSDCloudWorkflowUx -WorkflowName $WorkflowName
    #=================================================
    # Ensure workflow frontend is triggered before invoking workflow
    if ($null -ne $global:OSDCloudDeploy.TimeStart) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Invoke-OSDCloudWorkflowTask $WorkflowName"
        $global:OSDCloudDeploy | Out-Host
        try {
            Invoke-OSDCloudWorkflowTask
        } catch {
            Write-Warning "Failed to invoke OSDCloud Workflow $WorkflowName $_"
            break
        }
    } else {
        Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSDCloud Workflow $WorkflowName was not started."
    }
    #=================================================
}
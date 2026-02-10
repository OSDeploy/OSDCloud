function Deploy-OSDCloudGUI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $Name = 'default'
    )
    #=================================================
    # Initialize OSDCloudWorkflow
    Initialize-OSDCloudDeploy -Name $Name
    #=================================================
    # Prevents the workflow from starting unless the Start button is clicked in the Ux
    $global:OSDCloudDeploy.TimeStart = $null
    #=================================================
    # OSDCloudWorkflowUx
    Invoke-OSDCloudWorkflowUx -WorkflowName $Name
    #=================================================
    # Ensure workflow frontend is triggered before invoking workflow
    if ($null -ne $global:OSDCloudDeploy.TimeStart) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Invoke-OSDCloudWorkflowTask $Name"
        $global:OSDCloudDeploy | Out-Host
        try {
            Invoke-OSDCloudWorkflowTask
        } catch {
            Write-Warning "Failed to invoke OSDCloud Workflow $Name $_"
            break
        }
    } else {
        Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSDCloud Workflow $Name was not started."
    }
    #=================================================
}
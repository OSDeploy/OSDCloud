function Deploy-OSDCloud {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $Name = 'default',

        [System.Management.Automation.SwitchParameter]
        $CLI
    )
    #=================================================
    # Initialize OSDCloudWorkflow
    Initialize-OSDCloudWorkflow -Name $Name
    #=================================================
    if ($CLI.IsPresent) {
        #=================================================
        # Initialize OSDCloudWorkflow
        Initialize-OSDCloudWorkflow -Name $Name
        #=================================================
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Invoke-OSDCloudWorkflowTask"
        $global:OSDCloudWorkflowInit.TimeStart = Get-Date
        $OSDCloudWorkflowInit | Out-Host
        Invoke-OSDCloudWorkflowTask
        #=================================================
    }
    else {
        # Prevents the workflow from starting unless the Start button is clicked in the Ux
        $global:OSDCloudWorkflowInit.TimeStart = $null
        #=================================================
        # OSDCloudWorkflowUx
        Invoke-OSDCloudWorkflowUx -Name $Name
        #=================================================
        # Ensure workflow frontend is triggered before invoking workflow
        if ($null -ne $global:OSDCloudWorkflowInit.TimeStart) {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Invoke-OSDCloudWorkflowTask $Name"
            $OSDCloudWorkflowInit | Out-Host
            try {
                Invoke-OSDCloudWorkflowTask
            }
            catch {
                Write-Warning "Failed to invoke OSDCloud Workflow $Name $_"
                break
            }
        } else {
            Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSDCloud Workflow $Name was not started."
        }
    }
}
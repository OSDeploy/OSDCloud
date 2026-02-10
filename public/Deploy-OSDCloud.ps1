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
    Initialize-DeployOSDCloud -Name $Name
    #=================================================
    if ($CLI.IsPresent) {
        #=================================================
        # Initialize OSDCloudWorkflow
        Initialize-DeployOSDCloud -Name $Name
        #=================================================
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Invoke-OSDCloudWorkflowTask"
        $global:OSDCloudInitialize.TimeStart = Get-Date
        $OSDCloudInitialize | Out-Host
        Invoke-OSDCloudWorkflowTask
        #=================================================
    }
    else {
        # Prevents the workflow from starting unless the Start button is clicked in the Ux
        $global:OSDCloudInitialize.TimeStart = $null
        #=================================================
        # OSDCloudWorkflowUx
        Invoke-OSDCloudWorkflowUx -Name $Name
        #=================================================
        # Ensure workflow frontend is triggered before invoking workflow
        if ($null -ne $global:OSDCloudInitialize.TimeStart) {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Invoke-OSDCloudWorkflowTask $Name"
            $OSDCloudInitialize | Out-Host
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
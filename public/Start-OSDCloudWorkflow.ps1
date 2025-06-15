function Start-OSDCloudWorkflow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $Name = 'default',
        [switch]
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
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] Invoke-OSDCloudWorkflow"
        $global:OSDCloudWorkflowInit.TimeStart = Get-Date
        $OSDCloudWorkflowInit | Out-Host
        Invoke-OSDCloudWorkflow
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
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] Invoke-OSDCloudWorkflow $Name"
            $OSDCloudWorkflowInit | Out-Host
            try {
                Invoke-OSDCloudWorkflow
            } catch {
                Write-Error "Failed to invoke OSDCloud Workflow $Name $_"
            }
        } else {
            Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] OSDCloud Workflow $Name was not started."
        }
    }
}
function Deploy-OSDCloud {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
        [System.String]
        $WorkflowName = 'default',

        [System.Management.Automation.SwitchParameter]
        $CLI
    )
    #=================================================
    Write-Host -ForegroundColor DarkCyan "OSDCloud collects analytic data during the deployment process to identify issues, enhance performance, and improve the overall user experience."
    Write-Host -ForegroundColor DarkCyan "No personally identifiable information (PII) is collected, and all data is anonymized to protect user privacy."
    Write-Host -ForegroundColor DarkCyan "Collected data includes information about the deployment environment and system configuration."
    Write-Host -ForegroundColor DarkCyan "By using OSDCloud, you consent to the collection of analytic data as outlined in the privacy policy"
    Write-Host -ForegroundColor DarkGray "https://github.com/OSDeploy/OSDCloud/blob/main/PRIVACY.md"
    Write-Host ""
    #=================================================
    # Initialize OSDCloudWorkflow
    Initialize-OSDCloudDeploy -WorkflowName $WorkflowName
    #=================================================
    if ($CLI.IsPresent) {
        #=================================================
        # Initialize OSDCloudWorkflow
        Initialize-OSDCloudDeploy -WorkflowName $WorkflowName
        #=================================================
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Invoke-OSDCloudWorkflowTask"
        $global:OSDCloudDeploy.TimeStart = Get-Date
        $global:OSDCloudDeploy | Out-Host
        Invoke-OSDCloudWorkflowTask
        #=================================================
    }
    else {
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
            }
            catch {
                Write-Warning "Failed to invoke OSDCloud Workflow $WorkflowName $_"
                break
            }
        } else {
            Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSDCloud Workflow $WorkflowName was not started."
        }
    }
}
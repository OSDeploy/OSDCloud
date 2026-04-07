function Deploy-OSDCloud {
    <#
    .SYNOPSIS
        Starts an OSDCloud operating system deployment.

    .DESCRIPTION
        Initializes and runs an OSDCloud deployment workflow. By default, launches the
        graphical UI (UX) so the operator can configure deployment settings before
        starting. Use -CLI to skip the UI and immediately begin the workflow in the
        current console session.

        OSDCloud collects anonymous analytic data about the deployment environment and
        system configuration to help improve the product. No personally identifiable
        information (PII) is collected. By using OSDCloud you consent to this collection
        as described in the privacy policy:
        https://github.com/OSDeploy/OSDCloud/blob/main/PRIVACY.md

    .PARAMETER WorkflowName
        The name of the OSDCloud workflow to run. Defaults to 'default'.
        Available workflows are located in the module's workflow folder.

    .PARAMETER CLI
        Skips the graphical UX and runs the deployment workflow immediately in the
        current console session.

    .EXAMPLE
        Deploy-OSDCloud

        Launches the OSDCloud graphical UX for the default workflow. The deployment
        starts only after the operator clicks Start in the UI.

    .EXAMPLE
        Deploy-OSDCloud -CLI

        Runs the default OSDCloud workflow immediately without the graphical UX.

    .EXAMPLE
        Deploy-OSDCloud -WorkflowName 'latest'

        Launches the graphical UX for the 'latest' workflow.
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
        [System.String]
        $WorkflowName = 'default',

        [System.Management.Automation.SwitchParameter]
        $CLI
    )

    Write-Host -ForegroundColor DarkCyan 'OSDCloud collects analytic data during the deployment process to help improve the product and user experience.'
    Write-Host -ForegroundColor DarkCyan 'No personally identifiable information (PII) is collected, and all data is anonymized to protect user privacy.'
    Write-Host -ForegroundColor DarkCyan 'Collected data includes information about the deployment environment and system configuration.'
    Write-Host -ForegroundColor DarkCyan 'By using OSDCloud, you consent to the collection of analytic data as outlined in the privacy policy:'
    Write-Host -ForegroundColor DarkGray 'https://github.com/OSDeploy/OSDCloud/blob/main/PRIVACY.md'
    Write-Host

    Initialize-OSDCloudDeploy -WorkflowName $WorkflowName

    if ($CLI.IsPresent) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Invoke-OSDCloudWorkflowTask"
        $global:OSDCloudDeploy.TimeStart = Get-Date
        $global:OSDCloudDeploy | Out-Host
        Invoke-OSDCloudWorkflowTask
    }
    else {
        # Prevents the workflow from starting unless the Start button is clicked in the GUI
        $global:OSDCloudDeploy.TimeStart = $null

        Invoke-OSDCloudWorkflowUx -WorkflowName $WorkflowName

        if ($null -ne $global:OSDCloudDeploy.TimeStart) {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Invoke-OSDCloudWorkflowTask $WorkflowName"
            $global:OSDCloudDeploy | Out-Host
            try {
                Invoke-OSDCloudWorkflowTask
            }
            catch {
                Write-Warning "Failed to invoke OSDCloud Workflow '$WorkflowName': $_"
            }
        }
        else {
            Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSDCloud Workflow '$WorkflowName' was not started."
        }
    }
}
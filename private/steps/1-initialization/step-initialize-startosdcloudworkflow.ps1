function step-initialize-startosdcloudworkflow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$WorkflowName = "OSDCloud Workflow"
    )
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSvDCloudWorkflowCurrentStep
    #=================================================
    # Delay Start
    Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Starting $WorkflowName in 5 seconds..."
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Press CTRL+C to cancel"
    Start-Sleep -Seconds 5
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
function step-initialize-startosdcloudworkflow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$WorkflowName = "OSDCloud Workflow"
    )
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudWorkflowCurrentStep
    #=================================================
    # Delay Start
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] Starting $WorkflowName in 5 seconds..."
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] Press CTRL+C to cancel"
    Start-Sleep -Seconds 5
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
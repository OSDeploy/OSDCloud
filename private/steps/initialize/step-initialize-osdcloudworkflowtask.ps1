function step-initialize-osdcloudworkflowtask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$WorkflowTaskName = "OSDCloud Workflow"
    )
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudTaskCurrentStep
    #=================================================
    # Delay Start
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Starting $WorkflowTaskName in 5 seconds..."
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Press CTRL+C to cancel"
    Start-Sleep -Seconds 5
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
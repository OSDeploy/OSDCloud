function step-initialize-osdcloudworkflowtask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$WorkflowTaskName = "OSDCloud Workflow"
    )
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Verbose -Message $Message; Write-Debug -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudCurrentStep
    #=================================================
    #region Main
    
    # Display delay message to user
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Starting $WorkflowTaskName in 5 seconds..."
    Write-Host -ForegroundColor DarkGray "Press Ctrl+C to exit OSDCloud"
    Start-Sleep -Seconds 5
    
    #endregion
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
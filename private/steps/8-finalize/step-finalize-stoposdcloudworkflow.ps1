function step-finalize-stoposdcloudworkflow {
    [CmdletBinding()]
    param ()
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSvDCloudWorkflowCurrentStep
    #=================================================
    #region Main
    $global:InvokeOSDCloudWorkflow.TimeEnd = Get-Date
    $global:InvokeOSDCloudWorkflow.TimeSpan = New-TimeSpan -Start $global:InvokeOSDCloudWorkflow.TimeStart -End $global:InvokeOSDCloudWorkflow.TimeEnd
    $global:InvokeOSDCloudWorkflow | ConvertTo-Json | Out-File -FilePath 'C:\Windows\Temp\osdcloud-logs\OSDCloud.json' -Encoding ascii -Width 2000 -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Completed in $($global:InvokeOSDCloudWorkflow.TimeSpan.ToString("mm' minutes 'ss' seconds'"))"
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
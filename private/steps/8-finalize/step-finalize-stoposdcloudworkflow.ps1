function step-finalize-stoposdcloudworkflow {
    [CmdletBinding()]
    param ()
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudWorkflowCurrentStep
    #=================================================
    #region Main
    $global:OSDCloudWorkflowInvoke.TimeEnd = Get-Date
    $global:OSDCloudWorkflowInvoke.TimeSpan = New-TimeSpan -Start $global:OSDCloudWorkflowInvoke.TimeStart -End $global:OSDCloudWorkflowInvoke.TimeEnd
    $global:OSDCloudWorkflowInvoke | ConvertTo-Json | Out-File -FilePath 'C:\Windows\Temp\osdcloud-logs\OSDCloud.json' -Encoding ascii -Width 2000 -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] Completed in $($global:OSDCloudWorkflowInvoke.TimeSpan.ToString("mm' minutes 'ss' seconds'"))"
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
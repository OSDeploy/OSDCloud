function step-postaction-removeosdcloudlogs {
    [CmdletBinding()]
    param ()
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudWorkflowCurrentStep
    #=================================================
    # Stop Transcript at this point as this file is locked and will cause issues with cleanup
    $null = Stop-Transcript -ErrorAction SilentlyContinue

    $LogsPath = "C:\Windows\Temp\osdcloud-logs"

    $Params = @{
        ErrorAction = 'SilentlyContinue'
        Force       = $true
        Path        = $LogsPath
        Recurse     = $true
    }

    if (Test-Path $LogsPath) {
        Remove-Item @Params | Out-Null
    }
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
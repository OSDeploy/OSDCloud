function step-postaction-restartcomputer {
    [CmdletBinding()]
    param ()
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudCurrentStep
    #=================================================
    #region Main
    if ($global:OSDCloudWorkflowInvoke.WinpeRestart) {
        Write-Host -ForegroundColor Yellow "[$(Get-Date -format s)] Device will restart in 30 seconds"
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Press CTRL + C to cancel"
        #TODO EJECT ISO
        # (New-Object -ComObject 'Shell.Application').Namespace(17).Items() | Where-Object { $_.Type -eq 'CD Drive' } | ForEach-Object { $_.InvokeVerb('Eject') }
        Start-Sleep -Seconds 30
        Restart-Computer
    }
    #endregion
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
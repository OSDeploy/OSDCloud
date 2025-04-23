function step-postaction-restartcomputer {
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
    if ($global:OSDCloudWorkflowInvoke.WinpeRestart) {
        Write-Host -ForegroundColor Yellow "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Device will restart in 30 seconds"
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Press CTRL + C to cancel"
        #TODO EJECT ISO
        # (New-Object -ComObject 'Shell.Application').Namespace(17).Items() | Where-Object { $_.Type -eq 'CD Drive' } | ForEach-Object { $_.InvokeVerb('Eject') }
        Start-Sleep -Seconds 30
        Restart-Computer
    }
    #endregion
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
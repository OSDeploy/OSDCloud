function step-install-bcdboot {
    [CmdletBinding()]
    param ()
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudWorkflowCurrentStep
    #=================================================
    #region Main
    # Check what architecture we are using
    if ($global:OSDCloudWorkflowGather.Architecture -match 'arm64') {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] X:\Windows\System32\bcdboot.exe C:\Windows /c"
        X:\Windows\System32\bcdboot.exe C:\Windows /c
    }
    else {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] C:\Windows\System32\bcdboot.exe C:\Windows /c"
        C:\Windows\System32\bcdboot.exe C:\Windows /c
    }

    #TODO What is "Updated configuration that should clear existing UEFI Boot entires and fix the Dell issue"
    # https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/bcdboot-command-line-options-techref-di?view=windows-11

    #endregion
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
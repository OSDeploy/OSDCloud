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
    $LogPath = "C:\Windows\Temp\osdcloud-logs"

    # Check what architecture we are using
    if ($global:OSDCloudWorkflowInit.OSArchitecture -match 'ARM64') {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] X:\Windows\System32\bcdboot.exe C:\Windows /c /v"
        $BCDBootOutput = & X:\Windows\System32\bcdboot.exe C:\Windows /c /v
        $BCDBootOutput | Out-File -FilePath "$LogPath\bcdboot.log" -Force
    }
    else {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] C:\Windows\System32\bcdboot.exe C:\Windows /c /v"
        $BCDBootOutput = & C:\Windows\System32\bcdboot.exe C:\Windows /c /v
        $BCDBootOutput | Out-File -FilePath "$LogPath\bcdboot.log" -Force
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
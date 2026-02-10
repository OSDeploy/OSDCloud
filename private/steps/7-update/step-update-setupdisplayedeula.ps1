function step-update-setupdisplayedeula {
    [CmdletBinding()]
    param ()
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudTaskCurrentStep
    #=================================================
    #region Main
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Updating the OOBE SetupDisplayedEula value in the registry. OK."
    $null = reg load HKLM\TempSOFTWARE "C:\Windows\System32\Config\SOFTWARE"
    $null = reg add HKLM\TempSOFTWARE\Microsoft\Windows\CurrentVersion\Setup\OOBE /v SetupDisplayedEula /t REG_DWORD /d 0x00000001 /f
    $null = reg unload HKLM\TempSOFTWARE
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
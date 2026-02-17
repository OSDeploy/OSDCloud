function step-install-bcdboot {
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
    $LogPath = "C:\Windows\Temp\osdcloud-logs"

    # https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/bcdboot-command-line-options-techref-di?view=windows-11
    # https://support.microsoft.com/en-us/topic/how-to-manage-the-windows-boot-manager-revocations-for-secure-boot-changes-associated-with-cve-2023-24932-41a975df-beb2-40c1-99a3-b3ff139f832d

    Push-Location -Path "C:\Windows\System32"
    if ($global:OSDCloudDeploy.OSBuild -lt 26200) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] C:\Windows\System32\bcdboot.exe C:\Windows /c /v"
        $BCDBootOutput = & C:\Windows\System32\bcdboot.exe C:\Windows /c /v
        $BCDBootOutput | Out-File -FilePath "$LogPath\bcdboot.log" -Force
    }
    else {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] C:\Windows\System32\bcdboot.exe C:\Windows /c /bootex"
        $BCDBootOutput = & C:\Windows\System32\bcdboot.exe C:\Windows /c /bootex
        $BCDBootOutput | Out-File -FilePath "$LogPath\bcdboot.log" -Force
    }
    Pop-Location
    #endregion
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
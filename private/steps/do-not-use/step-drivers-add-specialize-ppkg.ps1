function step-drivers-add-specialize-ppkg {
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
    Write-Host -ForegroundColor DarkGray 'Add Windows Driver with Offline Servicing (Add-OfflineServicingWindowsDriver)'
    Write-Verbose -Message 'https://docs.microsoft.com/en-us/powershell/module/dism/add-windowsdriver'
    Write-Host -ForegroundColor DarkGray 'Drivers in C:\Drivers are being added to the offline Windows Image'
    Write-Host -ForegroundColor DarkGray 'This process can take up to 20 minutes'
    Write-Verbose -Message 'Add-OfflineServicingWindowsDriver'
    if ($IsWinPE -eq $true) {
        Add-OfflineServicingWindowsDriver
    }
    #endregion
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
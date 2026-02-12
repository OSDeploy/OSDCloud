function step-test-targetdisk {
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
    $global:OSDCloudWorkflowInvoke.GetDiskFixed = Get-DeviceLocalDisk | Where-Object { $_.IsBoot -eq $false } | Sort-Object Number

    if ($global:OSDCloudWorkflowInvoke.GetDiskFixed) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Fixed Disk is valid. OK."
    }
    else {
        Write-Warning "[$(Get-Date -format s)] Unable to detect a Fixed Disk."
        Write-Warning "[$(Get-Date -format s)] WinPE may need additional Disk, SCSI or Raid Drivers."
        Write-Warning 'Press Ctrl+C to cancel OSDCloud'
        Start-Sleep -Seconds 86400
        exit
    }
    #endregion
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
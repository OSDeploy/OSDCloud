function step-validate-isdiskready {
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
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)]"

    $global:OSDCloudWorkflowInvoke.GetDiskFixed = Get-LocalDisk | Where-Object { $_.IsBoot -eq $false } | Sort-Object Number

    if ($global:OSDCloudWorkflowInvoke.GetDiskFixed) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Fixed Disk is valid. OK."
    }
    else {
        Write-Warning "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Unable to detect a Fixed Disk."
        Write-Warning "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] WinPE may need additional Disk, SCSI or Raid Drivers."
        Write-Warning 'Press Ctrl+C to cancel OSDCloud'
        Start-Sleep -Seconds 86400
        Exit
    }
    #endregion
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
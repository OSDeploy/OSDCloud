function step-preinstall-cleartargetdisk {
    [CmdletBinding()]
    param (
        # We should always confirm to Clear-Disk as this is destructive
        [System.Boolean]
        $Confirm = $true
    )
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudCurrentStep
    #=================================================
    #region Main
    # If Confirm is set to false, we need to check if there are multiple disks
    if (($Confirm -eq $false) -and (($global:OSDCloudWorkflowInvoke.GetDiskFixed | Measure-Object).Count -ge 2)) {
        Write-Warning "[$(Get-Date -format s)] OSDCloud has detected more than 1 Fixed Disk is installed. Clear-Disk with Confirm is required"
        $Confirm = $true
    }

    Clear-DeviceLocalDisk -Force -NoResults -Confirm:$Confirm -ErrorAction Stop
    #endregion
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
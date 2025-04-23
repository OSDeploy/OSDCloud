function step-preinstall-cleardisk {
    [CmdletBinding()]
    param (
        # We should always confirm to Clear-Disk as this is destructive
        [System.Boolean]
        $Confirm = $true
    )
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSvDCloudWorkflowCurrentStep
    #=================================================
    #region Main
    # If Confirm is set to false, we need to check if there are multiple disks
    if (($Confirm -eq $false) -and (($global:OSDCloudWorkflowInvokeSettings.GetDiskFixed | Measure-Object).Count -ge 2)) {
        Write-Warning "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] OSDCloud has detected more than 1 Fixed Disk is installed. Clear-Disk with Confirm is required"
        $Confirm = $true
    }

    Clear-LocalDisk -Force -NoResults -Confirm:$Confirm -ErrorAction Stop
    #endregion
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
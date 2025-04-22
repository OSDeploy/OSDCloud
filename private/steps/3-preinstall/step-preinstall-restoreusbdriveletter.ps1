function step-preinstall-restoreusbdriveletter {
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
    if ($global:InvokeOSDCloudWorkflow.USBPartitions) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Restoring USB Drive Letters. OK."
        foreach ($Item in $global:InvokeOSDCloudWorkflow.USBPartitions) {
            $Params = @{
                AssignDriveLetter = $true
                DiskNumber        = $Item.DiskNumber
                PartitionNumber   = $Item.PartitionNumber
                ErrorAction       = 'SilentlyContinue'
            }
            Add-PartitionAccessPath @Params
            Start-Sleep -Seconds 5
        }
    }
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
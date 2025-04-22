function step-preinstall-removeusbdriveletter {
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
    <#
        https://docs.microsoft.com/en-us/powershell/module/storage/remove-partitionaccesspath
        Partition Access Paths are being removed from USB Drive Letters
        This prevents issues when Drive Letters are reassigned
    #>

    # Store the USB Partitions
    $global:OSDCloudWorkflowInvoke.USBPartitions = Get-USBPartition

    # Remove USB Drive Letters
    if ($global:OSDCloudWorkflowInvoke.USBPartitions) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Removing USB Drive Letters. OK."
        foreach ($Item in $global:OSDCloudWorkflowInvoke.USBPartitions) {
            $Params = @{
                AccessPath      = "$($Item.DriveLetter):"
                DiskNumber      = $Item.DiskNumber
                PartitionNumber = $Item.PartitionNumber
                ErrorAction     = 'SilentlyContinue'
            }
            Remove-PartitionAccessPath @Params
            Start-Sleep -Seconds 3
        }
    }
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
function step-preinstall-partitiondisk {
    [CmdletBinding()]
    param (
        [System.String]
        $RecoveryPartitionForce = $global:OSDCloudWorkflowInvokeSettings.RecoveryPartition.Force,

        [System.String]
        $RecoveryPartitionSkip = $global:OSDCloudWorkflowInvokeSettings.RecoveryPartition.Skip,

        [Int32]
        $DiskNumber = $global:OSDCloudWorkflowInvokeSettings.DiskPartition.DiskNumber
    )
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudWorkflowCurrentStep
    #=================================================
    #region Main
    # Mental Math
    $RecoveryPartition = $true
    if ($IsVM -eq $true) { $RecoveryPartition = $false }
    if ($RecoveryPartitionSkip) { $RecoveryPartition = $false }
    if ($RecoveryPartitionForce) { $RecoveryPartition = $true }

    if ($RecoveryPartition -eq $false) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] Recovery Partition will not be created. OK."
        New-OSDisk -PartitionStyle GPT -NoRecoveryPartition -Force -ErrorAction Stop
        Write-Host "=========================================================================" -ForegroundColor Cyan
        Write-Host "| SYSTEM | MSR |                    WINDOWS                             |" -ForegroundColor Cyan
        Write-Host "=========================================================================" -ForegroundColor Cyan
    }
    else {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] 2GB Recovery Partition will be created. OK."
        if ($DiskNumber) {
            New-OSDisk -PartitionStyle GPT -DiskNumber $DiskNumber -SizeRecovery 2000 -Force -ErrorAction Stop
        }
        else {
            New-OSDisk -PartitionStyle GPT -Force -ErrorAction Stop
        }
        Write-Host "=========================================================================" -ForegroundColor Cyan
        Write-Host "| SYSTEM | MSR |                    WINDOWS                  | RECOVERY |" -ForegroundColor Cyan
        Write-Host "=========================================================================" -ForegroundColor Cyan
    }
    Start-Sleep -Seconds 5

    # Make sure that there is a PSDrive 
    if (!(Get-PSDrive -Name 'C')) {
        Write-Warning "[$(Get-Date -format G)] Failed to create a PSDrive FileSystem at C:\."
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] Press Ctrl+C to exit OSDCloud"
        Start-Sleep -Seconds 86400
        exit
    }
    #endregion
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
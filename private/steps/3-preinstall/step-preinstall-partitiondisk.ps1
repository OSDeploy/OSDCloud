function step-preinstall-partitiondisk {
    [CmdletBinding()]
    param (
        [System.String]
        $RecoveryPartitionForce = $global:InvokeOSDCloudWorkflowSettings.RecoveryPartition.Force,

        [System.String]
        $RecoveryPartitionSkip = $global:InvokeOSDCloudWorkflowSettings.RecoveryPartition.Skip,

        [Int32]
        $DiskNumber = $global:InvokeOSDCloudWorkflowSettings.DiskPartition.DiskNumber
    )
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSvDCloudWorkflowCurrentStep
    #=================================================
    #region Main
    # Mental Math
    $RecoveryPartition = $true
    if ($IsVM -eq $true) { $RecoveryPartition = $false }
    if ($RecoveryPartitionSkip) { $RecoveryPartition = $false }
    if ($RecoveryPartitionForce) { $RecoveryPartition = $true }

    if ($RecoveryPartition -eq $false) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Recovery Partition will not be created. OK."
        New-OSDisk -PartitionStyle GPT -NoRecoveryPartition -Force -ErrorAction Stop
        Write-Host "=========================================================================" -ForegroundColor Cyan
        Write-Host "| SYSTEM | MSR |                    WINDOWS                             |" -ForegroundColor Cyan
        Write-Host "=========================================================================" -ForegroundColor Cyan
    }
    else {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] 2GB Recovery Partition will be created. OK."
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
        Write-Warning "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Failed to create a PSDrive FileSystem at C:\."
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Press Ctrl+C to exit OSDCloud"
        Start-Sleep -Seconds 86400
        exit
    }
    #endregion
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
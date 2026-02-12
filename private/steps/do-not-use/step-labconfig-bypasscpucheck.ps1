function step-labconfig-bypasscpucheck {
    [CmdletBinding()]
    param (
        [System.Boolean]
        $Enabled = $false
    )
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudCurrentStep
    #=================================================
    #region Main
    $OfflineRegistryPath = 'HKLM:\OfflineSystem\Setup\LabConfig'
    if (-not (Test-Path $OfflineRegistryPath)) {
        New-Item -Path $OfflineRegistryPath -Force | Out-Null
    }
    New-ItemProperty -Path $OfflineRegistryPath -Name 'BypassCPUCheck' -Value 1 -PropertyType DWord -Force | Out-Null
    Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] BypassCPUCheck set to 1 in offline registry"
    #endregion
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}

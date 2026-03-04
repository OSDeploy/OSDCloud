<#
.SYNOPSIS
    Adds Windows drivers from disk to the running Windows system.

.DESCRIPTION
    This step function adds device drivers from the OSDCloud temporary drivers directory
    to the running Windows installation. It uses DISM (Deployment Image Servicing and
    Management) to inject drivers with the Add-WindowsDriver cmdlet. Drivers are applied
    to the C:\ drive and are logged for troubleshooting purposes.
    
    This is part of the OSDCloud deployment workflow and runs during the driver injection phase.

.NOTES
    - Driver source directory: C:\Windows\Temp\osdcloud-drivers-disk
    - Log output: C:\Windows\Temp\osdcloud-logs\dism-add-windowsdriver-disk.log
    - Drivers are added recursively from the source directory
    - Unsigned drivers are allowed during the deployment process
    - Non-terminating errors are suppressed to allow deployment to continue if driver injection fails
    - Requires administrative privileges to execute

.EXAMPLE
    step-Add-WindowsDriver-Disk
    
    Adds all drivers from the OSDCloud drivers directory to the system.

.OUTPUTS
    None. This function does not return any objects.
#>
function step-Add-WindowsDriver-Disk {
    [CmdletBinding()]
    param ()
    #=================================================
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message
    $Step = $global:OSDCloudCurrentStep
    #=================================================
    $LogPath = "C:\Windows\Temp\osdcloud-logs"

    $DriverPath = "C:\Windows\Temp\osdcloud-drivers-disk"

    if (Test-Path -Path $DriverPath) {
        if (-not (Test-Path -Path $LogPath)) {
            New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
        }
        Add-WindowsDriver -Path "C:\" -Driver "$DriverPath" -Recurse -ForceUnsigned -LogPath "$LogPath\dism-add-windowsdriver-disk.log" -ErrorAction SilentlyContinue
    }
    #=================================================
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
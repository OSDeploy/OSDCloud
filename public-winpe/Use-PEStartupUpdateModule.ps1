<#
.SYNOPSIS
Updates a PowerShell module from the PowerShell Gallery in Windows PE startup environment.

.DESCRIPTION
Downloads and installs the latest version of a specified PowerShell module from the PowerShell Gallery with AllUsers scope. Provides a 10-second countdown window before installation begins, allowing users to cancel if needed. After successful installation, the module is imported with the -Force parameter to ensure the latest version is loaded into the current session.

.PARAMETER Name
Specifies the name of the PowerShell module to update from the PowerShell Gallery. This parameter is mandatory.

.EXAMPLE
Use-PEStartupUpdateModule -Name OSDCloud
Updates the OSDCloud module from the PowerShell Gallery and imports it into the current session.

.EXAMPLE
Use-PEStartupUpdateModule -Name PSDiskPart
Updates the PSDiskPart module with a 10-second countdown before installation begins.

.OUTPUTS
None. This function performs module installation and displays status messages to the console but does not return objects.

.NOTES
This function is designed for use in Windows PE startup environments and uses the following installation parameters:
- Scope: AllUsers (installs module for all users on the system)
- Force: $true (forces installation even if module exists)
- SkipPublisherCheck: $true (skips publisher trust check for module signature)

The function displays a 10-second countdown timer before beginning the installation, allowing users time to cancel the operation if needed. The window title updates to show the module name being updated and indicates that closing the window will cancel the operation.

Installation is performed to the AllUsers scope, making the module available to all users on the system.
#>
function Use-PEStartupUpdateModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )
    #=================================================
    $Error.Clear()
    $host.ui.RawUI.WindowTitle = "[$(Get-Date -format s)] OSDCloud - Update PowerShell Module: $Name (close this window to cancel)"
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    #=================================================
    Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] Update PowerShell Module: $Name"
    Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] Close this window to cancel (starting in 10 seconds)"
    Start-Sleep -Seconds 10
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] $Name $($GalleryPSModule.Version) [AllUsers]"
    Install-Module $Name -Scope AllUsers -Force -SkipPublisherCheck
    Import-Module $Name -Force
    #=================================================
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    #=================================================
}
<#
.SYNOPSIS
Displays network configuration information in Windows PE startup environment.

.DESCRIPTION
Shows detailed network adapter and IP configuration information for all network interfaces using the ipconfig /all command. Updates the PowerShell window title to indicate the function is running and sets the output window title to indicate this is the IPConfig display. This utility is designed to help troubleshoot network connectivity issues during WinPE deployment.

.PARAMETER None
This function does not accept any parameters.

.EXAMPLE
Show-PEStartupIpconfig
Displays the ipconfig /all output showing all network adapter configuration details.

.OUTPUTS
None. This function displays network configuration information to the console via the ipconfig utility but does not return objects.

.NOTES
This function is designed for use in Windows PE startup environments. It provides:
- Network adapter names and types
- IP addresses (IPv4 and IPv6)
- DHCP configuration status
- Gateway and DNS information
- Media status and adapter speeds

The window title is updated to '[OSDCloud] IPConfig - Network Configuration' to provide context to users.

.LINK
ipconfig
#>
function Show-PEStartupIpconfig {
    [CmdletBinding()]
    param ()
    #=================================================
    $Error.Clear()
    $host.ui.RawUI.WindowTitle = "[$(Get-Date -format s)] OSDCloud - IPConfig - Network Configuration"
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    #=================================================
    Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] ipconfig /all"
    ipconfig /all
    #=================================================
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    #=================================================
}
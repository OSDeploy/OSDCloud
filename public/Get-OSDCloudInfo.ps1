function Get-OSDCloudInfo {
    <#
    .SYNOPSIS
        Displays OSDCloud module information, contributors, and community links.

    .DESCRIPTION
        Displays the OSDCloud module's contributor profiles, GitHub project URL,
        PowerShell Gallery page, and Discord community channel link.
        Requires the global OSDCloudModule variable to be initialized, which happens
        automatically when the module is imported.

    .EXAMPLE
        Get-OSDCloudInfo

        Displays contributor links, the GitHub repository, PowerShell Gallery page,
        and Discord community URL for the OSDCloud module.
    #>
    [CmdletBinding()]
    param ()

    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"

    if (-not $global:OSDCloudModule -or -not $global:OSDCloudModule.links) {
        Write-Warning "The global variable '\$OSDCloudModule' or its 'links' property is not defined. Ensure the OSDCloud module is imported correctly."
        return
    }

    Write-Host -ForegroundColor DarkCyan 'OSDCloud Module Collaboration'
    Write-Host -ForegroundColor DarkGray "David Segura $($global:OSDCloudModule.links.david)"
    Write-Host -ForegroundColor DarkGray "Michael Escamilla $($global:OSDCloudModule.links.michael)"
    Write-Host

    Write-Host -ForegroundColor DarkCyan 'GitHub: OSDCloud'
    Write-Host -ForegroundColor DarkGray $global:OSDCloudModule.module.project
    Write-Host

    Write-Host -ForegroundColor DarkCyan 'PowerShell Gallery: OSDCloud'
    Write-Host -ForegroundColor DarkGray $global:OSDCloudModule.module.powershellgallery
    Write-Host

    Write-Host -ForegroundColor DarkCyan 'Discord: WinAdmins os-deployment'
    Write-Host -ForegroundColor DarkGray $global:OSDCloudModule.links.discord

    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
}
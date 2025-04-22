function Get-OSDCloudInfo {
    [CmdletBinding()]
    param ()

    # Clear previous errors
    $Error.Clear()
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand)] Start"

    # Retrieve module details
    $ModuleName = $($MyInvocation.MyCommand.Module.Name)
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] ModuleName: $ModuleName"
    $ModuleBase = $($MyInvocation.MyCommand.Module.ModuleBase)
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] ModuleBase: $ModuleBase"
    $ModuleVersion = $($MyInvocation.MyCommand.Module.Version)
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] ModuleVersion: $ModuleVersion"

    # Validate global variable dependencies
    if (-not $OSDCloudModule -or -not $OSDCloudModule.links) {
        Write-Error "The global variable '$OSDCloudModule' or its 'links' property is not defined. Please ensure it is initialized before running this function."
        return
    }

    # Display OSDCloud team information
    Write-Host -ForegroundColor DarkCyan 'OSDCloud Team'
    Write-Host -ForegroundColor DarkGray "David Segura $($OSDCloudModule.links.david)"
    Write-Host -ForegroundColor DarkGray "Michael Escamilla $($OSDCloudModule.links.michael)"
    Write-Host -ForegroundColor DarkGray "Gary Blok $($OSDCloudModule.links.gary)"
    Write-Host

    # Display upcoming events
    Write-Host -ForegroundColor DarkCyan 'MMSMOA: OSDCloud and OSDWorkspace'
    Write-Host -ForegroundColor DarkGray "May 5-8 2025 $($OSDCloudModule.links.mmsmoa)"
    Write-Host
    Write-Host -ForegroundColor DarkCyan 'WPNinjasUK: OSDCloud and OSDWorkspace'
    Write-Host -ForegroundColor DarkGray "June 16-17 2025 $($OSDCloudModule.links.wpninjasuk)"
    Write-Host
    Write-Host -ForegroundColor DarkCyan 'WPNinjas: OSDCloud and OSDWorkspace'
    Write-Host -ForegroundColor DarkGray "September 22-25, 2025 | $($OSDCloudModule.links.wpninjasch)"
    Write-Host

    # Display additional resources
    Write-Host -ForegroundColor DarkCyan 'GitHub: OSDCloud'
    Write-Host -ForegroundColor DarkGray $($OSDCloudModule.links.github)
    Write-Host
    Write-Host -ForegroundColor DarkCyan 'PowerShell Gallery: OSDCloud'
    Write-Host -ForegroundColor DarkGray $($OSDCloudModule.links.powershellgallery)
    Write-Host
    Write-Host -ForegroundColor DarkCyan 'Discord: WinAdmins os-deployment'
    Write-Host -ForegroundColor DarkGray $($OSDCloudModule.links.discord)
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
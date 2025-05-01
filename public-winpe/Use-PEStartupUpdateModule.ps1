function Use-PEStartupUpdateModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )
    #=================================================
    $Error.Clear()
    Write-Verbose "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] Start"
    $host.ui.RawUI.WindowTitle = "[OSDCloud] Update PowerShell Module: $Name (close this window to cancel)"
    #=================================================
    Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format G)] Update PowerShell Module: $Name"
    Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format G)] Close this window to cancel (starting in 10 seconds)"
    Start-Sleep -Seconds 10
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] $Name $($GalleryPSModule.Version) [AllUsers]"
    Install-Module $Name -Scope AllUsers -Force -SkipPublisherCheck
    Import-Module $Name -Force
    #=================================================
    Write-Verbose "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] Done"
    #=================================================
}
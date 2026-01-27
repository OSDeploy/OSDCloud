function Use-PEStartupUpdateModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )
    #=================================================
    $Error.Clear()
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    $host.ui.RawUI.WindowTitle = "[OSDCloud] Update PowerShell Module: $Name (close this window to cancel)"
    #=================================================
    Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] Update PowerShell Module: $Name"
    Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] Close this window to cancel (starting in 10 seconds)"
    Start-Sleep -Seconds 10
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] $Name $($GalleryPSModule.Version) [AllUsers]"
    Install-Module $Name -Scope AllUsers -Force -SkipPublisherCheck
    Import-Module $Name -Force
    #=================================================
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Done"
    #=================================================
}
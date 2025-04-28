function Use-PEStartupUpdateModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )
    #=================================================
    $Error.Clear()
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Start"
    $host.ui.RawUI.WindowTitle = "[OSDCloud] Update PowerShell Module: $Name (close this window to cancel)"
    #=================================================
    Write-Host -ForegroundColor DarkCyan "[$((Get-Date).ToString('HH:mm:ss'))] Update PowerShell Module: $Name"
    Write-Host -ForegroundColor DarkCyan "[$((Get-Date).ToString('HH:mm:ss'))] Close this window to cancel (starting in 10 seconds)"
    Start-Sleep -Seconds 10

    $InstalledModule = Get-Module -Name $Name -ListAvailable -ErrorAction Ignore | Sort-Object Version -Descending | Select-Object -First 1
    $GalleryPSModule = Find-Module -Name $Name -ErrorAction Ignore -WarningAction Ignore

    # Install the OSD module if it is not installed or if the version is older than the gallery version
    if ($GalleryPSModule) {
        if (($GalleryPSModule.Version -as [version]) -gt ($InstalledModule.Version -as [version])) {
            Write-Host -ForegroundColor DarkGray "$Name $($GalleryPSModule.Version) [AllUsers]"
            Install-Module $Name -Scope AllUsers -Force -SkipPublisherCheck
            Import-Module $Name -Force
        }
    }
    #=================================================
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Done"
    #=================================================
}
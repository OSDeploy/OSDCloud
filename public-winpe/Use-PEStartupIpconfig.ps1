function Use-PEStartupIpconfig {
    [CmdletBinding()]
    param ()
    #=================================================
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Start"
    $Error.Clear()
    $host.ui.RawUI.WindowTitle = '[OSDCloud] IPConfig - Network Configuration'
    #=================================================
    Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format G)] ipconfig /all"
    ipconfig /all
    #=================================================
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Done"
    #=================================================
}
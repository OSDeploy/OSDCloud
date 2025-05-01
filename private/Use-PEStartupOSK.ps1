function Use-PEStartupOSK {
    [CmdletBinding()]
    param ()
    #=================================================
    Write-Verbose "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] Start"
    $Error.Clear()
    #=================================================
    $host.ui.RawUI.WindowTitle = '[OSDCloud] Use-PEStartupOSK'

    Start-Process -FilePath 'osk.exe' -WindowStyle Minimized
    exit 0
    #=================================================
    Write-Verbose "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] Done"
    #=================================================
}
function Invoke-PEStartupOSK {
    [CmdletBinding()]
    param ()
    #=================================================
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    $Error.Clear()
    #=================================================
    $host.ui.RawUI.WindowTitle = '[OSDCloud] Invoke-PEStartupOSK'

    Start-Process -FilePath 'osk.exe' -WindowStyle Minimized
    exit 0
    #=================================================
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Done"
    #=================================================
}
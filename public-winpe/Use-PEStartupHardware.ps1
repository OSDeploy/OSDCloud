function Use-PEStartupHardware {
    [CmdletBinding()]
    param ()
    #=================================================
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Start"
    $Error.Clear()
    $host.ui.RawUI.WindowTitle = '[OSDCloud] Device Hardware'
    #=================================================
    $Results = Get-CimInstance -ClassName Win32_PnPEntity | Select-Object Status, DeviceID, Name, Manufacturer, PNPClass, Service | Sort-Object DeviceID

    if ($Results) {
        Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format G)] Get-CimInstance Win32_PnPEntity Hardware Devices"
        Write-Output $Results | Format-Table -AutoSize
    }
    else {
        exit 0
    }
    #=================================================
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Done"
    #=================================================
}
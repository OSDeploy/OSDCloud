function Use-PEStartupHardwareErrors {
    [CmdletBinding()]
    param ()
    #=================================================
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    $Error.Clear()
    $host.ui.RawUI.WindowTitle = '[OSDCloud] Device Hardware with Issues (automatically close in 5 seconds)'
    #=================================================
    $Results = Get-CimInstance -ClassName Win32_PnPEntity | Select-Object Status, DeviceID, Name, Manufacturer, PNPClass, Service | Where-Object Status -ne 'OK' | Sort-Object Status, DeviceID

    if ($Results) {
        Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] Get-CimInstance Win32_PnPEntity Hardware Devices with Issues"
        Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] This window will automatically close in 5 seconds"
        Write-Output $Results | Format-Table -AutoSize
        Start-Sleep -Seconds 5
    }
    exit 0
    #=================================================
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Done"
    #=================================================
}
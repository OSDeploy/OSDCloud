function Show-PEStartupHardware {
    [CmdletBinding()]
    param ()
    #=================================================
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    $Error.Clear()
    $host.ui.RawUI.WindowTitle = '[OSDCloud] Device Hardware'
    #=================================================
    $Results = Get-CimInstance -ClassName Win32_PnPEntity | Select-Object Status, DeviceID, Name, Manufacturer, PNPClass, Service | Sort-Object DeviceID

    if ($Results) {
        Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] WinPE Hardware Devices"        
        $Command = "Get-CimInstance -ClassName Win32_PnPEntity | Select-Object Status, DeviceID, Name, Manufacturer, PNPClass, Service | Sort-Object DeviceID | Format-Table -AutoSize"
        Write-Host -ForegroundColor DarkGray $Command
        Set-Clipboard -Value $Command
        Write-Output $Results | Format-Table -AutoSize
    }
    else {
        exit 0
    }
    #=================================================
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Done"
    #=================================================
}
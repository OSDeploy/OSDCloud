function Show-PEStartupHardwareErrors {
    [CmdletBinding()]
    param ()
    #=================================================
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    $Error.Clear()
    $host.ui.RawUI.WindowTitle = '[OSDCloud] Device Hardware with Errors (automatically close in 5 seconds)'
    #=================================================
    $Results = Get-CimInstance -ClassName Win32_PnPEntity | Select-Object Status, DeviceID, Name, Manufacturer, PNPClass, Service | Where-Object Status -ne 'OK' | Sort-Object Status, DeviceID

    if ($Results) {
        <#
        $USBDrive = Get-DeviceUSBVolume | Where-Object { ($_.FileSystemLabel -match "OSDCloud|USB-DATA") } | Where-Object { $_.SizeGB -ge 16 } | Where-Object { $_.SizeRemainingGB -ge 10 } | Select-Object -First 1
        if ($USBDrive) {
            [System.String]$SerialNumber = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber.Trim()
            $USBPath = "$($USBDrive.DriveLetter):\OSDCloudLogs\$SerialNumber\PEStartup"
            if (-not (Test-Path -Path $USBPath)) {
                New-Item -Path $USBPath -ItemType Directory -Force | Out-Null
            }
            $Results | Export-clixml -Path "$USBPath\HardwareErrors.xml" -Force
            $Results | Convertto-Json -Depth 10 | Out-File "$USBPath\HardwareErrors.json" -Force -Encoding UTF8
        }
        #>

        Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] WinPE Device Hardware with Errors"
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] This window will automatically close in 5 seconds"
        Write-Output $Results | Format-Table -AutoSize
        Start-Sleep -Seconds 5
    }
    exit 0
    #=================================================
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Done"
    #=================================================
}
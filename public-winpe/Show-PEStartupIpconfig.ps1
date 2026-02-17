function Show-PEStartupIpconfig {
    [CmdletBinding()]
    param ()
    #=================================================
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    $Error.Clear()
    $host.ui.RawUI.WindowTitle = '[OSDCloud] IPConfig - Network Configuration'
    #=================================================
    Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] ipconfig /all"
    ipconfig /all
    #=================================================
    <#
    $USBDrive = Get-DeviceUSBVolume | Where-Object { ($_.FileSystemLabel -match "OSDCloud|USB-DATA") } | Where-Object { $_.SizeGB -ge 16 } | Where-Object { $_.SizeRemainingGB -ge 10 } | Select-Object -First 1
    if ($USBDrive) {
        [System.String]$SerialNumber = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber.Trim()
        $USBPath = "$($USBDrive.DriveLetter):\OSDCloudLogs\$SerialNumber\PEStartup"
        if (-not (Test-Path -Path $USBPath)) {
            New-Item -Path $USBPath -ItemType Directory -Force | Out-Null
        }
        ipconfig /all | Out-File "$USBPath\ipconfig.txt" -Force -Encoding UTF8
    }
    #>
    #=================================================
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Done"
    #=================================================
}
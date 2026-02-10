function Use-PEStartupWifi {
    [CmdletBinding()]
    param ()
    #=================================================
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    $Error.Clear()
    $host.ui.RawUI.WindowTitle = '[OSDCloud] Wireless Connectivity'
    #=================================================
    if (Test-Path "$env:SystemRoot\System32\dmcmnutils.dll") {
        if ($WirelessConnect) {
            #TODO - Enable functionality for WirelessConnect.exe
            Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] Starting WirelessConnect.exe"
            Start-Process PowerShell -ArgumentList 'Invoke-OSDCloudWifi -WirelessConnect' -Wait
        }
        elseif ($WifiProfile) {
            #TODO - Enable functionality for WifiProfile
            Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] Starting WiFi Profile"
            $Global:WifiProfile = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -ne 'C' } | ForEach-Object {
                Get-ChildItem "$($_.Root)OSDCloud\Config\Scripts" -Include "WiFiProfile.xml" -File -Recurse -Force -ErrorAction Ignore
            }
            Start-Process PowerShell -ArgumentList "Invoke-OSDCloudWifi -WifiProfile `"$Global:WifiProfile`"" -Wait
        }
        else {
            Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] Starting Wi-Fi"
            Start-Process PowerShell Invoke-OSDCloudWifi -Wait
        }
    }

    Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] Initialize Network Connections"
    $timeout = 0
    while ($timeout -lt 20) {
        Start-Sleep -Seconds $timeout
        $timeout = $timeout + 5

        $IP = Test-Connection -ComputerName $(HOSTNAME) -Count 1 | Select-Object -ExpandProperty IPV4Address
        if ($null -eq $IP) {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Network adapter error. This should not happen!"
        }
        elseif ($IP.IPAddressToString.StartsWith('169.254') -or $IP.IPAddressToString.Equals('127.0.0.1')) {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] IP address not yet assigned by DHCP. Trying to get a new DHCP lease."
            ipconfig /release | Out-Null
            ipconfig /renew | Out-Null
        }
        else {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Network configuration renewed with IP: $($IP.IPAddressToString)"
            break
        }
    }
    #=================================================
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Done"
    #=================================================
}
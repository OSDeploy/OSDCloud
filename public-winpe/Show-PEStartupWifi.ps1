<#
.SYNOPSIS
Establishes and validates WiFi connectivity in Windows PE startup environment.

.DESCRIPTION
Manages WiFi network connectivity during WinPE startup by detecting available wireless interfaces and initiating connection. Supports three connection modes: WirelessConnect.exe, custom WiFi profile, or interactive WiFi selection. After establishing a connection, validates IP address assignment with automatic DHCP lease renewal if necessary. Includes timeout and retry logic to ensure network availability before returning.

.PARAMETER None
This function does not accept any parameters.

.EXAMPLE
Show-PEStartupWifi
Initiates WiFi connectivity startup, checking for wireless capability and establishing a network connection with IP validation.

.OUTPUTS
None. This function manages WiFi connectivity and displays status messages to the console but does not return objects.

.NOTES
This function is designed for use in Windows PE startup environments. It performs the following operations:

Prerequisites:
- Checks for dmcmnutils.dll in System32 (required for WiFi functionality)

Connection Modes (attempted in order):
1. WirelessConnect.exe: If $WirelessConnect variable is set
2. WiFi Profile: If $WifiProfile variable is set, searches removable drives for WiFiProfile.xml in OSDCloud\Config\Scripts
3. Interactive WiFi: Standard Invoke-OSDCloudWifi for manual network selection

Network Initialization:
- Validates IP addresses are properly assigned
- Detects APIPA addresses (169.254.x.x) indicating DHCP failure
- Automatically renews DHCP leases when necessary
- Retries with 5-second intervals up to 20 seconds total
- Updates window title throughout process

If dmcmnutils.dll is not found, the function skips WiFi connection and proceeds directly to network initialization.

The window title is updated to '[OSDCloud] - Wireless Connectivity' to show the current operation status.
#>
function Show-PEStartupWifi {
    [CmdletBinding()]
    param ()
    #=================================================
    $Error.Clear()
    $host.ui.RawUI.WindowTitle = '[OSDCloud] Wireless Connectivity'
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
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
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    #=================================================
}
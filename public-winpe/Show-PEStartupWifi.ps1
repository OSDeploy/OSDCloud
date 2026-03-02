<#
.SYNOPSIS
Establishes and validates Wi-Fi connectivity in Windows PE startup environment.

.DESCRIPTION
Manages Wi-Fi network connectivity during WinPE startup by detecting available wireless interfaces and initiating connection. Supports three connection modes: WirelessConnect.exe, custom Wi-Fi profile, or interactive Wi-Fi selection. After establishing a connection, validates IP address assignment with automatic DHCP lease renewal if necessary. Includes timeout and retry logic to ensure network availability before returning.

.PARAMETER None
This function does not accept any parameters.

.EXAMPLE
Show-PEStartupWifi
Initiates Wi-Fi connectivity startup, checking for wireless capability and establishing a network connection with IP validation.

.OUTPUTS
None. This function manages Wi-Fi connectivity and displays status messages to the console but does not return objects.

.NOTES
This function is designed for use in Windows PE startup environments. It performs the following operations:

Prerequisites:
- Checks for dmcmnutils.dll in System32 (required for Wi-Fi functionality)

Connection Modes (attempted in order):
1. WirelessConnect.exe: If $WirelessConnect variable is set
2. Wi-Fi Profile: If $WifiProfile variable is set, searches removable drives for WiFiProfile.xml in OSDCloud\Config\Scripts
3. Interactive Wi-Fi: Standard Invoke-OSDCloudWifi for manual network selection

Network Initialization:
- Validates IP addresses are properly assigned
- Detects APIPA addresses (169.254.x.x) indicating DHCP failure
- Automatically renews DHCP leases when necessary
- Retries with 5-second intervals up to 20 seconds total
- Updates window title throughout process

If dmcmnutils.dll is not found, the function skips Wi-Fi connection and proceeds directly to network initialization.

The window title is updated to '[OSDCloud] - Wireless Connectivity' to show the current operation status.
#>
function Show-PEStartupWifi {
    [CmdletBinding()]
    param ()
    #=================================================
    $Error.Clear()
    $host.ui.RawUI.WindowTitle = "[$(Get-Date -format s)] OSDCloud - WinPE Startup Wi-Fi"
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    #=================================================
    # Test-OSDCloudInternetConnection
    if (Test-OSDCloudInternetConnection -Uri 'google.com') {
        # Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Ping google.com success. Device is already connected to the Internet"
        $StartOSDCloudWifi = $false
    }
    else {
        # Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Ping google.com failed. Will attempt to connect to a Wireless Network"
        $StartOSDCloudWifi = $true
    }
    #=================================================
    # Test WinPE Required Components
    if ($StartOSDCloudWifi) {
        $RequiredDlls = @(
            'dmcmnutils.dll',
            'mdmpostprocessevaluator.dll',
            'mdmregistration.dll',
            'raschap.dll',
            'raschapext.dll',
            'rastls.dll',
            'rastlsext.dll'
        )
        
        $MissingDlls = @()
        foreach ($Dll in $RequiredDlls) {
            $DllPath = "$ENV:SystemRoot\System32\$Dll"
            if (!(Test-Path -Path $DllPath)) {
                $MissingDlls += $Dll
                $StartOSDCloudWifi = $false
            }
        }
        
        if (!$StartOSDCloudWifi) {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Unable to enable Wireless Network due to missing components"
            if ($MissingDlls.Count -gt 0) {
                Write-Host -ForegroundColor Yellow "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Missing DLL files: $($MissingDlls -join ', ')"
            }
        }
    }
    #=================================================
    # Invoke-OSDCloudWifi
    if ($StartOSDCloudWifi) {
        if ($WirelessConnect) {
            #TODO - Enable functionality for WirelessConnect.exe
            Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] Starting WirelessConnect.exe"
            Start-Process PowerShell -ArgumentList 'Invoke-OSDCloudWifi -WirelessConnect' -Wait
        }
        elseif ($WifiProfile) {
            #TODO - Enable functionality for Wi-Fi profile connection
            Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] Starting Wi-Fi Profile"
            $Global:WifiProfile = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -ne 'C' } | ForEach-Object {
                Get-ChildItem "$($_.Root)OSDCloud\Config\Scripts" -Include "WiFiProfile.xml" -File -Recurse -Force -ErrorAction Ignore
            }
            Start-Process PowerShell -ArgumentList "Invoke-OSDCloudWifi -WifiProfile `"$Global:WifiProfile`"" -Wait
        }
        else {
            Write-Verbose "[$(Get-Date -format s)] Starting Wi-Fi"
            # Start-Process PowerShell Invoke-OSDCloudWifi -Wait
            Invoke-OSDCloudWifi
            Start-Sleep -Seconds 2
        }
    }
    #=================================================
    # Initialize Network Connections
    Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] Initialize Network Connections"
    $timeout = 0
    while ($timeout -lt 20) {
        Start-Sleep -Seconds $timeout
        $timeout = $timeout + 5

        $IP = Test-Connection -ComputerName $(HOSTNAME) -Count 1 | Select-Object -ExpandProperty IPV4Address
        if ($null -eq $IP) {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Network adapter error. This should not happen!"
            Start-Sleep -Seconds 2
        }
        elseif ($IP.IPAddressToString.StartsWith('169.254') -or $IP.IPAddressToString.Equals('127.0.0.1')) {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] IP address not yet assigned by DHCP. Trying to get a new DHCP lease."
            ipconfig /release | Out-Null
            ipconfig /renew | Out-Null
            Start-Sleep -Seconds 2
        }
        else {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Network configuration renewed with IP: $($IP.IPAddressToString)"
            Start-Sleep -Seconds 2
            break
        }
    }
    Start-Sleep -Seconds 2
    #=================================================
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    #=================================================
}
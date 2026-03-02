<#
.SYNOPSIS
Establishes Wi-Fi connectivity in WinPE environment during OS deployment.

.DESCRIPTION
Manages Wi-Fi connection in Windows PE by testing for adapter availability, configuring wireless services, and connecting to available networks. Supports both automated connection via saved Wi-Fi profiles and interactive Wi-Fi network selection. Includes comprehensive checks for required WinPE components, wireless adapter detection, and connection validation with retry logic.

.PARAMETER WifiProfile
Specifies the path to a Wi-Fi profile XML file for unattended Wi-Fi connection. If provided and valid, the function attempts to connect using this profile without user interaction. If not provided or invalid, the function presents an interactive Wi-Fi network selection menu.

.PARAMETER WirelessConnect
Switch parameter to use the built-in WirelessConnect.exe utility for interactive Wi-Fi connection when available in WinPE. If not specified or unavailable, uses the Get-OSDCloudWifi menu for network selection.

.EXAMPLE
Invoke-OSDCloudWifi
Starts the Wi-Fi connection process interactively, displaying available Wi-Fi networks for selection.

.EXAMPLE
Invoke-OSDCloudWifi -WifiProfile 'C:\Temp\WifiProfile.xml'
Attempts to connect to Wi-Fi using the specified profile XML file without user interaction.

.EXAMPLE
Invoke-OSDCloudWifi -WirelessConnect
Uses the WirelessConnect.exe utility for interactive Wi-Fi connection if it exists in the WinPE environment.

.OUTPUTS
None. This function performs Wi-Fi connection setup and writes status messages to the host but does not return objects.

.NOTES
This function is designed specifically for Windows PE environments during OS deployment. It performs the following operations:

- Tests internet connectivity via Google.com
- Validates WinPE required components (DLL files for wireless support)
- Starts WlanSvc (Wireless LAN Service)
- Detects wireless network adapters
- Attempts to retrieve Wi-Fi profile from HP UEFI firmware if available
- Connects to networks either via stored profile or interactive selection
- Waits for IP configuration and network availability
- Creates transcript logs in $env:Temp\transcript-OSDCloudWifi.txt

Required WinPE Components:
  - dmcmnutils.dll
  - mdmpostprocessevaluator.dll
  - mdmregistration.dll
  - raschap.dll
  - raschapext.dll
  - rastls.dll
  - rastlsext.dll

If wireless adapters are not detected or drivers are missing, the function will report which devices have errors and may require driver additions to WinPE.
#>
function Invoke-OSDCloudWifi {
    [CmdletBinding()]
    param (
        [System.String]
        $WifiProfile,
        
        [System.Management.Automation.SwitchParameter]
        $WirelessConnect
    )
    #=================================================
    $Error.Clear()
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    #=================================================
    # Start-Transcript
    $LogsPath = "$env:TEMP\osdcloud-logs"

    $Params = @{
        Path        = $LogsPath
        ItemType    = 'Directory'
        Force       = $true
        ErrorAction = 'SilentlyContinue'
    }

    if (-not (Test-Path $Params.Path)) {
        New-Item @Params | Out-Null
    }

    $TranscriptFullName = Join-Path $LogsPath "OSDCloudWifi-$((Get-Date).ToString('yyyy-MM-dd-HHmmss')).log"
    $null = Start-Transcript -Path $TranscriptFullName -ErrorAction SilentlyContinue
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
    # Start-Service WlanSvc
    if ($StartOSDCloudWifi) {
        try {
            $WlanService = Get-Service -Name 'WlanSvc' -ErrorAction Stop

            if ($WlanService.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running) {
                Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] WlanSvc service is already running"
            }
            else {
                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Starting WlanSvc service from state '$($WlanService.Status)'"
                Start-Service -Name 'WlanSvc' -ErrorAction Stop

                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Waiting for WlanSvc service to start"
                $WlanService.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Running, [TimeSpan]::FromSeconds(30))
                $WlanService.Refresh()

                if ($WlanService.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Running) {
                    throw "WlanSvc did not reach the Running state within the timeout period."
                }

                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] WlanSvc service started successfully"
            }
        }
        catch [System.TimeoutException] {
            Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Timed out waiting for WlanSvc service to start"
            $StartOSDCloudWifi = $false
        }
        catch {
            Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Unable to start WlanSvc service: $($_.Exception.Message)"
            $StartOSDCloudWifi = $false
        }
    }
    #=================================================
    # Test Wi-Fi Adapter
    if ($StartOSDCloudWifi) {
        # Do we have a Wireless Interface? We have to search for different names as this will vary depending on the WinPE Language
        $SmbClientNetworkInterface = Get-SmbClientNetworkInterface | Where-Object { ($_.'FriendlyName' -match 'WiFi|Wi-Fi|Wireless|WLAN') } | Sort-Object -Property InterfaceIndex | Select-Object -First 1
        
        # Pair a Wireless Network Adapter based on the InterfaceIndex
        $WirelessNetworkAdapter = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object { $_.InterfaceIndex -eq $SmbClientNetworkInterface.InterfaceIndex }

        if ($WirelessNetworkAdapter) {
            $StartOSDCloudWifi = $true
            $WirelessNetworkAdapter | Select-Object * -ExcludeProperty Availability, Status, StatusInfo, Caption, Description, InstallDate, *Error*, *Power*, CIM*, System*, PS*, AutoSense, MaxSpeed, Index, TimeOfLastReset, MaxNumberControlled, Installed, NetworkAddresses,ConfigManager* | Format-List
        }
        else {
            # Get Network Devices with Error Status
            $PnPEntity = Get-WmiObject -ClassName Win32_PnPEntity | Where-Object { $_.Status -eq 'Error' } |  Where-Object { $_.Name -match 'Net' }
            Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] No Wireless Network Adapters were detected"
            if ($PnPEntity) {
                Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Drivers may need to be added to WinPE for the following hardware"
                foreach ($Item in $PnPEntity) {
                    Write-Warning "$($Item.Name): $($Item.DeviceID)"
                }
                Start-Sleep -Seconds 10
            }
            else {
                Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Drivers may need to be added to WinPE before Wireless Networking is available"
            }
            $StartOSDCloudWifi = $false
        }
    }
    #=================================================
    # Test UEFI Wi-Fi Profile
    if ($StartOSDCloudWifi){
        $Module = Import-Module UEFIv2 -PassThru -ErrorAction SilentlyContinue
        if ($Module) {
            $UEFIWifiProfile = Get-UEFIVariable -Namespace "{43B9C282-A6F5-4C36-B8DE-C8738F979C65}" -VariableName PrebootWifiProfile
            if ($UEFIWifiProfile) {
                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Found Wi-Fi Profile in HP UEFI"
                $UEFIWifiProfile = $UEFIWifiProfile -Replace "`0",""

                $SSIDString = $UEFIWifiProfile.Split(",") | Where-Object {$_ -match "SSID"}
                $SSID = ($SSIDString.Split(":") | Where-Object {$_ -notmatch "SSID"}).Replace("`"","")

                $KeyString = $UEFIWifiProfile.Split(",") | Where-Object {$_ -match "Password"}
                $Key = ($KeyString.Split(":") | Where-Object {$_ -notmatch "Password"}).Replace("`"","")
                if ($SSID) {
                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Found $SSID in UEFI, Attepting to Create Profile and Connect"
                    Set-OSDCloudWifi -WLanName $SSID -Passwd $Key -outfile "$env:TEMP\UEFIWifiProfile.XML"
                    if (!($WifiProfile)) {
                        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Setting WifiProfile var to $env:TEMP\UEFIWifiProfile.XML"
                        $WifiProfile = "$env:TEMP\UEFIWifiProfile.XML"
                    }
                }
            }
        }
    }
    #=================================================
    # Test Wi-Fi Connection
    #TODO Test on ARM64
    if ($StartOSDCloudWifi) {
        if ($WirelessNetworkAdapter.NetEnabled -eq $true) {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Wireless is already connected ... Disconnecting"
            (Get-WmiObject -ClassName Win32_NetworkAdapter | Where-Object { $_.InterfaceIndex -eq $WirelessNetworkAdapter.InterfaceIndex }).disable() | Out-Null
            Start-Sleep -Seconds 5
            (Get-WmiObject -ClassName Win32_NetworkAdapter | Where-Object { $_.InterfaceIndex -eq $WirelessNetworkAdapter.InterfaceIndex }).enable() | Out-Null
            Start-Sleep -Seconds 5
            $StartOSDCloudWifi = $true
        }
    }
    #=================================================
    # Connect
    if ($StartOSDCloudWifi) {
            if ($WifiProfile -and (Test-Path $WifiProfile)) {
                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Starting unattended Wi-Fi connection "
            }
            else {
                Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Starting Wi-Fi Network Menu "
            }

            # Use the Win32_NetworkAdapterConfiguration to check if the Wi-Fi adapter is IPEnabled
            while (((Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.Index -eq $($WirelessNetworkAdapter.DeviceID) }).IPEnabled -eq $false)) {
            Start-Sleep -Seconds 3

            $StartOSDCloudWifi = 0
            # make checks on start of evert cycle because in case of failure, profile will be deleted
            if ($WifiProfile -and (Test-Path $WifiProfile)) { ++$StartOSDCloudWifi }
    
            if ($StartOSDCloudWifi) {
                # use saved wi-fi profile to make the unattended connection
                try {
                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Establishing a connection using $WifiProfile"
                    Connect-OSDCloudWifiByXMLProfile $WifiProfile -ErrorAction Stop
                    Start-Sleep -Seconds 10
                }
                catch {
                    Write-Warning $_
                    # to avoid infinite loop of tries
                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Removing invalid Wi-Fi profile '$WifiProfile'"
                    Remove-Item $WifiProfile -Force
                    continue
                }
            }
            else {
                # show list of available SSID to make interactive connection
                if (($WirelessConnect) -and (Test-Path -path $ENV:SystemRoot\WirelessConnect.exe)) {
                    Start-Process -FilePath  $ENV:SystemRoot\WirelessConnect.exe -Wait
                }
                else {
                    $SSIDList = Get-OSDCloudWifi
                    if ($SSIDList) {
                        #show list of available SSID
                        $SSIDList | Sort-Object Index | Select-Object Signal, Index, SSID, Authentication, Encryption, NetworkType | Format-Table
            
                        $SSIDListIndex = $SSIDList.index
                        $SSIDIndex = ""
                        while ($SSIDIndex -notin $SSIDListIndex) {
                            $SSIDIndex = Read-Host "Select the Index of Wi-Fi Network to connect or CTRL+C to quit"
                        }
            
                        $SSID = $SSIDList | Where-Object { $_.index -eq $SSIDIndex } | Select-Object -exp SSID
            
                        # connect to selected Wi-Fi
                        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Establishing a connection to SSID $SSID"
                        try {
                            Connect-OSDCloudWifi $SSID -ErrorAction Stop
                        } catch {
                            Write-Warning $_
                            continue
                        }
                    } else {
                        Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] No Wi-Fi network found. Move closer to AP or use ethernet cable instead."
                    }
                }
            }

            if ($StartOSDCloudWifi) {
                $text = "to Wi-Fi using $WifiProfile"
            } else {
                $text = "to SSID $SSID"
            }
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Waiting for a connection $text"
            Start-Sleep -Seconds 15
        
            $i = 30
            #TODO Resolve issue with WirelessNetworkAdapter
            while (((Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.Index -eq $($WirelessNetworkAdapter.DeviceID) }).IPEnabled -eq $false) -and $i -gt 0) {
                --$i
                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Waiting for Wi-Fi Connection ($i)"
                Start-Sleep -Seconds 1
            }
        }
        Get-SmbClientNetworkInterface | Where-Object { ($_.FriendlyName -match 'WiFi|Wi-Fi|Wireless|WLAN') } | Format-List
    }
    $null = Stop-Transcript -ErrorAction Ignore
    if ($StartOSDCloudWifi) {
        Start-Sleep -Seconds 5
    }
}
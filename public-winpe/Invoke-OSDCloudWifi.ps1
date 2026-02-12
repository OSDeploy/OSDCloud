function Invoke-OSDCloudWifi {
    [CmdletBinding()]
    param (
        [System.String]
        $wifiProfile,
        
        [System.Management.Automation.SwitchParameter]
        $WirelessConnect
    )
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    #=================================================
    #	Transcript
    #=================================================        
    $TranscriptPath = "$env:Temp"
    if (!(Test-Path -path $TranscriptPath)){
        New-Item -Path $TranscriptPath -ItemType Directory -Force | Out-Null
    }
    $null = Start-Transcript -Path "$TranscriptPath\transcript-OSDCloudWifi.txt" -ErrorAction Ignore
    #=================================================
    #	Test Internet Connection
    #=================================================
    if (Test-OSDCloudInternetConnection -Uri 'google.com') {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Ping google.com success. Device is already connected to the Internet"
        $StartOSDCloudWifi = $false
    }
    else {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Ping google.com failed. Will attempt to connect to a Wireless Network"
        $StartOSDCloudWifi = $true
    }
    #=================================================
    #   Test WinRE
    #=================================================
    if ($StartOSDCloudWifi) {
        if (!(Test-Path "$ENV:SystemRoot\System32\dmcmnutils.dll")) {
            $StartOSDCloudWifi = $false
        }
        if (!(Test-Path "$ENV:SystemRoot\System32\mdmpostprocessevaluator.dll")) {
            $StartOSDCloudWifi = $false
        }
        if (!(Test-Path "$ENV:SystemRoot\System32\mdmregistration.dll")) {
            $StartOSDCloudWifi = $false
        }
        if (!(Test-Path "$ENV:SystemRoot\System32\raschap.dll")) {
            $StartOSDCloudWifi = $false
        }
        if (!(Test-Path "$ENV:SystemRoot\System32\raschapext.dll")) {
            $StartOSDCloudWifi = $false
        }
        if (!(Test-Path "$ENV:SystemRoot\System32\rastls.dll")) {
            $StartOSDCloudWifi = $false
        }
        if (!(Test-Path "$ENV:SystemRoot\System32\rastlsext.dll")) {
            $StartOSDCloudWifi = $false
        }
        if ($StartOSDCloudWifi) {
        }
        else {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Unable to enable Wireless Network due to missing components"
        }
    }
    #=================================================
    #	WlanSvc
    #=================================================
    if ($StartOSDCloudWifi) {
        if (Get-Service -Name WlanSvc) {
            if ((Get-Service -Name WlanSvc).Status -ne 'Running') {
                Get-Service -Name WlanSvc | Start-Service
                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Waiting for WlanSvc service to start"
                (Get-Service WlanSvc).WaitForStatus('Running')
            }
        }
    }
    #=================================================
    #	Test Wi-Fi Adapter
    #=================================================
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
    #   Test UEFI WiFi Profile
    #=================================================
    if ($StartOSDCloudWifi){
        $Module = Import-Module UEFIv2 -PassThru -ErrorAction SilentlyContinue
        if ($Module) {
            $UEFIWiFiProfile = Get-UEFIVariable -Namespace "{43B9C282-A6F5-4C36-B8DE-C8738F979C65}" -VariableName PrebootWiFiProfile
            if ($UEFIWiFiProfile) {
                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Found WiFi Profile in HP UEFI"
                $UEFIWiFiProfile = $UEFIWiFiProfile -Replace "`0",""

                $SSIDString = $UEFIWiFiProfile.Split(",") | Where-Object {$_ -match "SSID"}
                $SSID = ($SSIDString.Split(":") | Where-Object {$_ -notmatch "SSID"}).Replace("`"","")

                $KeyString = $UEFIWiFiProfile.Split(",") | Where-Object {$_ -match "Password"}
                $Key = ($KeyString.Split(":") | Where-Object {$_ -notmatch "Password"}).Replace("`"","")
                if ($SSID) {
                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Found $SSID in UEFI, Attepting to Create Profile and Connect"
                    Set-OSDCloudWifi -WLanName $SSID -Passwd $Key -outfile "$env:TEMP\UEFIWiFiProfile.XML"
                    if (!($wifiProfile)) {
                        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Setting wifiprofile var to $env:TEMP\UEFIWiFiProfile.XML"
                        $wifiProfile = "$env:TEMP\UEFIWiFiProfile.XML"
                    }
                }
            }
        }
    }
    #=================================================
    #	Test Wi-Fi Connection
    #=================================================
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
    #   Connect
    #=================================================
    if ($StartOSDCloudWifi) {
            if ($wifiProfile -and (Test-Path $wifiProfile)) {
                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Starting unattended Wi-Fi connection "
            }
            else {
                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Starting Wi-Fi Network Menu "
            }

            # Use the Win32_NetworkAdapterConfiguration to check if the Wi-Fi adapter is IPEnabled
            while (((Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.Index -eq $($WirelessNetworkAdapter.DeviceID) }).IPEnabled -eq $false)) {
            Start-Sleep -Seconds 3

            $StartOSDCloudWifi = 0
            # make checks on start of evert cycle because in case of failure, profile will be deleted
            if ($wifiProfile -and (Test-Path $wifiProfile)) { ++$StartOSDCloudWifi }
    
            if ($StartOSDCloudWifi) {
                # use saved wi-fi profile to make the unattended connection
                try {
                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Establishing a connection using $wifiProfile"
                    Connect-OSDCloudWifiByXMLProfile $wifiProfile -ErrorAction Stop
                    Start-Sleep -Seconds 10
                }
                catch {
                    Write-Warning $_
                    # to avoid infinite loop of tries
                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Removing invalid Wi-Fi profile '$wifiProfile'"
                    Remove-Item $wifiProfile -Force
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
                $text = "to Wi-Fi using $wifiProfile"
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
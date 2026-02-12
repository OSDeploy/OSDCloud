function Connect-OSDCloudWifi {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $SSID
    )

    $network = Get-OSDCloudWifi | Where-Object { $_.SSID -eq $SSID }

    $password = ""

    if ($network.Authentication -ne "Open") {
        $cred = Get-Credential -Message "Enter password for WIFI network '$SSID'" -UserName $SSID
        $password = $cred.GetNetworkCredential().password
    }

    #TODO Add more modes like WEP or enterprise here:
    if ($network.Authentication -eq "WPA-Personal") {
        $authmode = "WPAPSK"
        $encmode = "AES"
    }

    # It's for WPA3 networks with WPA2 fallback. You still want to try WPA2 if your radio SOC is not able to use WPA3
    if (($network.Authentication -eq "WPA2-Personal") -or ($network.Authentication -eq "WPA3-Personal")) {
        $authmode = "WPA2PSK"
        $encmode = "AES"
    }
    
    # Checks if your card is able to do WPA3
    if (($network.Authentication -eq "WPA3-Personal") -and (netsh wlan show driver | Select-String -Pattern "WPA3-Personal")) {
        $authmode = "WPA3SAE"
        $encmode = "AES"
    }

    # just for sure
    $null = Netsh WLAN delete profile "$SSID"

    # create new network profile
    $param = @{
        WLanName = $SSID
    }
    if ($password) { $param.Passwd = $password }
    if ($authmode) { $param.WPA = $true }
    Set-OSDCloudWifi @param

    # connect to network
    $result = Netsh WLAN connect name="$SSID"
    if ($result -ne "Connection request was completed successfully.") {
        throw "Connection to WIFI wasn't successful. Error was $result"
    }
}
function Connect-OSDCloudWifiByXMLProfile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript( {
            if (Test-Path -Path $_) {
                $true
            } else {
                throw "$_ doesn't exists"
            }
            if ($_ -notmatch "\.xml$") {
                throw "$_ isn't xml file"
            }
            if (!(([xml](Get-Content $_ -Raw)).WLANProfile.Name) -or (([xml](Get-Content $_ -Raw)).WLANProfile.MSM.security.sharedKey.protected) -ne "false") {
                throw "$_ isn't valid Wi-Fi XML profile (is the password correctly in plaintext?). Use command like this, to create it: netsh wlan export profile name=`"MyWifiSSID`" key=clear folder=C:\Wifi"
            }
        })]
        [string] $wifiProfile
    )
    
    $SSID = ([xml](Get-Content $wifiProfile)).WLANProfile.Name
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Connecting to $SSID"

    # just for sure
    $null = Netsh WLAN delete profile "$SSID"

    # import wifi profile
    $null = Netsh WLAN add profile filename="$wifiProfile"

    # connect to network
    $result = Netsh WLAN connect name="$SSID"
    if ($result -ne "Connection request was completed successfully.") {
        throw "Connection to WIFI wasn't successful. Error was $result"
    }
}
function Get-OSDCloudWifi {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        $SSID
    )
    $response = netsh wlan show networks mode=bssid
    $wLANs = $response | Where-Object { $_ -match "^SSID" } | ForEach-Object {
        $report = "" | Select-Object SSID, Index, NetworkType, Authentication, Encryption, Signal
        $i = $response.IndexOf($_)
        $report.SSID = $_ -replace "^SSID\s\d+\s:\s", ""
        $report.Index = $i
        $report.NetworkType = $response[$i + 1].Split(":")[1].Trim()
        $report.Authentication = $response[$i + 2].Split(":")[1].Trim()
        $report.Encryption = $response[$i + 3].Split(":")[1].Trim()
        $report.Signal = $response[$i + 5].Split(":")[1].Trim()
        $report
    }
    if ($SSID) {
        $wLANs | Where-Object { $_.SSID -eq $SSID }
    } else {
        $wLANs
    }
}
function Set-OSDCloudWifi() {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Please add Wireless network name")]
        [System.String]
        $WLanName,
        
        [System.String]
        $Passwd,
        
        [Parameter(Mandatory = $false, HelpMessage = "This switch will generate a WPA profile instead of WPA2")]
        [System.Management.Automation.SwitchParameter]
        $WPA = $false,

        [Parameter(Mandatory = $false, HelpMessage = "This switch will generate XML Profile File")]
        [System.String]
        $OutFile = "$env:TEMP/WiFiProfile.xml"
    )

    if ($Passwd) {
        # escape XML special characters
        $Passwd = [System.Security.SecurityElement]::Escape($Passwd)
    }

$XMLProfile = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
      <name>$WlanName</name>
      <SSIDConfig>
         <SSID>
              <name>$WLanName</name>
          </SSID>
     </SSIDConfig>
     <connectionType>ESS</connectionType>
     <connectionMode>auto</connectionMode>
     <MSM>
         <security>
             <authEncryption>
                 <authentication>$authmode</authentication>
                 <encryption>$encmode</encryption>
                 <useOneX>false</useOneX>
             </authEncryption>
             <sharedKey>
                 <keyType>passPhrase</keyType>
                 <protected>false</protected>
				<keyMaterial>$Passwd</keyMaterial>
			</sharedKey>
		</security>
	</MSM>
</WLANProfile>
"@

    if ($Passwd -eq "") {
$XMLProfile = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
	<name>$WLanName</name>
	<SSIDConfig>
		<SSID>
			<name>$WLanName</name>
		</SSID>
	</SSIDConfig>
	<connectionType>ESS</connectionType>
	<connectionMode>manual</connectionMode>
	<MSM>
		<security>
			<authEncryption>
				<authentication>open</authentication>
				<encryption>none</encryption>
				<useOneX>false</useOneX>
			</authEncryption>
		</security>
	</MSM>
	<MacRandomization xmlns="http://www.microsoft.com/networking/WLAN/profile/v3">
		<enableRandomization>false</enableRandomization>
	</MacRandomization>
</WLANProfile>
"@
    }

    $WLanName = $WLanName -replace "\s+"
    $WlanConfig = "$env:TEMP\$WLanName.xml"
    $XMLProfile | Set-Content $WlanConfig
    if ($OutFile){
        Copy-Item $WlanConfig -Destination $OutFile
    }
    $result = Netsh WLAN add profile filename=$WlanConfig
    Remove-Item $WlanConfig -ErrorAction SilentlyContinue
    if ($result -notmatch "is added on interface") {
        throw "There was en error when setting up WIFI $WLanName connection profile. Error was $result"
    }
}
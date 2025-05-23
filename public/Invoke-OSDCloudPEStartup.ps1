function Invoke-OSDCloudPEStartup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet(
            'OSK',
            'DeviceHardware',
            'Info',
            'IPConfig',
            'UpdateModule',
            'WiFi'
        )]
        [System.String]
        $Id,

        [Parameter(Position = 1)]
        [System.String]
        $Value
    )
    Start-Transcript -Path "$($env:Temp)\OSDCloudPEStartup.log" -Append -Force -ErrorAction SilentlyContinue
    Write-Host "Processing $Id with value $Value"

    switch ($Id) {
        'OSK' {
            # Make sure osk.exe is available
            if (Get-Command -Name 'osk.exe' -ErrorAction SilentlyContinue) {
                # Invoke-OSDCloudPEStartupCommand Use-PEStartupOSK -WindowStyle Hidden
                Start-Process -FilePath 'osk.exe' -WindowStyle Minimized
            }
        }
        'DeviceHardware' {
            Invoke-OSDCloudPEStartupCommand Use-PEStartupHardware -WindowStyle Minimized -NoExit
            Invoke-OSDCloudPEStartupCommand Use-PEStartupHardwareErrors -WindowStyle Maximized -NoExit -Wait
        }
        'WiFi' {
            # If we can reach the PowerShell Gallery, we can assume we have a network connection
            try {
                $WebRequest = Invoke-WebRequest -Uri "https://www.powershellgallery.com" -UseBasicParsing -Method Head
            }
            catch {
                Invoke-OSDCloudPEStartupCommand Use-PEStartupWiFi -Wait
            }
        }
        'IPConfig' {
            Invoke-OSDCloudPEStartupCommand Use-PEStartupIpconfig -Run Asynchronous -WindowStyle Minimized -NoExit
        }
        'UpdateModule' {
            # Value must be specified for this function to work
            if ($Value) {
                # Make sure we are online and can reach the PowerShell Gallery
                try {
                    $WebRequest = Invoke-WebRequest -Uri "https://www.powershellgallery.com/packages/$Value" -UseBasicParsing -Method Head
                }
                catch {
                    Write-Host "UpdateModule: Unable to reach the PowerShell Gallery. Please check your network connection."
                    return
                }
                Invoke-OSDCloudPEStartupUpdateModule -Name $Value -Wait
            }
        }
        'Info' {
            Invoke-OSDCloudPEStartupCommand Use-PEStartupDeviceInfo -NoExit -Wait
        }
    }
}
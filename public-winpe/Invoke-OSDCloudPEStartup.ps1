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
    # Start-Transcript -Path "$($env:Temp)\OSDCloudPEStartup.log" -Append -Force -ErrorAction SilentlyContinue
    # Write-Host "Processing $Id with value $Value"

    switch ($Id) {
        'OSK' {
            # OSK should not be launched if a physical keyboard is detected. This is common on tablets and some laptops that may be running WinPE without a keyboard attached
            if (Get-CimInstance -ClassName Win32_Keyboard -ErrorAction SilentlyContinue) {
                Write-Host "OSDCloud OSK: Keyboard detected. Not launching On-Screen Keyboard."
            }
            else {
                # osk.exe is not present in all versions of WinPE, so check for it before trying to launch it
                if (Get-Command -Name 'osk.exe' -ErrorAction SilentlyContinue) {
                    Write-Host "OSDCloud OSK: Keyboard not detected. Launching On-Screen Keyboard."
                    Start-Process -FilePath 'osk.exe' -WindowStyle Minimized
                    # Invoke-PEStartupCommand Invoke-PEStartupOSK -WindowStyle Hidden
                }
                else {
                    Write-Host "OSDCloud OSK: Unable to launch On-Screen Keyboard due to osk.exe not found."
                    Write-Host "OSDCloud OSK: OSDWorkspace should be used to create WinPE to resolve this issue."
                }
            }
        }
        'DeviceHardware' {
            Invoke-PEStartupCommand Show-PEStartupHardware -WindowStyle Minimized -NoExit
            Invoke-PEStartupCommand Show-PEStartupHardwareErrors -WindowStyle Maximized -NoExit -Wait
        }
        'WiFi' {
            # If we can reach the PowerShell Gallery, we can assume we have a network connection
            try {
                $null = Invoke-WebRequest -Uri "https://www.powershellgallery.com" -UseBasicParsing -Method Head
                Write-Host "OSDCloud WiFi: Network connection detected. Not launching WiFi connection."
            }
            catch {
                Write-Host "OSDCloud WiFi: Network connection not detected. Launching WiFi connection."
                Invoke-PEStartupCommand Show-PEStartupWifi -Wait
            }
        }
        'IPConfig' {
            Write-Host "OSDCloud IPConfig: Launching IPConfig in minimized window."
            Invoke-PEStartupCommand Show-PEStartupIpconfig -Run Asynchronous -WindowStyle Minimized -NoExit
        }
        'UpdateModule' {
            # Value must be specified for this function to work
            if ($Value) {
                # Make sure we are online and can reach the PowerShell Gallery
                try {
                    $null = Invoke-WebRequest -Uri "https://www.powershellgallery.com/packages/$Value" -UseBasicParsing -Method Head
                }
                catch {
                    Write-Host "UpdateModule: Unable to reach the PowerShell Gallery. Please check your network connection."
                    return
                }
                Invoke-PEStartupUpdateModule -Name $Value -Wait
            }
        }
        'Info' {
            Invoke-PEStartupCommand Show-PEStartupDeviceInfo -NoExit -Wait
        }
    }
}
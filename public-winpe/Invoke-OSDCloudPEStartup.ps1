<#
.SYNOPSIS
Invokes various startup utilities and commands in Windows PE environment.

.DESCRIPTION
Executes predefined startup actions within WinPE, including hardware detection, network configuration, module updates, and system information display. This function provides a centralized way to trigger common PE startup tasks with appropriate validation and error handling.

.PARAMETER Id
Specifies the startup action to invoke. Valid values are:
- 'OSK': Launches the On-Screen Keyboard if no physical keyboard is detected
- 'DeviceHardware': Displays hardware information and hardware errors
- 'Info': Shows comprehensive device information
- 'IPConfig': Displays network configuration in a minimized window
- 'UpdateModule': Updates a PowerShell module from the PowerShell Gallery (requires -Value parameter)
- 'WiFi': Launches WiFi connection utility if no network is detected

.PARAMETER Value
Optional parameter used by the UpdateModule action to specify the name of the module to update. Required when Id is 'UpdateModule'.

.EXAMPLE
Invoke-OSDCloudPEStartup -Id OSK
Launches the On-Screen Keyboard if no physical keyboard is present.

.EXAMPLE
Invoke-OSDCloudPEStartup -Id DeviceHardware
Displays device hardware information and any hardware errors.

.EXAMPLE
Invoke-OSDCloudPEStartup -Id UpdateModule -Value 'OSDCloud'
Updates the OSDCloud module from the PowerShell Gallery.

.EXAMPLE
Invoke-OSDCloudPEStartup -Id WiFi
Launches the WiFi connection utility if network connectivity is unavailable.

.EXAMPLE
Invoke-OSDCloudPEStartup -Id IPConfig
Displays IP configuration information in a minimized window.

.OUTPUTS
None. This function performs startup actions and displays output to the console but does not return objects.

.NOTES
This function is designed for use in WinPE environments during the OS deployment process. Some features like osk.exe may not be available in all WinPE versions.
#>
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
    switch ($Id) {
        'OSK' {
            # OSK should not be launched if a physical keyboard is detected
            if (Get-CimInstance -ClassName Win32_Keyboard -ErrorAction SilentlyContinue) {
                Write-Host "OSDCloud OSK: Keyboard detected. Not launching On-Screen Keyboard."
            }
            else {
                # osk.exe is not present in all versions of WinPE, so check for it before trying to launch it
                if (Get-Command -Name 'osk.exe' -ErrorAction SilentlyContinue) {
                    Write-Host "OSDCloud OSK: Keyboard not detected. Launching On-Screen Keyboard."
                    Start-Process -FilePath 'osk.exe' -WindowStyle Minimized
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
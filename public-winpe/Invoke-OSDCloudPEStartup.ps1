<#
.SYNOPSIS
    Invokes startup tasks and utilities for OSDCloud Windows PE environments.

.DESCRIPTION
    Invoke-OSDCloudPEStartup provides quick access to various diagnostic and utility functions
    within Windows PE. It can launch system information displays, network configuration tools,
    the on-screen keyboard, hardware detection utilities, and manage module updates.
    
    This function is designed to be used in Windows PE startup sequences and automation workflows.

.PARAMETER Id
    Specifies the startup task or utility to invoke. Valid values are:
    - OSK: Launches the On-Screen Keyboard (if keyboard not detected and available)
    - DeviceHardware: Displays hardware information and errors
    - Info: Shows comprehensive device information
    - IPConfig: Launches the IP configuration utility
    - WiFi: Initiates Wi-Fi connection setup (if network not detected)
    - UpdateModule: Updates a specified PowerShell module from the PowerShell Gallery

.PARAMETER Value
    Optional parameter used by the UpdateModule action to specify the module name to update.
    Required when Id is set to 'UpdateModule'.

.EXAMPLE
    Invoke-OSDCloudPEStartup -Id OSK
    Launches the On-Screen Keyboard if a physical keyboard is not detected.

.EXAMPLE
    Invoke-OSDCloudPEStartup -Id DeviceHardware
    Displays hardware information and any hardware errors.

.EXAMPLE
    Invoke-OSDCloudPEStartup -Id Info
    Shows comprehensive device information.

.EXAMPLE
    Invoke-OSDCloudPEStartup -Id IPConfig
    Launches the IP configuration utility in a minimized window.

.EXAMPLE
    Invoke-OSDCloudPEStartup -Id WiFi
    Initiates Wi-Fi connection setup if network connectivity is not detected.

.EXAMPLE
    Invoke-OSDCloudPEStartup -Id UpdateModule -Value OSDCloud
    Updates the OSDCloud module from the PowerShell Gallery.

.NOTES
    - The OSK action requires osk.exe to be available in the Windows PE environment
    - The WiFi action checks for network connectivity by attempting to reach powershellgallery.com
    - The UpdateModule action requires internet connectivity to reach the PowerShell Gallery
    - This function uses verbose output for diagnostic logging

.OUTPUTS
    None. This function does not return objects to the pipeline.

.LINK
    https://github.com/OSDeploy/OSDCloud
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
    #=================================================
    $Error.Clear()
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    #=================================================
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
                Write-Host "OSDCloud Wi-Fi: Network connection detected. Not launching Wi-Fi connection."
            }
            catch {
                Write-Host "OSDCloud Wi-Fi: Network connection not detected. Launching Wi-Fi connection."
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
                    Write-Host "OSDCloud UpdateModule: Unable to reach the PowerShell Gallery. Please check your network connection."
                    return
                }
                Invoke-PEStartupUpdateModule -Name $Value -Wait
            }
        }
        'Info' {
            Invoke-PEStartupCommand Show-PEStartupDeviceInfo -NoExit -Wait
        }
    }
    #=================================================
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    #=================================================
}
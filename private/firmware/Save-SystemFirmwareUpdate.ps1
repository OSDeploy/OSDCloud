function Save-SystemFirmwareUpdate {
    [CmdLetBinding()]
    param (
        [String]$DestinationDirectory = "$env:TEMP\SystemFirmwareUpdate"
    )
    #=================================================
    #	MSCatalog PowerShell Module
    #   Ryan-Jan
    #   https://github.com/ryan-jan/MSCatalog
    #   This excellent work is a good way to gather information from MS
    #   Catalog
    #=================================================
    if (!(Get-Module -ListAvailable -Name MSCatalog)) {
        Install-Module MSCatalog -SkipPublisherCheck -Force -ErrorAction Ignore
    }
    #=================================================
    if (Test-MicrosoftUpdateCatalog) {
        if (Get-Module -ListAvailable -Name MSCatalog -ErrorAction Ignore) {
            $SystemFirmwareUpdate = Get-SystemFirmwareUpdate
        
            if ($SystemFirmwareUpdate.Guid) {
                Write-Host -ForegroundColor DarkGray "$($SystemFirmwareUpdate.Title) version $($SystemFirmwareUpdate.Version)"
                Write-Host -ForegroundColor DarkGray "Version $($SystemFirmwareUpdate.Version) Size: $($SystemFirmwareUpdate.Size)"
                Write-Host -ForegroundColor DarkGray "Last Updated $($SystemFirmwareUpdate.LastUpdated)"
                Write-Host -ForegroundColor DarkGray "UpdateID: $($SystemFirmwareUpdate.Guid)"
                Write-Host -ForegroundColor DarkGray ""
            }
        
            if ($SystemFirmwareUpdate) {
                $SystemFirmwareUpdateFile = Save-MicrosoftUpdateCatalogUpdate -Guid $SystemFirmwareUpdate.Guid -DestinationDirectory $DestinationDirectory
                if ($SystemFirmwareUpdateFile) {
                    expand.exe "$($SystemFirmwareUpdateFile.FullName)" -F:* "$DestinationDirectory"
                    Remove-Item $SystemFirmwareUpdateFile.FullName | Out-Null
                    if ($env:SystemDrive -eq 'X:') {
                        #Write-Host -ForegroundColor DarkGray "You can install the firmware by running the following command"
                        #Write-Host -ForegroundColor DarkGray "Add-WindowsDriver -Path C:\ -Driver $DestinationDirectory"
                    }
                    else {
                        #Write-Host -ForegroundColor DarkGray "Make sure Bitlocker is suspended first before installing the Firmware Driver"
                        if (Test-Path "$DestinationDirectory\firmware.inf") {
                            #Write-Host -ForegroundColor DarkGray "Right click on $DestinationDirectory\firmware.inf and Install"
                        }
                    }
                }
                else {
                    Write-Host -ForegroundColor DarkGray "Save-SystemFirmwareUpdate: Could not find a UEFI Firmware update for this HardwareID"
                }
            }
            else {
                Write-Host -ForegroundColor DarkGray "Save-SystemFirmwareUpdate: Could not find a UEFI Firmware HardwareID"
            }
        }
        else {
            Write-Host -ForegroundColor DarkGray "Save-SystemFirmwareUpdate: Could not install required PowerShell Module MSCatalog"
        }
    }
    else {
        Write-Host -ForegroundColor DarkGray "Save-SystemFirmwareUpdate: Could not reach https://www.catalog.update.microsoft.com/"
    }
    #=================================================
}
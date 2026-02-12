function Save-MicrosoftUpdateCatalogDriver {
    [CmdletBinding(DefaultParameterSetName = 'ByPNPClass')]
    param (
        [System.String]$DestinationDirectory,

        [Parameter(ParameterSetName = 'ByHardwareID')]
        [System.String[]]$HardwareID,

        [Parameter(ParameterSetName = 'ByPNPClass')]
        [ValidateSet('DiskDrive','Display','Net','SCSIAdapter','SecurityDevices','USB')]
        [System.String]$PNPClass
    )
    #=================================================
    if (!($DestinationDirectory)) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Set the DestinationDirectory parameter to download the Drivers"
    }
    else {
        if (!(Test-Path $DestinationDirectory)){
            New-Item -Path $DestinationDirectory -ItemType Directory -Force | Out-Null
        }
    }
    #=================================================
    #	MSCatalog PowerShell Module
    #   Ryan-Jan
    #   https://github.com/ryan-jan/MSCatalog
    #   This excellent work is a good way to gather information from MS
    #   Catalog
    #=================================================
<#     if (!(Get-Module -ListAvailable -Name MSCatalog)) {
        Install-Module MSCatalog -Force -SkipPublisherCheck -ErrorAction Ignore
    } #>
    #=================================================
    $HardwareIDPattern = 'v[ei][dn]_([0-9a-f]){4}&[pd][ie][dv]_([0-9a-f]){4}'
    $SurfaceIDPattern = 'mshw0[0-1]([0-9]){2}'

    if (-not (Test-MicrosoftUpdateCatalog)) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Unable to reach Microsoft Update Catalog, exiting function"
        return
    }

    # Initialize hashtable to track searched HardwareIDs to avoid duplicates
    $SearchedHardwareIDs = @{}

    #=================================================
    #	ByPNPClass
    #=================================================
    if ($PSCmdlet.ParameterSetName -eq 'ByPNPClass') {
        Write-Verbose "[$(Get-Date -format s)] ByPNPClass"

        $Params = @{
            ClassName = 'Win32_PnpEntity' 
            Property = 'Name','Description','DeviceID','HardwareID','ClassGuid','Manufacturer','PNPClass'
        }
        $Devices = Get-CimInstance @Params

        if ($Devices) {
            if ($PNPClass -match 'Display') {
                $Devices = $Devices | Where-Object {($_.Name -match 'Video') -or ($_.PNPClass -match 'Display')}
            }
            elseif ($PNPClass -match 'Net') {
                $Devices = $Devices | Where-Object {($_.Name -match 'Network') -or ($_.PNPClass -match 'Net')}
            }
            elseif ($PNPClass) {
                $Devices = $Devices | Where-Object {$_.PNPClass -match $PNPClass}
            }
            else {
                # No parameters were pecified, so all devices will be processed
            }
        }
        else {
            Write-Verbose "[$(Get-Date -format s)] PNP Devices were not found on the system"
        }

        if ($Devices) {
            if ($PNPClass) {
                Write-Verbose "[$(Get-Date -format s)] Devices were found for PNPClass $PNPClass"
            }
            else {
                Write-Verbose "[$(Get-Date -format s)] Devices were found for all PNPClasses"
            }

            # Process all devices
            foreach ($Item in $Devices) {
                Write-Verbose "[$(Get-Date -format s)] $Item"

                $WindowsUpdateDriver = $null
                $FindHardwareID = $null

                # Determine if the input is a HardwareID or SurfaceID pattern, and extract the relevant portion for searching
                Write-Verbose "[$(Get-Date -format s)] Try matching DeviceID to HardwareID pattern: $HardwareIDPattern"
                Write-Verbose "[$(Get-Date -format s)] DeviceID: $($Item.DeviceID)"
                $FindHardwareID = $Item.DeviceID | Select-String -Pattern $HardwareIDPattern -AllMatches | Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Value
                
                if (-NOT $FindHardwareID) {
                    if ($Item.HardwareID) {
                        Write-Verbose "[$(Get-Date -format s)] HardwareID: $($Item.HardwareID[0])"
                        $FindHardwareID = $Item.HardwareID[0] | Select-String -Pattern $HardwareIDPattern -AllMatches | Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Value
                    }
                }

                if ($FindHardwareID) {
                    # Check if we have already searched for this HardwareID
                    if ($SearchedHardwareIDs.ContainsKey($FindHardwareID)) {
                        Write-Verbose "[$(Get-Date -format s)] Skipping duplicate search for: $FindHardwareID"
                        continue
                    }

                    # Mark this HardwareID as searched
                    $SearchedHardwareIDs[$FindHardwareID] = $true

                    Write-Verbose "[$(Get-Date -format s)] Search: $FindHardwareID"
                    $SearchString = "$FindHardwareID".Replace('&',"`%26")

                    try {
                        # Define version search order (newest to oldest)
                        $VersionSearchOrder = @('25H2', '24H2', '23H2', '22H2', '21H2', 'Vibranium', '1903', '1809')

                        # Search for driver with version-specific queries first
                        foreach ($Version in $VersionSearchOrder) {
                            $WindowsUpdateDriver = Get-MicrosoftUpdateCatalogResult -Search "$Version+$PNPClass+$SearchString" -Descending |
                                Select-Object LastUpdated, Title, Version, Size, Guid -First 1 -ErrorAction Ignore
                            
                            if ($WindowsUpdateDriver) {
                                Write-Verbose "Found driver match for version: $Version"
                                break
                            }
                        }
    
                        if ($WindowsUpdateDriver.Guid) {
                            Write-Host -ForegroundColor DarkGreen "[$(Get-Date -format s)] $($WindowsUpdateDriver.Title)"
                            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] UpdateID: $($WindowsUpdateDriver.Guid)"
                            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Last Updated $($WindowsUpdateDriver.LastUpdated) Version $($WindowsUpdateDriver.Version) Size: $($WindowsUpdateDriver.Size)"

                            if ($Item.Name -and $Item.PNPClass) {
                                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] $($Item.PNPClass) $($Item.Name)"
                            }
                            elseif ($Item.Name) {
                                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] $($Item.Name)"
                            }
                            else {
                                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] $($Item.DeviceID)"
                            }
                            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] HardwareID: $FindHardwareID"
                            Write-Verbose "[$(Get-Date -format s)] SearchString: $SearchString"

                            if ($DestinationDirectory) {
                                $ExpandedLocalFolder = Join-Path $DestinationDirectory "$($WindowsUpdateDriver.Guid)"
                                if (Test-Path $ExpandedLocalFolder) {
                                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Driver already expanded at $ExpandedLocalFolder"
                                }
                                else {
                                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Downloading to $DestinationDirectory"
                                    $WindowsUpdateDriverFile = Save-MicrosoftUpdateCatalogUpdate -Guid $WindowsUpdateDriver.Guid -DestinationDirectory $DestinationDirectory
                                    if ($WindowsUpdateDriverFile) {
                                        if (-not (Test-Path $ExpandedLocalFolder)) {
                                            # Destination folder must exist before expanding the cab file
                                            New-Item -Path $ExpandedLocalFolder -ItemType Directory -Force | Out-Null
                                        }
                                        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Expanding to $ExpandedLocalFolder"
                                        expand.exe "$($WindowsUpdateDriverFile.FullName)" -F:* "$ExpandedLocalFolder" | Out-Null
                                        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Removing $($WindowsUpdateDriverFile.FullName)"
                                        Remove-Item $($WindowsUpdateDriverFile.FullName) -Force -ErrorAction SilentlyContinue | Out-Null
                                    }
                                    else {
                                        Write-Verbose "[$(Get-Date -format s)] Could not find a Driver for this HardwareID"
                                    }
                                }
                            }
                        }
                        else {
                            Write-Verbose "[$(Get-Date -format s)] No Results: $($Item.Name) $FindHardwareID"
                        }
                    }
                    catch{
                        Write-Verbose "[$(Get-Date -format s)] Unable to get Driver for Hardware component"
                    }   
                }
                else {
                    Write-Verbose "[$(Get-Date -format s)] No Results: $FindHardwareID"
                }
            }
        }
    }
    #=================================================
    #	ByHardwareID
    #=================================================
    if ($PSCmdlet.ParameterSetName -eq 'ByHardwareID') {
        Write-Verbose "[$(Get-Date -format s)] ByHardwareID"

        foreach ($Item in $HardwareID) {
            Write-Verbose "[$(Get-Date -format s)] $Item"

            $WindowsUpdateDriver = $null
            $FindHardwareID = $null

            # Determine if the input is a HardwareID or SurfaceID pattern, and extract the relevant portion for searching
            Write-Verbose "[$(Get-Date -format s)] Try matching HardwareID pattern: $HardwareIDPattern"
            $FindHardwareID = $Item | Select-String -Pattern $HardwareIDPattern | Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Value

            if (-not ($FindHardwareID)) {
                Write-Verbose "[$(Get-Date -format s)] Try matching SurfaceID pattern: $SurfaceIDPattern"
                $FindHardwareID = $Item | Select-String -Pattern $SurfaceIDPattern | Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Value
            }
            if (-not ($FindHardwareID)) {
                Write-Verbose "[$(Get-Date -format s)] Search term did not match known patterns, using raw input as search term"
                $FindHardwareID = $Item
            }

            if ($FindHardwareID) {
                # Check if we have already searched for this HardwareID
                if ($SearchedHardwareIDs.ContainsKey($FindHardwareID)) {
                    Write-Verbose "[$(Get-Date -format s)] Skipping duplicate search for: $FindHardwareID"
                    continue
                }

                # Mark this HardwareID as searched
                $SearchedHardwareIDs[$FindHardwareID] = $true

                # Write-Verbose "[$(Get-Date -format s)] Search: $FindHardwareID"
                $SearchString = "$FindHardwareID".Replace('&', "`%26")

                try {
                    Write-Verbose "[$(Get-Date -format s)] Search: $SearchString"
                    $WindowsUpdateDriver = Get-MicrosoftUpdateCatalogResult -Search "$SearchString" -Descending |
                        Select-Object LastUpdated, Title, Version, Size, Guid -First 1 -ErrorAction Ignore
                    
                    if ($WindowsUpdateDriver) {
                        Write-Verbose "[$(Get-Date -format s)] Found driver match for version: $($WindowsUpdateDriver.Version)"
                    }
                }
                catch {
                    Write-Verbose "[$(Get-Date -format s)] Error searching for driver: $_"
                }

                if ($WindowsUpdateDriver.Guid) {
                    Write-Host -ForegroundColor DarkGreen "[$(Get-Date -format s)] $($WindowsUpdateDriver.Title)"
                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] UpdateID: $($WindowsUpdateDriver.Guid)"
                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Last Updated $($WindowsUpdateDriver.LastUpdated) Version $($WindowsUpdateDriver.Version) Size: $($WindowsUpdateDriver.Size)"
                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] HardwareID: $FindHardwareID"
                    Write-Verbose "[$(Get-Date -format s)] SearchString: $SearchString"

                    if ($DestinationDirectory) {
                        $ExpandedLocalFolder = Join-Path $DestinationDirectory "$($WindowsUpdateDriver.Guid)"
                        if (Test-Path $ExpandedLocalFolder) {
                            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Driver already expanded at $ExpandedLocalFolder"
                        }
                        else {
                            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Downloading to $DestinationDirectory"
                            $WindowsUpdateDriverFile = Save-MicrosoftUpdateCatalogUpdate -Guid $WindowsUpdateDriver.Guid -DestinationDirectory $DestinationDirectory
                            if ($WindowsUpdateDriverFile) {
                                if (-not (Test-Path $ExpandedLocalFolder)) {
                                    # Destination folder must exist before expanding the cab file
                                    New-Item -Path $ExpandedLocalFolder -ItemType Directory -Force | Out-Null
                                }
                                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Expanding to $ExpandedLocalFolder"
                                expand.exe "$($WindowsUpdateDriverFile.FullName)" -F:* "$ExpandedLocalFolder" | Out-Null
                                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Removing $($WindowsUpdateDriverFile.FullName)"
                                Remove-Item $($WindowsUpdateDriverFile.FullName) -Force -ErrorAction SilentlyContinue | Out-Null
                            }
                            else {
                                Write-Verbose "[$(Get-Date -format s)] Could not find a Driver for this HardwareID"
                            }
                        }
                    }
                }
                else {
                    Write-Verbose "[$(Get-Date -format s)] No Results: $FindHardwareID"
                }
            }
            else {
                Write-Verbose "[$(Get-Date -format s)] No Results: $FindHardwareID"
            }
        }
    }
}
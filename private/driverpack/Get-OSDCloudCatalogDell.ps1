function Get-OSDCloudCatalogDell {
    <#
    .SYNOPSIS
        Downloads and parses the Dell driver pack catalog for Windows 11.

    .DESCRIPTION
        Retrieves the latest Dell DriverPackCatalog.cab from Dell's download site,
        extracts and parses it to create a catalog of available Windows 11 driver packs.
        Falls back to offline catalog if download fails.

    .EXAMPLE
        Get-OSDCloudCatalogDell
        
        Retrieves the Dell driver pack catalog for Windows 11.

    .OUTPUTS
        PSCustomObject[]
        Returns custom objects with driver pack information including Name, Model, 
        SystemId, URL, ReleaseDate, and other metadata.

    .NOTES
        Catalog is downloaded from https://downloads.dell.com/catalog/DriverPackCatalog.cab
    #>
    [CmdletBinding()]
    param ()
    
    begin {
        Write-Verbose "[$((Get-Date).ToString('HH:mm:ss'))][$($MyInvocation.MyCommand.Name)] Start"
        #=================================================
        # Catalogs
        $localCatalogPath = "$(Get-OSDCloudModulePath)\catalogs\driverpack\dell.xml"
        $originCatalogPath = 'https://downloads.dell.com/catalog/DriverPackCatalog.cab'
        $repositoryCatalogPath = 'https://raw.githubusercontent.com/OSDeploy/osdcloud-cache/refs/heads/master/driverpack/dell.xml'
        $tempCatalogPackagePath = "$($env:TEMP)\DriverPackCatalog.cab"
        $tempCatalogPath = "$($env:TEMP)\osdcloud-driverpack-dell.xml"
        #=================================================
        # Build realtime catalog from online source, if fails fallback to offline catalog
        <#
        try {
            if ($Force -or -not (Test-Path $tempCatalogPath)) {
                Write-Verbose "Downloading Dell driver pack catalog from $originCatalogPath"
                $null = Invoke-WebRequest -Uri $originCatalogPath -OutFile $tempCatalogPackagePath -ErrorAction Stop
                
                if (Test-Path $tempCatalogPackagePath) {
                    Write-Verbose "Extracting catalog from CAB file"
                    # expand.exe is used for CAB extraction as Expand-Archive only supports ZIP
                    $expandResult = & expand.exe $tempCatalogPackagePath $tempCatalogPath 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        Write-Warning "Failed to extract catalog: $expandResult"
                    }
                }
            } else {
                Write-Verbose "Using cached catalog (use -Force to download latest)"
            }
        } catch {
            Write-Warning "Failed to download catalog: $($_.Exception.Message)"
            Write-Verbose "Falling back to offline catalog"
        }
        #>
        
        # Load catalog content
        if (Test-Path $tempCatalogPath) {
            Write-Verbose "Loading online catalog from $tempCatalogPath"
            [xml]$XmlCatalogContent = Get-Content -Path $tempCatalogPath -Raw
        } else {
            Write-Verbose "Loading offline catalog from $localCatalogPath"
            [xml]$XmlCatalogContent = Get-Content -Path $localCatalogPath -Raw
        }
        
        # Validate catalog content
        if (-not $XmlCatalogContent) {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new("Failed to load catalog content"),
                'CatalogLoadFailed',
                [System.Management.Automation.ErrorCategory]::InvalidData,
                $tempCatalogPath
            )
            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }
    }
    
    process {
        #=================================================
        # Build Catalog
        #=================================================
        Write-Verbose "Building driver pack catalog"
        $OnlineBaseUri = 'https://downloads.dell.com/'

        #$CatalogVersion = (Get-Date $XmlCatalogContent.DriverPackManifest.version).ToString('yy.MM.dd')
        $RawCatalogVersion = $XmlCatalogContent.DriverPackManifest.version -replace '.00','.01'
        $CatalogVersion = (Get-Date $RawCatalogVersion).ToString('yy.MM.dd')
        Write-Verbose "Catalog version: $CatalogVersion"

        $DellDriverPackXml = $XmlCatalogContent.DriverPackManifest.DriverPackage
        
        # Fixed handling null values
        $DellDriverPackXml = $DellDriverPackXml | Where-Object { 
            $osCode = $_.SupportedOperatingSystems.OperatingSystem.osCode
            $osCode -and ($osCode.Trim() | Select-Object -Unique) -notmatch 'winpe'
        }
        #=================================================
        # Create Object
        #=================================================
        $Results = foreach ($Item in $DellDriverPackXml) {
            $osCode = $Item.SupportedOperatingSystems.OperatingSystem.osCode.Trim() | Select-Object -Unique
            if ($osCode -match 'Windows11') {
                $OperatingSystem = 'Windows 11'
            } else {
                Continue
            }

            $Name = "Dell $($Item.SupportedSystems.Brand.Model.name | Select-Object -Unique)"
            $Name = $Name -replace '  ',' '
            $Name = $Name -replace 'Dell Dell','Dell'
            $Model = ($Item.SupportedSystems.Brand.Model.name | Select-Object -Unique)

            # DriverPack Version
            $DriverPackVersion = $Item.dellVersion
            if ($DriverPackVersion -eq '*') {
                $DriverPackVersion = $null
            }

            $ReleaseDate = Get-Date $Item.dateTime -Format "yy.MM.dd"

            $ObjectProperties = [Ordered]@{
                CatalogVersion      = $CatalogVersion
                ReleaseDate         = $ReleaseDate
                Name                = "$Name $DriverPackVersion [$ReleaseDate]"
                Manufacturer        = 'Dell'
                Model               = $Model
                SystemId            = [string[]]@($Item.SupportedSystems.Brand.Model.systemID | Select-Object -Unique)
                FileName            = (Split-Path -Leaf $Item.path)
                Url                 = -join ($OnlineBaseUri, $Item.path)
                OperatingSystem     = $OperatingSystem
                OSArchitecture      = 'amd64'
                HashMD5             = $Item.HashMD5
            }
            New-Object -TypeName PSObject -Property $ObjectProperties
        }
        #=================================================
        # Sort Results
        #=================================================
        $Results = $Results | Sort-Object -Property Name
        if ($VerbosePreference -eq 'Continue' -or $DebugPreference -eq 'Continue') {
            $Results | ConvertTo-Json -Depth 10 | Out-File -FilePath "$env:Temp\osdcloud-driverpack-dell.json" -Encoding utf8
        }
        Write-Verbose "Found $($Results.Count) Windows 11 driver packs"
        $Results
    }
    
    end {
        #=================================================
        if ($VerbosePreference -eq 'Continue' -or $DebugPreference -eq 'Continue') {
            $Results | ConvertTo-Json -Depth 10 | Out-File -FilePath "$env:Temp\osdcloud-driverpack-dell.json" -Encoding utf8
        }
        if (Test-Path $tempCatalogPackagePath) {
            Write-Verbose "Removing temporary CAB file"
            Remove-Item -Path $tempCatalogPackagePath -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $tempCatalogPath) {
            Write-Verbose "Removing temporary catalog file"
            Remove-Item -Path $tempCatalogPath -Force -ErrorAction SilentlyContinue
        }
        #=================================================
        Write-Verbose "[$((Get-Date).ToString('HH:mm:ss'))][$($MyInvocation.MyCommand.Name)] End"
        #=================================================
    }
}
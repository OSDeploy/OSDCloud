function Get-OSDCloudCatalogHp {
    <#
    .SYNOPSIS
        Downloads and parses the HP driver pack catalog for Windows 11.

    .DESCRIPTION
        Retrieves the latest HP Client Driver Pack Catalog from HP's cloud repository,
        extracts and parses it to create a catalog of available Windows 11 driver packs.
        Falls back to offline catalog if download fails.

    .EXAMPLE
        Get-OSDCloudCatalogHp
        
        Retrieves the HP driver pack catalog for Windows 11.

    .OUTPUTS
        PSCustomObject[]
        Returns custom objects with driver pack information including Name, Model, 
        SystemId, URL, ReleaseDate, and other metadata.

    .NOTES
        Catalog is downloaded from https://hpia.hpcloud.hp.com/downloads/driverpackcatalog/HPClientDriverPackCatalog.cab
    #>
    [CmdletBinding()]
    param ()
    
    begin {
        Write-Verbose "[$((Get-Date).ToString('HH:mm:ss'))][$($MyInvocation.MyCommand.Name)] Start"
        #=================================================
        # Catalogs
        $localCatalogPath = "$(Get-OSDCloudModulePath)\catalogs\driverpack\hp.xml"
        $originCatalogPath = 'https://hpia.hpcloud.hp.com/downloads/driverpackcatalog/HPClientDriverPackCatalog.cab'
        $repositoryCatalogPath = 'https://raw.githubusercontent.com/OSDeploy/osdcloud-cache/refs/heads/master/driverpack/hp.xml'
        $tempCatalogPackagePath = "$($env:TEMP)\HPClientDriverPackCatalog.cab"
        $tempCatalogPath = "$($env:TEMP)\osdcloud-driverpack-hp.xml"
        #=================================================
        # Build realtime catalog from online source, if fails fallback to offline catalog
        try {
            if (-not (Test-Path $tempCatalogPath)) {
                Write-Verbose "Downloading HP driver pack catalog from $originCatalogPath"
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
                Write-Verbose "Using cached catalog"
            }
        } catch {
            Write-Warning "Failed to download catalog: $($_.Exception.Message)"
            Write-Verbose "Falling back to offline catalog"
        }
        
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
        $CatalogVersion = Get-Date -Format yy.MM.dd
        Write-Verbose "Catalog version: $CatalogVersion"
        
        $HpSoftPaqList = $XmlCatalogContent.NewDataSet.HPClientDriverPackCatalog.SoftPaqList.SoftPaq
        $HpModelList = $XmlCatalogContent.NewDataSet.HPClientDriverPackCatalog.ProductOSDriverPackList.ProductOSDriverPack
        $HpModelList = $HpModelList | Where-Object {$_.OSId -ge '4317'}
        #=================================================
        # Create Object
        #=================================================
        $Results = foreach ($Item in $HpModelList) {
            $HpSoftPaq = $null
            $HpSoftPaq = $HpSoftPaqList | Where-Object {$_.Id -eq $Item.SoftPaqId}

            if ($null -eq $HpSoftPaq) {
                Continue
            }
            $OperatingSystem = 'Windows 11'

            $OSVersion = $Item.OSName
            $OSVersion = $OSVersion.Substring($OSVersion.Length - 4)

            $template = "M/d/yyyy hh:mm:ss tt"
            $timeinfo = $HpSoftPaq.DateReleased
            $dtReleaseDate = [datetime]::ParseExact($timeinfo, $template, $null)
            $ReleaseDate = $dtReleaseDate.ToString("yy.MM.dd")

            $ObjectProperties = [Ordered]@{
                CatalogVersion  = $CatalogVersion
                ReleaseDate     = $ReleaseDate
                Name            = "$($Item.SystemName) $($Item.SoftPaqId) [$ReleaseDate]"
                Manufacturer    = 'HP'
                Model           = $Item.SystemName
                SystemId        = $Item.SystemId.split(',').ForEach({$_.Trim()})
                FileName        = $HpSoftPaq.Url | Split-Path -Leaf
                Url             = $HpSoftPaq.Url
                OperatingSystem = $OperatingSystem
                OSArchitecture  = 'amd64'
                OSVersion       = $OSVersion
                HashMD5         = $HpSoftPaq.MD5
            }
            New-Object -TypeName PSObject -Property $ObjectProperties
        }
        #=================================================
        # Cleanup Catalog
        #=================================================
        Write-Verbose "Filtering to latest driver packs per model"
        $Results = $Results | Sort-Object Model, OSVersion -Descending | Group-Object Model | ForEach-Object {$_.Group | Select-Object -First 1}
        #=================================================
        # Sort Results
        #=================================================
        $Results = $Results | Sort-Object -Property Name
        Write-Verbose "Found $($Results.Count) Windows 11 driver packs"
        $Results
    }
    
    end {
        #=================================================
        if ($VerbosePreference -eq 'Continue' -or $DebugPreference -eq 'Continue') {
            $Results | ConvertTo-Json -Depth 10 | Out-File -FilePath "$env:Temp\osdcloud-driverpack-hp.json" -Encoding utf8
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
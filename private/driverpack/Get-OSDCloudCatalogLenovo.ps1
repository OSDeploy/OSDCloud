function Get-OSDCloudCatalogLenovo {
    <#
    .SYNOPSIS
        Downloads and parses the Lenovo driver pack catalog for Windows 11.

    .DESCRIPTION
        Retrieves the latest Lenovo SCCM driver pack catalog from Lenovo's download site,
        parses the XML to create a catalog of available Windows 11 driver packs.
        Falls back to offline catalog if download fails.

    .EXAMPLE
        Get-OSDCloudCatalogLenovo
        
        Retrieves the Lenovo driver pack catalog for Windows 11.

    .OUTPUTS
        PSCustomObject[]
        Returns custom objects with driver pack information including Name, Model, 
        SystemId, URL, ReleaseDate, and other metadata.

    .NOTES
        Catalog is downloaded from https://download.lenovo.com/cdrt/td/catalogv2.xml
    #>
    [CmdletBinding()]
    param ()
    
    begin {
        Write-Verbose "[$((Get-Date).ToString('HH:mm:ss'))][$($MyInvocation.MyCommand.Name)] Start"
        #=================================================
        # Catalogs
        $localCatalogPath = "$(Get-OSDCloudModulePath)\catalogs\driverpack\lenovo.xml"
        $originCatalogPath = 'https://download.lenovo.com/cdrt/td/catalogv2.xml'
        $repositoryCatalogPath = 'https://raw.githubusercontent.com/OSDeploy/osdcloud-cache/refs/heads/master/driverpack/lenovo.xml'
        $tempCatalogPath = "$($env:TEMP)\osdcloud-driverpack-lenovo.xml"
        #=================================================
        # Build realtime catalog from online source, if fails fallback to offline catalog
        <#
        try {
            if ($Force -or -not (Test-Path $tempCatalogPath)) {
                Write-Verbose "Downloading Lenovo driver pack catalog from $originCatalogPath"
                $sourceContent = Invoke-RestMethod -Uri $originCatalogPath -UseBasicParsing -ErrorAction Stop
                
                if ($sourceContent) {
                    Write-Verbose "Processing catalog content"
                    # Remove BOM (Byte Order Mark) from the beginning of the content
                    $catalogContent = $sourceContent.Substring(3)
                    $catalogContent | Out-File -FilePath $tempCatalogPath -Encoding utf8 -Force
                    [xml]$XmlCatalogContent = $catalogContent
                }
            } else {
                Write-Verbose "Using cached catalog (use -Force to download latest)"
                if (Test-Path $tempCatalogPath) {
                    Write-Verbose "Loading online catalog from $tempCatalogPath"
                    [xml]$XmlCatalogContent = Get-Content -Path $tempCatalogPath -Raw
                }
            }
        } catch {
            Write-Warning "Failed to download catalog: $($_.Exception.Message)"
            Write-Verbose "Falling back to offline catalog"
        }
        #>
        
        # Load offline catalog if online catalog failed
        if (-not $XmlCatalogContent) {
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
        
        $ModelList = $XmlCatalogContent.ModelList.Model
        #=================================================
        # Create Object 
        #=================================================
        $Results = foreach ($Model in $ModelList) {
            foreach ($Item in $Model.SCCM) {
                $DownloadUrl = $Item.'#text'
                # Release date is in this format: 2022-09-28
                $ReleaseDate = $Item.date
                # Need to convert it to this format: 22.09.28
                $ReleaseDate = Get-Date $ReleaseDate -Format "yy.MM.dd"
                
                $OSVersion = $Item.version
                if ($OSVersion -eq '*') {
                    $OSVersion = $null
                }

                $HashMD5 = $Item.crc

                if ($Item.os -eq 'win11') {
                    $OperatingSystem = "Windows 11"
                } else {
                    continue
                }

                $NewName = "Lenovo $($Model.name) [$ReleaseDate]"

                $ObjectProperties = [Ordered]@{
                    CatalogVersion  = $CatalogVersion
                    ReleaseDate     = $ReleaseDate
                    Name            = $NewName
                    Manufacturer    = 'Lenovo'
                    Model           = $Model.name
                    SystemId        = $Model.Types.Type.split(',').ForEach({$_.Trim()})
                    FileName        = $DownloadUrl | Split-Path -Leaf
                    Url             = $DownloadUrl
                    OperatingSystem = $OperatingSystem
                    OSArchitecture  = 'amd64'
                    OSVersion       = $OSVersion
                    HashMD5         = $HashMD5
                }
                New-Object -TypeName PSObject -Property $ObjectProperties
            }
        }
        #=================================================
        # Cleanup Catalog
        #=================================================
        Write-Verbose "Filtering to latest driver packs per model"
        $Results = $Results | Sort-Object Model, OSVersion -Descending | Group-Object Model | ForEach-Object {$_.Group | Select-Object -First 1}
        $Results = $Results | Sort-Object Model, OSVersion -Descending | Group-Object HashMD5 | ForEach-Object {$_.Group | Select-Object -First 1}
        #=================================================
        # Sort Results
        #=================================================
        $Results = $Results | Sort-Object Model, OSVersion -Descending
        Write-Verbose "Found $($Results.Count) Windows 11 driver packs"
        $Results
    }
    
    end {
        #=================================================
        # Cleanup temporary files
        #=================================================
        if (Test-Path $tempCatalogPath) {
            Write-Verbose "Removing temporary catalog file"
            Remove-Item -Path $tempCatalogPath -Force -ErrorAction SilentlyContinue
        }
        #=================================================
        Write-Verbose "[$((Get-Date).ToString('HH:mm:ss'))][$($MyInvocation.MyCommand.Name)] End"
        #=================================================
    }
}
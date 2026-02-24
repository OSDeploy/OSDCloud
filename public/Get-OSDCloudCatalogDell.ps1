function Get-OSDCloudCatalogDell {
    [CmdletBinding()]
    param (
        $Force
    )
    #=================================================
    # Offline Source
    $InputCatalogPath  = "$(Get-OSDCloudModulePath)\catalogs\driverpack\osdcloud-dell.xml"
    #=================================================
    # Online Source
    $sourceUrl = 'https://downloads.dell.com/catalog/DriverPackCatalog.cab'
    #=================================================
    # Update Catalog
    $destinationCatalog = "$($env:TEMP)\osdcloud-dell.xml"
    $destinationCabFile = "$($env:TEMP)\DriverPackCatalog.cab"
    (New-Object System.Net.WebClient).DownloadFile($sourceUrl, $destinationCabFile)
    if (Test-Path $destinationCabFile) {
        $null = Expand "$destinationCabFile" "$destinationCatalog"
    }
    if (Test-Path $destinationCatalog) {
        [xml]$XmlCatalogContent = Get-Content -Path $destinationCatalog -Raw
    }
    else {
        [xml]$XmlCatalogContent = Get-Content -Path $InputCatalogPath -Raw
    }
    #=================================================
    # Build Catalog
    $OnlineBaseUri = 'http://downloads.dell.com/'

    #$CatalogVersion = (Get-Date $XmlCatalogContent.DriverPackManifest.version).ToString('yy.MM.dd')
    $RawCatalogVersion = $XmlCatalogContent.DriverPackManifest.version -replace '.00','.01'
    $CatalogVersion = (Get-Date $RawCatalogVersion).ToString('yy.MM.dd')

    $DellDriverPackXml = $XmlCatalogContent.DriverPackManifest.DriverPackage
    
    # Fixed handling null values
    $DellDriverPackXml = $DellDriverPackXml | Where-Object { 
        $osCode = $_.SupportedOperatingSystems.OperatingSystem.osCode
        $osCode -and ($osCode.Trim() | Select-Object -Unique) -notmatch 'winpe'
    }
    #=================================================
    #   Create Object
    #=================================================
    $Results = foreach ($Item in $DellDriverPackXml) {
        $osCode = $Item.SupportedOperatingSystems.OperatingSystem.osCode.Trim() | Select-Object -Unique
        if ($osCode -match 'Windows11') {
            $OperatingSystem = 'Windows 11'
        }
        else {
            Continue
        }

        $Name = "Dell $($Item.SupportedSystems.Brand.Model.name | Select-Object -Unique)"
        $Name = $Name -replace '  ',' '
        $Name = $Name -replace 'Dell Dell','Dell'
        $Model = ($Item.SupportedSystems.Brand.Model.name | Select-Object -Unique)

        $ObjectProperties = [Ordered]@{
            CatalogVersion 	    = $CatalogVersion
            ReleaseDate		    = Get-Date $Item.dateTime -Format "yy.MM.dd"
            Name		        = $Name
            Manufacturer        = 'Dell'
            Model		        = $Model
            SystemId		    = [System.String]($Item.SupportedSystems.Brand.Model.systemID | Select-Object -Unique)
            FileName		    = (split-path -leaf $Item.path)
            Url		            = -join ($OnlineBaseUri, $Item.path)
            OperatingSystem     = $OperatingSystem
            OSArchitecture      = 'amd64'
            HashMD5		        = $Item.HashMD5
        }
        New-Object -TypeName PSObject -Property $ObjectProperties
    }
    #=================================================
    # Cleanup Catalog
    $Results = $Results | Sort-Object ReleaseDate -Descending | Group-Object Name | ForEach-Object {$_.Group | Select-Object -First 1}
    #=================================================
    #   Sort Results
    #=================================================
    $Results = $Results | Sort-Object -Property Name
    $Results
    #=================================================
    Write-Verbose "[$((Get-Date).ToString('HH:mm:ss'))][$($MyInvocation.MyCommand.Name)] End"
    #=================================================
}
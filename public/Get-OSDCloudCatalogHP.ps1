function Get-OSDCloudCatalogHp {
    [CmdletBinding()]
    param (
        $Force
    )
    #=================================================
    # Offline Source
    $InputCatalogPath  = "$(Get-OSDCloudModulePath)\catalogs\driverpack\osdcloud-hp.xml"
    #=================================================
    # Online Source
    $sourceUrl = 'https://hpia.hpcloud.hp.com/downloads/driverpackcatalog/HPClientDriverPackCatalog.cab'
    #=================================================
    # Update Catalog
    $destinationCatalog = "$($env:TEMP)\osdcloud-hp.xml"
    $destinationCabFile = "$($env:TEMP)\HPClientDriverPackCatalog.cab"
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
    $HpSoftPaqList = $XmlCatalogContent.NewDataSet.HPClientDriverPackCatalog.SoftPaqList.SoftPaq
    $HpModelList = $XmlCatalogContent.NewDataSet.HPClientDriverPackCatalog.ProductOSDriverPackList.ProductOSDriverPack
    $HpModelList = $HpModelList | Where-Object {$_.OSId -ge '4317'}
    #=================================================
    #   Create Object
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


        $ObjectProperties = [Ordered]@{
            CatalogVersion 	= Get-Date -Format yy.MM.dd
            ReleaseDate     = $dtReleaseDate.ToString("yy.MM.dd")
            Name            = "$($Item.SystemName) [$($Item.SoftPaqId)]"
            Manufacturer    = 'HP'
            Model           = $Item.SystemName
            SystemId        = [System.String]$Item.SystemId.split(',').Trim()
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
    $Results = $Results | Sort-Object Model, OSVersion -Descending | Group-Object Model | ForEach-Object {$_.Group | Select-Object -First 1}
    #=================================================
    #   Sort Results
    #=================================================
    $Results = $Results | Sort-Object -Property Name
    $Results
    #=================================================
    Write-Verbose "[$((Get-Date).ToString('HH:mm:ss'))][$($MyInvocation.MyCommand.Name)] End"
    #=================================================
}
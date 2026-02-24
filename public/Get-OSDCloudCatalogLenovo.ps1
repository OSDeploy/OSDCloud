function Get-OSDCloudCatalogLenovo {
    [CmdletBinding()]
    param (
        $Force
    )
    #=================================================
    # Offline Source
    $InputCatalogPath  = "$(Get-OSDCloudModulePath)\catalogs\driverpack\osdcloud-lenovo.xml"
    #=================================================
    # Online Source
    $sourceUrl = 'https://download.lenovo.com/cdrt/td/catalogv2.xml'
    #=================================================
    # Update Catalog
    $destinationCatalog = "$($env:TEMP)\osdcloud-lenovo.xml"
    $sourceContent = Invoke-RestMethod -Uri $sourceUrl -UseBasicParsing
    if ($sourceContent) {
        $catalogContent = $sourceContent.Substring(3)
        $catalogContent | Out-File -FilePath $destinationCatalog -Encoding utf8 -Force
        [xml]$XmlCatalogContent = $catalogContent
    }
    else {
        [xml]$XmlCatalogContent = Get-Content -Path $InputCatalogPath -Raw
    }
    #=================================================
    # Build Catalog
    $ModelList = $XmlCatalogContent.ModelList.Model
    #=================================================
    #   Create Object 
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
            }
            else {
                continue
            }

            if ($Item.version -eq '*') {
                $NewName = "Lenovo $($Model.name) - Win11"
            }
            else {
                $NewName = "Lenovo $($Model.name) - Win11 $($Item.version)"
            }

            $ObjectProperties = [Ordered]@{
                CatalogVersion 	= Get-Date -Format yy.MM.dd
                ReleaseDate     = $ReleaseDate
                Name            = $NewName
                Manufacturer    = 'Lenovo'
                Model           = $Model.name
                SystemId        = [System.String]$Model.Types.Type.split(',').Trim()
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
    $Results = $Results | Sort-Object Model, OSVersion -Descending | Group-Object Model | ForEach-Object {$_.Group | Select-Object -First 1}
    $Results = $Results | Sort-Object Model, OSVersion -Descending | Group-Object HashMD5 | ForEach-Object {$_.Group | Select-Object -First 1}
    #=================================================
    # Sort Results
    #=================================================
    $Results = $Results | Sort-Object Model, OSVersion -Descending
    $Results
    #=================================================
    Write-Verbose "[$((Get-Date).ToString('HH:mm:ss'))][$($MyInvocation.MyCommand.Name)] End"
    #=================================================
}
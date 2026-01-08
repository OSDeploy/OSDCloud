function Get-PSOSDCloudOperatingSystems {
    [CmdletBinding()]
    param ()
    $ErrorActionPreference = 'Stop'

    $srcRoot = Join-Path $(Get-OSDCloudModulePath) "catalogs\psosdcloudoperatingsystems"
    $xmlFiles = Get-ChildItem -Path $srcRoot -Filter '*.xml' -Recurse | Sort-Object FullName

    $records = @()

    foreach ($file in $xmlFiles) {
        Write-Verbose "Importing $($file.FullName)"

        $xml = [xml](Get-Content -Path $file.FullName -Raw)
        $fileNodes = $xml.MCT.Catalogs.Catalog.PublishedMedia.Files.File

        if (-not $fileNodes) {
            continue
        }
        #=================================================
        foreach ($node in ($fileNodes | Sort-Object FileName)) {
            #=================================================
            #   OSBuild
            #   Get the OSBuild from the FileName
            $OSBuild = $node.FileName.Substring(0, 5)
            #=================================================
            #   OperatingSystem / OSName / OSVersion
            #   19045 = Windows 10 22H2
            #   22000 = Windows 11 21H2
            #   22621 = Windows 11 22H2
            #   22631 = Windows 11 23H2
            #   26100 = Windows 11 24H2
            #   26200 = Windows 11 25H2
            #   28000 = Windows 11 26H1
            switch ($OSBuild) {
                '19045' { $OperatingSystem = 'Windows 10 22H2'; $OSName = 'Windows 10'; $OSVersion = '22H2' }
                '22000' { $OperatingSystem = 'Windows 11 21H2'; $OSName = 'Windows 11'; $OSVersion = '21H2' }
                '22621' { $OperatingSystem = 'Windows 11 22H2'; $OSName = 'Windows 11'; $OSVersion = '22H2' }
                '22631' { $OperatingSystem = 'Windows 11 23H2'; $OSName = 'Windows 11'; $OSVersion = '23H2' }
                '26100' { $OperatingSystem = 'Windows 11 24H2'; $OSName = 'Windows 11'; $OSVersion = '24H2' }
                '26200' { $OperatingSystem = 'Windows 11 25H2'; $OSName = 'Windows 11'; $OSVersion = '25H2' }
                '28000' { $OperatingSystem = 'Windows 11 26H1'; $OSName = 'Windows 11'; $OSVersion = '26H1' }
                default { continue }
            }
            #=================================================
            #   OSBuildVersion
            #   Combination of <OSBuild>.<Sub>
            #   Extract from FileName
            #=================================================
            $OSBuildVersion = ($node.FileName -split '\.', 3)[0..1] -join '.'
            #=================================================
            #   OSArchitecture
            #   Avoids confusion between x64 releases (amd64/arm64)
            #=================================================
            if ($node.Architecture -match 'x64') {
                $OSArchitecture = 'amd64'
            } elseif ($node.Architecture -match 'arm64') {
                $OSArchitecture = 'arm64'
            } else {
                $OSArchitecture = 'x86'
                continue
            }
            #=================================================
            #   OSActivation
            #=================================================
            if ($node.FileName -match 'clientconsumer_ret') {
                $OSActivation = 'Retail'
            }
            elseif ($node.FileName -match 'CLIENTBUSINESS_VOL') {
                $OSActivation = 'Volume'
            }
            else {
                $OSActivation = 'Unknown'
                continue
            }
            #=================================================
            #   Id
            #=================================================
            $Id = "$OperatingSystem $OSArchitecture $OSActivation $($node.LanguageCode) $OSBuildVersion"
            #=================================================
            #   ObjectProperties
            #=================================================
            $records += [pscustomobject]@{
                Id              = $Id
                OperatingSystem = $OperatingSystem
                OSName          = $OSName
                OSVersion       = $OSVersion
                OSArchitecture  = $OSArchitecture
                OSActivation    = $OSActivation
                LanguageCode    = $node.LanguageCode
                Language        = $node.Language
                OSBuild         = $OSBuild
                OSBuildVersion  = $OSBuildVersion
                # Architecture    = $node.Architecture
                Size            = $node.Size
                Sha1            = $node.Sha1
                Sha256          = $node.Sha256
                FileName        = $node.FileName
                FilePath        = $node.FilePath
                # IsRetailOnly    = $node.IsRetailOnly
            }
        }
    }
    $records = $records | Sort-Object -Property FileName -Unique
    $records = $records | Sort-Object -Property @{Expression = { $_.OperatingSystem }; Descending = $true }, OSArchitecture, OSActivation, LanguageCode
    
    $global:PSOSDCloudOperatingSystems = $records

    # $records | Export-Clixml -Path $(Join-Path $buildRoot 'recast-operatingsystems.clixml') -Force
    # $records | ConvertTo-Json | Out-File $(Join-Path $buildRoot 'recast-operatingsystems.json') -Encoding utf8 -Width 2000 -Force

    return $records
}
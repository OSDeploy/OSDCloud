function Get-PSOSDCloudOperatingSystem {
    [CmdletBinding()]
    param ()
    
    $ErrorActionPreference = 'Stop'

    <#
    Id             : Windows 11 25H2 ar-sa Retail arm64 26200.7462
    OSGroup        : Win11-25H2-arm64
    OSName         : Windows 11
    OSVersion      : 25H2
    OSArchitecture : arm64
    OSActivation   : Retail
    OSBuild        : 26200
    OSBuildVersion : 26200.7462
    FileName       : 26200.7462.251207-0044.25h2_ge_release_svc_refresh_CLIENTCONSUMER_RET_A64FRE_ar-sa.esd
    LanguageCode   : ar-sa
    Language       : Arabic (Saudi Arabia)
    Architecture   : ARM64
    Size           : 5353442850
    Sha1           :
    Sha256         : 9c3188747ee824b95a9282b4644c1ea5aa9902bf503b9b359e57ea6a6e604a4c
    FilePath       : http://dl.delivery.mp.microsoft.com/filestreamingservice/files/25844794-129b-4c73-a2da-c111a3969ea8/26200.7462.251207-0044.25h2_ge_release_svc_refresh_CLIENTCONSUMER_RET_A64FRE_ar-sa.esd
    #>

    $OSCloudOS = Get-PSOSDCloudOperatingSystems

    # Limit the results based on $env:PROCESSOR_ARCHITECTURE
    $ProcessorArchitecture = $env:PROCESSOR_ARCHITECTURE
    Write-Verbose "Filtering results for OSArchitecture = env:PROCESSOR_ARCHITECTURE = $ProcessorArchitecture"
    if ($ProcessorArchitecture -and ($OSCloudOS.OSArchitecture -match $ProcessorArchitecture)) {
        $OSCloudOS = $OSCloudOS | Where-Object { $_.OSArchitecture -eq $ProcessorArchitecture }
    }

    # OSDCloud LanguageCode
    $Culture = Get-Culture | Select-Object -ExpandProperty Name -First 1
    if ($global:OSDCLOUD_LANGUAGECODE) {
        $p = [string]$global:OSDCLOUD_LANGUAGECODE
        if ($p -and ($OSCloudOS.LanguageCode -match $p)) {
            Write-Verbose "Filtering results for LanguageCode = global:OSDCLOUD_LANGUAGECODE = $p"
            $OSCloudOS = $OSCloudOS | Where-Object { $_.LanguageCode -eq $p }
        }
    }
    elseif ($env:OSDCLOUD_LANGUAGECODE) {
        $p = [string]$env:OSDCLOUD_LANGUAGECODE
        if ($p -and ($OSCloudOS.LanguageCode -match $p)) {
            Write-Verbose "Filtering results for LanguageCode = env:OSDCLOUD_LANGUAGECODE = $p"
            $OSCloudOS = $OSCloudOS | Where-Object { $_.LanguageCode -eq $p }
        }
    }
    elseif ($Culture -and ($OSCloudOS.LanguageCode -match $Culture)) {
        Write-Verbose "Filtering results for LanguageCode = Get-Culture = $p"
        $OSCloudOS = $OSCloudOS | Where-Object { $_.LanguageCode -eq $Culture }
    }

    return $OSCloudOS | Select-Object -First 1
}
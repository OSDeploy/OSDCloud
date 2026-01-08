function Get-PSOSDCloudOperatingSystem {
    [CmdletBinding()]
    param ()
    $ErrorActionPreference = 'Stop'

    <#
        Id              : Windows 11 25H2 amd64 Retail en-gb 26200.7462
        OperatingSystem : Windows 11 25H2
        OSName          : Windows 11
        OSVersion       : 25H2
        OSArchitecture  : amd64
        OSActivation    : Retail
        OSLanguageCode  : en-gb
        OSLanguage      : English (United Kingdom)
        OSBuild         : 26200
        OSBuildVersion  : 26200.7462
        Size            : 5626355066
        Sha1            :
        Sha256          : 566a518dc46ba5ea401381810751a8abcfe7d012b2f81c9709b787358c606926
        FileName        : 26200.7462.251207-0044.25h2_ge_release_svc_refresh_CLIENTCONSUMER_RET_x64FRE_en-gb.esd
        FilePath        : http://dl.delivery.mp.microsoft.com/filestreamingservice/files/79a3f5e0-d04d-4689-a5d4-3ea35f8b189a/26200.7462.251207-0044.25h2_ge_release_svc_refresh_CLIENTCONSUMER_RET_x64FRE_en-gb.esd
    #>

    $records = Get-PSOSDCloudOperatingSystems
    #=================================================
    # Limit the results based on $env:PROCESSOR_ARCHITECTURE
    $ProcessorArchitecture = $env:PROCESSOR_ARCHITECTURE
    if ($ProcessorArchitecture -and ($records.OSArchitecture -match $ProcessorArchitecture)) {
        Write-Verbose "Set OSArchitecture from PROCESSOR_ARCHITECTURE environment variable $ProcessorArchitecture"
        $records = $records | Where-Object { $_.OSArchitecture -eq $ProcessorArchitecture }
    }
    #=================================================
    # OSDCloud OSLanguageCode
    # Preference Order:
    # 1. $global:OSDCLOUD_OSLANGUAGECODE
    $LanguageCodeGlobal = $global:OSDCLOUD_OSLANGUAGECODE
    # 2. $env:OSDCLOUD_OSLANGUAGECODE
    $LanguageCodeEnvironment = $env:OSDCLOUD_OSLANGUAGECODE
    # 3. Get-Culture
    $LanguageCodeCulture = Get-Culture | Select-Object -ExpandProperty Name -First 1

    if ($LanguageCodeGlobal -and ($records.OSLanguageCode -match $LanguageCodeGlobal)) {
        Write-Verbose "Set OSLanguageCode from global variable $LanguageCodeGlobal"
        $records = $records | Where-Object { $_.OSLanguageCode -eq $LanguageCodeGlobal }
    }
    elseif ($LanguageCodeEnvironment -and ($records.OSLanguageCode -match $LanguageCodeEnvironment)) {
        Write-Verbose "Set OSLanguageCode from environment variable $LanguageCodeEnvironment"
        $records = $records | Where-Object { $_.OSLanguageCode -eq $LanguageCodeEnvironment }
    }
    elseif ($LanguageCodeCulture -and ($records.OSLanguageCode -match $LanguageCodeCulture)) {
        Write-Verbose "Set OSLanguageCode from Get-Culture value $LanguageCodeCulture"
        $records = $records | Where-Object { $_.OSLanguageCode -eq $LanguageCodeCulture }
    }
    else {
        Write-Verbose "No OSLanguageCode preference set, using default records"
    }
    #=================================================
    return $records | Select-Object -First 1
}
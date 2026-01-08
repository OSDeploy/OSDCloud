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
        LanguageCode    : en-gb
        Language        : English (United Kingdom)
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
        Write-Verbose "Client OSArchitecture from environment variable env:PROCESSOR_ARCHITECTURE is $ProcessorArchitecture. Filtering results for OSArchitecture = $ProcessorArchitecture"
        $records = $records | Where-Object { $_.OSArchitecture -eq $ProcessorArchitecture }
    }
    #=================================================
    # OSDCloud LanguageCode
    # Preference Order:
    # 1. $global:OSDCLOUD_LANGUAGECODE
    # 2. $env:OSDCLOUD_LANGUAGECODE
    # 3. Get-Culture
    #TODO this needs more work to make sure there is a single match
    $Culture = Get-Culture | Select-Object -ExpandProperty Name -First 1

    if ($global:OSDCLOUD_LANGUAGECODE) {
        $p = [string]$global:OSDCLOUD_LANGUAGECODE
        if ($p -and ($records.LanguageCode -match $p)) {
            Write-Verbose "Filtering results for LanguageCode = global:OSDCLOUD_LANGUAGECODE = $p"
            $records = $records | Where-Object { $_.LanguageCode -eq $p }
        }
    }
    elseif ($env:OSDCLOUD_LANGUAGECODE) {
        $p = [string]$env:OSDCLOUD_LANGUAGECODE
        if ($p -and ($records.LanguageCode -match $p)) {
            Write-Verbose "Environment variable env:OSDCLOUD_LANGUAGECODE is $p. Filtering results for LanguageCode = $p"
            $records = $records | Where-Object { $_.LanguageCode -eq $p }
        }
    }
    elseif ($Culture -and ($records.LanguageCode -match $Culture)) {
        Write-Verbose "Filtering results for LanguageCode = Get-Culture = $p"
        $records = $records | Where-Object { $_.LanguageCode -eq $Culture }
    }

    return $records | Select-Object -First 1
}
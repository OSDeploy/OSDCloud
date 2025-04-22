function Initialize-OSDCloudOSSettings {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $PathAmd64 = "$($MyInvocation.MyCommand.Module.ModuleBase)\settings\os-amd64.json",

        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $PathArm64 = "$($MyInvocation.MyCommand.Module.ModuleBase)\settings\os-arm64.json",

        [System.Management.Automation.SwitchParameter]
        $AsJson,

        [System.String]
        $Architecture = $Env:PROCESSOR_ARCHITECTURE
    )
    #=================================================
    $Error.Clear()
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Start"
    $ModuleName = $($MyInvocation.MyCommand.Module.Name)
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] ModuleName: $ModuleName"
    $ModuleBase = $($MyInvocation.MyCommand.Module.ModuleBase)
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] ModuleBase: $ModuleBase"
    $ModuleVersion = $($MyInvocation.MyCommand.Module.Version)
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] ModuleVersion: $ModuleVersion"
    #=================================================
    # Import the RAW content of the JSON file
    if ($Architecture -eq 'AMD64') {
        $Path = $PathAmd64
    } elseif ($Architecture -eq 'ARM64') {
        $Path = $PathArm64
    } else {
        Write-Error "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Invalid Architecture: $Architecture"
        break
    }
    $rawJsonContent = Get-Content -Path $Path -Raw

    if ($AsJson) {
        return $rawJsonContent
    }

    # https://stackoverflow.com/questions/51066978/convert-to-json-with-comments-from-powershell
    $JsonContent = $rawJsonContent -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/'

    $hashtable = [ordered]@{}
    (ConvertFrom-Json $JsonContent).psobject.properties | ForEach-Object { $hashtable[$_.Name] = $_.Value }

    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Initialized InitializeOSDCloudOSSettings: $Path"
    $global:InitializeOSDCloudOSSettings = $hashtable
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
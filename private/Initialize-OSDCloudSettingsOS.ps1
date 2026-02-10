function Initialize-OSDCloudSettingsOS {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name = 'default',

        [System.Management.Automation.SwitchParameter]
        $AsJson,

        [System.String]
        $Architecture = $env:PROCESSOR_ARCHITECTURE,

        $Path = "$($MyInvocation.MyCommand.Module.ModuleBase)\workflow"
    )
    #=================================================
    $Error.Clear()
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    $ModuleName = $($MyInvocation.MyCommand.Module.Name)
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] ModuleName: $ModuleName"
    $ModuleBase = $($MyInvocation.MyCommand.Module.ModuleBase)
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] ModuleBase: $ModuleBase"
    $ModuleVersion = $($MyInvocation.MyCommand.Module.Version)
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] ModuleVersion: $ModuleVersion"
    #=================================================
    # Workflow Path must exist, there is no fallback
    if (-not (Test-Path $Path)) {
        Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] The specified Path does not exist"
        Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] $Path"
        break
    }

    $OSDCloudWorkflowNamedPath = Join-Path $Path $Name
    $OSDCloudWorkflowDefaultPath = Join-Path $Path 'default'

    $osamd64Path = "$OSDCloudWorkflowNamedPath\os-amd64.json"
    $osarm64Path = "$OSDCloudWorkflowNamedPath\os-arm64.json"

    if (-not ($OSDCloudWorkflowNamedPath -eq $OSDCloudWorkflowDefaultPath)) {
        if (-not (Test-Path $osamd64Path)) {
            $osamd64Path = "$OSDCloudWorkflowDefaultPath\os-amd64.json"
        }
        if (-not (Test-Path $osarm64Path)) {
            $osarm64Path = "$OSDCloudWorkflowDefaultPath\os-arm64.json"
        }
    }

    # Import the RAW content of the JSON file
    if ($Architecture -eq 'AMD64') {
        if (-not (Test-Path $osamd64Path)) {
            Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Unable to find $osamd64Path"
            break
        }
        else {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] $osamd64Path"
        }
        $OSDCloudSettingsOSFile = $osamd64Path
    }
    elseif ($Architecture -eq 'ARM64') {
        if (-not (Test-Path $osarm64Path)) {
            Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Unable to find $osarm64Path"
            break
        }
        else {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] $osarm64Path"
        }
        $OSDCloudSettingsOSFile = $osarm64Path
    }
    else {
        Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Invalid Architecture: $Architecture"
        break
    }
    
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Importing settings from $OSDCloudSettingsOSFile"
    $rawJsonContent = Get-Content -Path $OSDCloudSettingsOSFile -Raw

    if ($AsJson) {
        return $rawJsonContent
    }

    # https://stackoverflow.com/questions/51066978/convert-to-json-with-comments-from-powershell
    $JsonContent = $rawJsonContent -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/'

    $hashtable = [ordered]@{}
    (ConvertFrom-Json $JsonContent).psobject.properties | ForEach-Object { $hashtable[$_.Name] = $_.Value }

    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSDCloud OS Settings are stored in `$global:OSDCloudSettingsOS"
    $global:OSDCloudSettingsOS = $hashtable
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
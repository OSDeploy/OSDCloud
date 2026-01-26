function Initialize-OSDCloudWorkflowSettingsOS {
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

    $WorkflowSettingsOSPath = Join-Path $Path $Name
    $WorkflowSettingsOSDefaultPath = Join-Path $Path 'default'

    $PathAmd64 = "$WorkflowSettingsOSPath\os-amd64.json"
    $PathArm64 = "$WorkflowSettingsOSPath\os-arm64.json"

    if (-not ($WorkflowSettingsOSPath -eq $WorkflowSettingsOSDefaultPath)) {
        if (-not (Test-Path $PathAmd64)) {
            $PathAmd64 = "$WorkflowSettingsOSDefaultPath\os-amd64.json"
        }
        if (-not (Test-Path $PathArm64)) {
            $PathArm64 = "$WorkflowSettingsOSDefaultPath\os-arm64.json"
        }
    }

    # Import the RAW content of the JSON file
    if ($Architecture -eq 'AMD64') {
        if (-not (Test-Path $PathAmd64)) {
            Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Unable to find $PathAmd64"
            break
        }
        else {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] $PathAmd64"
        }
        $SettingsOSPath = $PathAmd64
    }
    elseif ($Architecture -eq 'ARM64') {
        if (-not (Test-Path $PathArm64)) {
            Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Unable to find $PathArm64"
            break
        }
        else {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] $PathArm64"
        }
        $SettingsOSPath = $PathArm64
    }
    else {
        Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Invalid Architecture: $Architecture"
        break
    }
    
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Importing settings from $SettingsOSPath"
    $rawJsonContent = Get-Content -Path $SettingsOSPath -Raw

    if ($AsJson) {
        return $rawJsonContent
    }

    # https://stackoverflow.com/questions/51066978/convert-to-json-with-comments-from-powershell
    $JsonContent = $rawJsonContent -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/'

    $hashtable = [ordered]@{}
    (ConvertFrom-Json $JsonContent).psobject.properties | ForEach-Object { $hashtable[$_.Name] = $_.Value }

    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSDCloud OS Settings are stored in `$global:OSDCloudWorkflowSettingsOS"
    $global:OSDCloudWorkflowSettingsOS = $hashtable
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
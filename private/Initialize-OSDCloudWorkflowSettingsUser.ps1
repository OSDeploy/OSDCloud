function Initialize-OSDCloudWorkflowSettingsUser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [System.String]
        $WorkflowName = 'default',

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

    $OSDCloudWorkflowNamedPath = Join-Path $Path $WorkflowName
    $OSDCloudWorkflowDefaultPath = Join-Path $Path 'default'

    $useramd64Path = "$OSDCloudWorkflowNamedPath\user-amd64.json"
    $userarm64Path = "$OSDCloudWorkflowNamedPath\user-arm64.json"

    if (-not ($OSDCloudWorkflowNamedPath -eq $OSDCloudWorkflowDefaultPath)) {
        if (-not (Test-Path $useramd64Path)) {
            $useramd64Path = "$OSDCloudWorkflowDefaultPath\user-amd64.json"
        }
        if (-not (Test-Path $userarm64Path)) {
            $userarm64Path = "$OSDCloudWorkflowDefaultPath\user-arm64.json"
        }
    }

    # Import the RAW content of the JSON file
    if ($Architecture -eq 'AMD64') {
        if (-not (Test-Path $useramd64Path)) {
            Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Unable to find $useramd64Path"
            break
        }
        else {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] $useramd64Path"
        }
        $OSDCloudWorkflowSettingsUserFile = $useramd64Path
    }
    elseif ($Architecture -eq 'ARM64') {
        if (-not (Test-Path $userarm64Path)) {
            Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Unable to find $userarm64Path"
            break
        }
        else {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] $userarm64Path"
        }
        $OSDCloudWorkflowSettingsUserFile = $userarm64Path
    }
    else {
        Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Invalid Architecture: $Architecture"
        break
    }
    $rawJsonContent = Get-Content -Path $OSDCloudWorkflowSettingsUserFile -Raw

    if ($AsJson) {
        return $rawJsonContent
    }

    # https://stackoverflow.com/questions/51066978/convert-to-json-with-comments-from-powershell
    $JsonContent = $rawJsonContent -replace '(?m)(?<=^([^"]|"[^"]*")*)//.*' -replace '(?ms)/\*.*?\*/'

    $hashtable = [ordered]@{}
    (ConvertFrom-Json $JsonContent).psobject.properties | ForEach-Object { $hashtable[$_.Name] = $_.Value }

    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Initialized OSDCloudWorkflowSettingsUser: $OSDCloudWorkflowSettingsUserFile"
    $global:OSDCloudWorkflowSettingsUser = $hashtable
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
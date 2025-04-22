function Initialize-OSDCloudFlows {
    [CmdletBinding()]
    param (
        $Architecture = $Env:PROCESSOR_ARCHITECTURE,
        $Path = "$($MyInvocation.MyCommand.Module.ModuleBase)\workflows"
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
    $WorkflowFiles = Get-ChildItem -Path $Path -Filter '*.json' -Recurse -ErrorAction SilentlyContinue

    $InitializeOSDCloudFlows = foreach ($item in $WorkflowFiles) {
        Get-Content $item.FullName -Raw | ConvertFrom-Json
    }

    if ($Architecture -match 'amd64') {
        Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Filtering amd64 workflows"
        $InitializeOSDCloudFlows = $InitializeOSDCloudFlows | Where-Object { $_.amd64 -eq $true }
    }
    elseif ($Architecture -match 'arm64') {
        Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Filtering arm64 workflows"
        $InitializeOSDCloudFlows = $InitializeOSDCloudFlows | Where-Object { $_.arm64 -eq $true }
    }

    if ($InitializeOSDCloudFlows.Count -eq 0) {
        Write-Error "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] No workflows found for architecture: $Architecture"
        break
    }

    $global:InitializeOSDCloudFlows = $InitializeOSDCloudFlows | Sort-Object -Property @{Expression='default';Descending=$true}, @{Expression='name';Descending=$false}
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
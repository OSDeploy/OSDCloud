function Initialize-OSDCloudWorkflowTasks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name = 'default',

        $Architecture = $Env:PROCESSOR_ARCHITECTURE,

        $Path = "$($MyInvocation.MyCommand.Module.ModuleBase)\workflow"
    )
    #=================================================
    $Error.Clear()
    Write-Verbose "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] Start"
    $ModuleName = $($MyInvocation.MyCommand.Module.Name)
    Write-Verbose "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] ModuleName: $ModuleName"
    $ModuleBase = $($MyInvocation.MyCommand.Module.ModuleBase)
    Write-Verbose "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] ModuleBase: $ModuleBase"
    $ModuleVersion = $($MyInvocation.MyCommand.Module.Version)
    Write-Verbose "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] ModuleVersion: $ModuleVersion"
    #=================================================
    $WorkflowJobFiles = Get-ChildItem -Path "$Path\$Name\tasks" -Filter '*.json' -Recurse -ErrorAction SilentlyContinue

    if (-not ($WorkflowJobFiles)) {
        Write-Warning "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] OSDCloud Workflows do not exist in the specified Path"
        Write-Warning "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] $Path\$Name\tasks"
        Write-Warning "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] The Name `"$Name`" may not be valid"
        break
    }

    $OSDCloudWorkflowTasks = foreach ($item in $WorkflowJobFiles) {
        Get-Content $item.FullName -Raw | ConvertFrom-Json
    }

    if ($Architecture -match 'amd64') {
        Write-Verbose "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] Filtering amd64 workflows"
        $OSDCloudWorkflowTasks = $OSDCloudWorkflowTasks | Where-Object { $_.amd64 -eq $true }
    }
    elseif ($Architecture -match 'arm64') {
        Write-Verbose "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] Filtering arm64 workflows"
        $OSDCloudWorkflowTasks = $OSDCloudWorkflowTasks | Where-Object { $_.arm64 -eq $true }
    }

    if ($OSDCloudWorkflowTasks.Count -eq 0) {
        Write-Error "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] No workflows found for architecture: $Architecture"
        break
    }

    $global:OSDCloudWorkflowTasks = $OSDCloudWorkflowTasks | Sort-Object -Property @{Expression='default';Descending=$true}, @{Expression='name';Descending=$false}
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
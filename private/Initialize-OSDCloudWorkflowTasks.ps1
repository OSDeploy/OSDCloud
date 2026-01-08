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

        [System.String]
        $Architecture = $env:PROCESSOR_ARCHITECTURE,

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
    # Workflow Path must exist, there is no fallback
    if (-not (Test-Path $Path)) {
        Write-Warning "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] The specified Path does not exist"
        Write-Warning "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] $Path"
        break
    }

    # Is the name not default?
    if ($Name -ne 'default') {
        $WorkflowTasksPath = Join-Path $Path (Join-Path $Name 'tasks')

        # Gather the Json files
        try {
            $WorkflowTasksFiles = Get-ChildItem -Path $WorkflowTasksPath -Filter '*.json' -Recurse -ErrorAction Stop
        }
        catch {
            $Name = 'default'
        }

        # Are there Json files that can be used?
        if (-not ($WorkflowTasksFiles)) {
            $Name = 'default'
        }
    }

    # Use the default path
    if ($Name -eq 'default') {
        $WorkflowTasksPath = Join-Path $Path (Join-Path $Name 'tasks')

        try {
            $WorkflowTasksFiles = Get-ChildItem -Path $WorkflowTasksPath -Filter '*.json' -Recurse -ErrorAction Stop
        }
        catch {
            Write-Warning "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] OSDCloud Workflows do not exist in the specified Path"
            Write-Warning "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] $WorkflowTasksPath"
            break
        }
    }

    if (-not ($WorkflowTasksFiles)) {
        Write-Warning "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] OSDCloud Workflows do not exist in the specified Path"
        Write-Warning "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] $WorkflowTasksPath"
        break
    }

    # Path that is going to be used 
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] $WorkflowTasksPath"

    $OSDCloudWorkflowTasks = foreach ($item in $WorkflowTasksFiles) {
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
        Write-Warning "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] No workflows found for architecture: $Architecture"
        break
    }

    $global:OSDCloudWorkflowTasks = $OSDCloudWorkflowTasks | Sort-Object -Property @{Expression='default';Descending=$true}, @{Expression='name';Descending=$false}
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
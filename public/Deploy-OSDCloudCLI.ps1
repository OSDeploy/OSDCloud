function Deploy-OSDCloudCLI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $Name = 'default'
    )
    #=================================================
    # Initialize OSDCloudWorkflow
    Initialize-OSDCloudWorkflow -Name $Name
    #=================================================
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] Invoke-OSDCloudWorkflow"
    $global:OSDCloudWorkflowInit.TimeStart = Get-Date
    $OSDCloudWorkflowInit | Out-Host
    Invoke-OSDCloudWorkflow
    #=================================================
}
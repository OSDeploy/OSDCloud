function Deploy-OSDCloudCLI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
        [System.String]
        $WorkflowName = 'default'
    )
    #=================================================
    # Initialize OSDCloudWorkflow
    Initialize-OSDCloudDeploy -WorkflowName $WorkflowName
    #=================================================
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Invoke-OSDCloudWorkflowTask"
    $global:OSDCloudDeploy.TimeStart = Get-Date
    $global:OSDCloudDeploy | Out-Host
    Invoke-OSDCloudWorkflowTask
    #=================================================
}
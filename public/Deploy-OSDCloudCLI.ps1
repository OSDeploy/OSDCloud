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
    Initialize-DeployOSDCloud -Name $Name
    #=================================================
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Invoke-OSDCloudWorkflowTask"
    $global:OSDCloudInitialize.TimeStart = Get-Date
    $OSDCloudInitialize | Out-Host
    Invoke-OSDCloudWorkflowTask
    #=================================================
}
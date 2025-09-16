function step-install-restartosdcloudlogs {
    [CmdletBinding()]
    param ()
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudWorkflowCurrentStep
    #=================================================
    #region Main
    $LogsPath = "C:\Windows\Temp\osdcloud-logs"

    $Params = @{
        Path        = $LogsPath
        ItemType    = 'Directory'
        Force       = $true
        ErrorAction = 'SilentlyContinue'
    }

    if (-not (Test-Path $Params.Path)) {
        New-Item @Params | Out-Null
    }

    $null = robocopy "X:\Windows\Temp\osdcloud-logs" "$LogsPath" transcript.log /e /move /ndl /nfl /r:0 /w:0
    $TranscriptFullName = Join-Path $LogsPath "transcript-$((Get-Date).ToString('yyyy-MM-dd-HHmmss')).log"

    $null = Start-Transcript -Path $TranscriptFullName -ErrorAction SilentlyContinue
    # Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] $TranscriptFullName"
    #endregion
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
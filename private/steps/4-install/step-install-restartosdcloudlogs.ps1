function step-install-restartosdcloudlogs {
    [CmdletBinding()]
    param ()
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSvDCloudWorkflowCurrentStep
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

    $TranscriptFullName = Join-Path $LogsPath "transcript.log"

    if (Test-Path "X:\Windows\Temp\osdcloud-logs\transcript.log") {
        Stop-Transcript -ErrorAction SilentlyContinue
        $null = robocopy "X:\Windows\Temp\osdcloud-logs" "C:\Windows\Temp\osdcloud-logs" transcript.log /e /move /ndl /nfl /r:0 /w:0
        Start-Transcript -Path $TranscriptFullName -Append -ErrorAction SilentlyContinue
    }
    #endregion
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
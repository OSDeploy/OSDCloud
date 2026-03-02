function step-initialize-osdcloudlogs {
    [CmdletBinding()]
    param ()
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Verbose -Message $Message; Write-Debug -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudCurrentStep
    #=================================================
    #region Main
    $LogsPath = "$env:TEMP\osdcloud-logs"

    # Ensure logs directory exists
    $null = New-Item -Path $LogsPath -ItemType Directory -Force -ErrorAction SilentlyContinue

    # Start transcript logging
    $TranscriptFullName = Join-Path $LogsPath "transcript-$((Get-Date).ToString('yyyy-MM-dd-HHmmss')).log"
    if (-not (Start-Transcript -Path $TranscriptFullName -ErrorAction SilentlyContinue)) {
        Write-Warning "[$(Get-Date -format s)] Failed to start transcript at $TranscriptFullName"
    }
    #endregion
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
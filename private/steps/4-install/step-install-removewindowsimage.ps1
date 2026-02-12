function step-install-removewindowsimage {
    [CmdletBinding()]
    param ()
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudCurrentStep
    #=================================================
    #region Main
    if (Test-Path "C:\OSDCloud") {
        try {
            Remove-Item -Path "C:\OSDCloud" -Recurse -Force -ErrorAction Stop | Out-Null
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Removed C:\OSDCloud"
        }
        catch {
            Write-Host -ForegroundColor DarkYellow "[$(Get-Date -format s)] Unable to remove C:\OSDCloud"
            Write-Host -ForegroundColor DarkYellow "[$(Get-Date -format s)] $_"
        }
        finally {
            $Error.Clear()
        }
    }
    #endregion
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
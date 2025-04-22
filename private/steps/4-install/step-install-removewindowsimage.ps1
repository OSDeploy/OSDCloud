function step-install-removewindowsimage {
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
    if (Test-Path "C:\OSDCloud") {
        try {
            Remove-Item -Path "C:\OSDCloud" -Recurse -Force -ErrorAction Stop | Out-Null
            Write-Host -ForegroundColor DarkGreen "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Removed C:\OSDCloud"
        }
        catch {
            Write-Host -ForegroundColor DarkYellow "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Unable to remove C:\OSDCloud"
            Write-Host -ForegroundColor DarkYellow "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] $_"
        }
        finally {
            $Error.Clear()
        }
    }
    #endregion
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
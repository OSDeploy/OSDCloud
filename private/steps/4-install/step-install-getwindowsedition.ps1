function step-install-getwindowsedition {
    [CmdletBinding()]
    param ()
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudWorkflowCurrentStep
    #=================================================
    try {
        $WindowsEdition = (Get-WindowsEdition -Path 'C:\' -ErrorAction Stop | Out-String).Trim()
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] $WindowsEdition"
        $global:OSDCloudWorkflowInvoke.WindowsEdition = $WindowsEdition
    }
    catch {
        Write-Host -ForegroundColor Yellow "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Unable to get Windows Edition. OK."
        Write-Host -ForegroundColor Yellow "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] $_"
    }
    finally {
        $Error.Clear()
    }
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
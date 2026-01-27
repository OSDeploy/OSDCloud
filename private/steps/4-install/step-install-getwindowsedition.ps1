function step-install-getwindowsedition {
    [CmdletBinding()]
    param ()
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudWorkflowCurrentStep
    #=================================================
    try {
        $WindowsEdition = (Get-WindowsEdition -Path 'C:\' -ErrorAction Stop | Out-String).Trim()
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] $WindowsEdition"
        $global:OSDCloudWorkflowInvoke.WindowsEdition = $WindowsEdition
    }
    catch {
        Write-Warning "[$(Get-Date -format s)] Unable to get Windows Edition. OK."
        Write-Warning "[$(Get-Date -format s)] $_"
    }
    finally {
        $Error.Clear()
    }
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
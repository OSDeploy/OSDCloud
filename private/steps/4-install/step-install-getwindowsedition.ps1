function step-install-getwindowsedition {
    [CmdletBinding()]
    param ()
    #=================================================
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message
    $Step = $global:OSDCloudCurrentStep
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
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
function step-test-targetwindowsimage {
    [CmdletBinding()]
    param (
        [System.String]
        $LaunchMethod = $global:OSDCloudWorkflowInvoke.LaunchMethod
    )
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudCurrentStep
    #=================================================
    # Is there an Operating System ImageFile URL?
    if (-not ($global:OSDCloudWorkflowInvoke.OperatingSystemObject.FilePath)) {
        Write-Warning "[$(Get-Date -format s)] OperatingSystemObject does not have a Url to validate."
        Write-Warning 'Press Ctrl+C to cancel OSDCloud'
        Start-Sleep -Seconds 86400
        exit
    }
    #=================================================
    # Is it reachable online?
    try {
        $WebRequest = Invoke-WebRequest -Uri $global:OSDCloudWorkflowInvoke.OperatingSystemObject.FilePath -UseBasicParsing -Method Head
        if ($WebRequest.StatusCode -eq 200) {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] OperatingSystem URL returned a 200 status code. OK."
            return
        }
    }
    catch {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] OperatingSystem URL is not reachable."
    }
    #=================================================
    # Does the file exist on a Drive?
    $FileName = Split-Path $global:OSDCloudWorkflowInvoke.OperatingSystemObject.FilePath -Leaf
    $MatchingFiles = @()
    $MatchingFiles = Get-PSDrive -PSProvider FileSystem | ForEach-Object {
        Get-ChildItem "$($_.Name):\OSDCloud\OS\" -Include "$FileName" -File -Recurse -Force -ErrorAction Ignore
    }
    
    if ($MatchingFiles) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] OperatingSystem is available offline. OK."
        return
    }
    else {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] OperatingSystem is not available offline."
    }
    #=================================================
    # Can't access the file so need to bail
    Write-Warning "[$(Get-Date -format s)] Unable to validate if the OperatingSystem is reachable online or offline."
    Write-Warning "Press Ctrl+C to cancel OSDCloud"
    Start-Sleep -Seconds 86400
    Exit
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}

<#
    if ($LaunchMethod) {
        #TODO This is not working for Core
        #$null = Install-Module -Name $global:OSDCloudWorkflowInvoke.LaunchMethod -Force -ErrorAction Ignore -WarningAction Ignore
    }

    if ($global:OSDCloudDeploy.LocalImageFileInfo) {
        # Test if the file is on USB (example: check if path starts with a removable drive letter)
        if (!(Test-Path $global:OSDCloudDeploy.LocalImageFileInfo)) {
            Write-Warning "[$(Get-Date -format s)] OSDCloud failed to find the Operating System Local ImageFile Item"
            Write-Warning $($global:OSDCloudDeploy.LocalImageFileInfo)
            Write-Warning "Press Ctrl+C to cancel OSDCloud"
            Start-Sleep -Seconds 86400
            Exit
        }
    }

    if ($global:OSDCloudWorkflowInvoke.LocalImageFileDestination) {
        if (!(Test-Path $global:OSDCloudWorkflowInvoke.LocalImageFileDestination)) {
            Write-Warning "[$(Get-Date -format s)] OSDCloud failed to find the Operating System Local ImageFile Destination"
            Write-Warning $($global:OSDCloudWorkflowInvoke.LocalImageFileDestination)
            Write-Warning 'Press Ctrl+C to cancel OSDCloud'
            Start-Sleep -Seconds 86400
            Exit
        }
    }
#>
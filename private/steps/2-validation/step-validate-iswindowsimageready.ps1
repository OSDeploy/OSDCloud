function step-validate-iswindowsimageready {
    [CmdletBinding()]
    param (
        [System.String]
        $LaunchMethod = $global:OSDCloudWorkflowInvoke.LaunchMethod
    )
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSvDCloudWorkflowCurrentStep
    #=================================================
    # Is there an Opeating System ImageFile URL?
    if (-not ($global:OSDCloudWorkflowInvoke.OperatingSystemObject.Url)) {
        Write-Warning "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] OperatingSystemObject does not have a Url to validate."
        Write-Warning 'Press Ctrl+C to cancel OSDCloud'
        Start-Sleep -Seconds 86400
        exit
    }
    #=================================================
    # Is it reachable online?
    try {
        $WebRequest = Invoke-WebRequest -Uri $global:OSDCloudWorkflowInvoke.OperatingSystemObject.Url -UseBasicParsing -Method Head
        if ($WebRequest.StatusCode -eq 200) {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] OperatingSystem URL returned a 200 status code. OK."
            return
        }
    }
    catch {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] OperatingSystem URL is not reachable."
    }
    #=================================================
    # Does the file exist on a Drive?
    $FileName = Split-Path $global:OSDCloudWorkflowInvoke.OperatingSystemObject.Url -Leaf
    $MatchingFiles = @()
    $MatchingFiles = Get-PSDrive -PSProvider FileSystem | ForEach-Object {
        Get-ChildItem "$($_.Name):\OSDCloud\OS\" -Include "$FileName" -File -Recurse -Force -ErrorAction Ignore
    }
    
    if ($MatchingFiles) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] OperatingSystem is available offline. OK."
        return
    }
    else {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] OperatingSystem is not available offline."
    }
    #=================================================
    # Can't access the file so need to bail
    Write-Warning "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Unable to validate if the OperatingSystem is reachable online or offline."
    Write-Warning "Press Ctrl+C to cancel OSDCloud"
    Start-Sleep -Seconds 86400
    Exit
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}

<#
    if ($LaunchMethod) {
        #TODO This is not working for Core
        #$null = Install-Module -Name $global:OSDCloudWorkflowInvoke.LaunchMethod -Force -ErrorAction Ignore -WarningAction Ignore
    }

    if ($global:OSDCloudWorkflowInit.LocalImageFileInfo) {
        # Test if the file is on USB (example: check if path starts with a removable drive letter)
        if (!(Test-Path $global:OSDCloudWorkflowInit.LocalImageFileInfo)) {
            Write-Warning "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] OSDCloud failed to find the Operating System Local ImageFile Item"
            Write-Warning $($global:OSDCloudWorkflowInit.LocalImageFileInfo)
            Write-Warning "Press Ctrl+C to cancel OSDCloud"
            Start-Sleep -Seconds 86400
            Exit
        }
    }

    if ($global:OSDCloudWorkflowInvoke.LocalImageFileDestination) {
        if (!(Test-Path $global:OSDCloudWorkflowInvoke.LocalImageFileDestination)) {
            Write-Warning "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] OSDCloud failed to find the Operating System Local ImageFile Destination"
            Write-Warning $($global:OSDCloudWorkflowInvoke.LocalImageFileDestination)
            Write-Warning 'Press Ctrl+C to cancel OSDCloud'
            Start-Sleep -Seconds 86400
            Exit
        }
    }
#>
function step-drivers-msupdate {
    [CmdletBinding()]
    param ()
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudWorkflowCurrentStep
    #=================================================
    # Gather Variables
    $ComputerManufacturer = $global:OSDCloudWorkflowInit.ComputerManufacturer
    #=================================================
    # Step Variables
    $DriverPackName = $global:OSDCloudWorkflowInit.DriverPackName
    #=================================================
    # Exclusions
    if ($PSVersionTable.PSVersion.Major -ne 5) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] PowerShell 5.1 is required to run this step. Skip."
        return
    }
    if (($IsVM -eq $true) -and ($ComputerManufacturer -match 'Microsoft')) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Microsoft Update Drivers is not enabled for Microsoft Hyper-V. Skip."
        return
    }
    if ($DriverPackName -eq 'None') {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Microsoft Update Drivers is not enabled. Skip."
        return
    }
    #=================================================
    # Is it reachable online?
    $Url = 'https://catalog.update.microsoft.com/Home.aspx'
    try {
        $WebRequest = Invoke-WebRequest -Uri $Url -UseBasicParsing -Method Head
        if ($WebRequest.StatusCode -eq 200) {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Microsoft Update Catalog URL returned a 200 status code. OK."
        }
    }
    catch {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Microsoft Update Catalog URL is not reachable. Skip."
        return
    }
    #=================================================
    # Microsoft Update Catalog
    if ($DriverPackName -eq 'Microsoft Update Catalog') {
        $DestinationDirectory = "C:\Windows\Temp\osdcloud-drivers-msupdate"
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Microsoft Update Drivers is enabled for all devices. OK."
        Save-MsUpCatDriver -DestinationDirectory $DestinationDirectory
        return
    }
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Microsoft Update Drivers is enabled for critical devices. OK."

    $DestinationDirectory = "C:\Windows\Temp\osdcloud-drivers-disk"
    Save-MsUpCatDriver -DestinationDirectory $DestinationDirectory -PNPClass 'DiskDrive'
    
    $DestinationDirectory = "C:\Windows\Temp\osdcloud-drivers-net"
    Save-MsUpCatDriver -DestinationDirectory $DestinationDirectory -PNPClass 'Net'
    
    $DestinationDirectory = "C:\Windows\Temp\osdcloud-drivers-scsi"
    Save-MsUpCatDriver -DestinationDirectory $DestinationDirectory -PNPClass 'SCSIAdapter'
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
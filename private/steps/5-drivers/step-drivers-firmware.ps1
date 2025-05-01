function step-drivers-firmware {
    [CmdletBinding()]
    param ()
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudWorkflowCurrentStep
    #=================================================
    if ($PSVersionTable.PSVersion.Major -ne 5) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] PowerShell 5.1 is required to run this step. Skip."
        return
    }
    if ($IsVM -eq $true) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] Microsoft Update Firmware is not enabled for Virtual Machines. Skip."
        return
    }
    if ($IsOnBattery -eq $true) {
        # Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] Microsoft Update Firmware is not enabled for devices on battery power"
        # return
    }
    #=================================================
    # Is it reachable online?
    $Url = 'https://catalog.update.microsoft.com/Home.aspx'
    try {
        $WebRequest = Invoke-WebRequest -Uri $Url -UseBasicParsing -Method Head
        if ($WebRequest.StatusCode -eq 200) {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] Microsoft Update Catalog URL returned a 200 status code. OK."
        }
    }
    catch {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] Microsoft Update Catalog URL is not reachable. Skip."
        return
    }

    $FirmwarePath = "C:\Windows\Temp\osdcloud\drivers-firmware"

    $Params = @{
        Path        = $FirmwarePath
        ItemType    = 'Directory'
        Force       = $true
        ErrorAction = 'SilentlyContinue'
    }

    if (-not (Test-Path $Params.Path)) {
        New-Item @Params | Out-Null
    }

    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] Firmware Updates will be downloaded from Microsoft Update Catalog to $FirmwarePath"
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] Not all systems support a driver Firmware Update"
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] BIOS or Firmware Settings may need to be enabled for Firmware Updates"
    Save-SystemFirmwareUpdate -DestinationDirectory $FirmwarePath
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
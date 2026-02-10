function step-drivers-firmware {
    [CmdletBinding()]
    param ()
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudWorkflowCurrentStep
    #=================================================
    if ($PSVersionTable.PSVersion.Major -ne 5) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] PowerShell 5.1 is required to run this step. Skip."
        return
    }
    if ($IsVM -eq $true) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Microsoft Update Firmware is not enabled for Virtual Machines. Skip."
        return
    }
    if ($IsOnBattery -eq $true) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Microsoft Update Firmware is not enabled for devices on battery power"
        return
    }
    #=================================================
    # Is it reachable online?
    $Url = 'https://catalog.update.microsoft.com/Home.aspx'
    try {
        $WebRequest = Invoke-WebRequest -Uri $Url -UseBasicParsing -Method Head
        if ($WebRequest.StatusCode -eq 200) {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Microsoft Update Catalog returned a 200 status code. OK."
        }
    }
    catch {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Microsoft Update Catalog is not reachable. Skip."
        return
    }

    <#
    $FirmwarePath = "C:\Windows\Temp\osdcloud-drivers-firmware"

    $Params = @{
        Path        = $FirmwarePath
        ItemType    = 'Directory'
        Force       = $true
        ErrorAction = 'SilentlyContinue'
    }

    if (-not (Test-Path $Params.Path)) {
        New-Item @Params | Out-Null
    }
    #>

    $DestinationDirectory = "C:\Windows\Temp\osdcloud-drivers-firmware"
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Firmware Updates will be downloaded from Microsoft Update Catalog to $DestinationDirectory"
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Not all systems support a driver Firmware Update"
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] BIOS or Firmware Settings may need to be enabled for Firmware Updates"
    # Save-SystemFirmwareUpdate -DestinationDirectory $DestinationDirectory

    $SystemFirmwareId = Get-SystemFirmwareResource
    $SystemFirmwareId = $SystemFirmwareId -replace '[{}]',''
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] System Firmware Hardware ID: $SystemFirmwareId"

    <#
        Try {
            Get-MicrosoftUpdateCatalogResult -Search $SystemFirmwareId -SortBy Date -Descending | Select-Object LastUpdated,Title,Version,Size,Guid -First 1
        }
        Catch {
            #Do nothing
        }

    #>

    Save-MicrosoftUpdateCatalogDriver -DestinationDirectory $DestinationDirectory -HardwareID $SystemFirmwareId
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
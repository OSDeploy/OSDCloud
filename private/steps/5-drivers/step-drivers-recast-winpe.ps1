function step-drivers-recast-winpe {
    [CmdletBinding()]
    param ()
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudTaskCurrentStep
    #=================================================
    # Output Path
    $OutputPath = "C:\Windows\Temp\osdcloud-drivers-recast"
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    $LogPath = "C:\Windows\Temp\osdcloud-logs"
    if (-not (Test-Path -Path $LogPath)) {
        New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
    }
    #=================================================
    # Gather In-Use Drivers
    $PnputilXml = & pnputil.exe /enum-devices /format xml
    $PnputilXmlObject = [xml]$PnputilXml
    $PnputilDevices = $PnputilXmlObject.PnpUtil.Device | `
        Where-Object { $_.DriverName -like "oem*.inf" } | `
        Sort-Object DriverName -Unique | `
        Select-Object -Property DriverName, Status, ClassGuid, ClassName, DeviceDescription, ManufacturerName, InstanceId
    
    if ($PnputilDevices) {
        $PnputilDevices | Export-Clixml -Path "$LogPath\drivers-recast-winpe.xml" -Force
        # Export Drivers to Disk
        Write-Verbose "[$(Get-Date -format s)] Export drivers to: $OutputPath"
        foreach ($Device in $PnputilDevices) {
            # Check that the Device has a DriverName
            if ($Device.Drivername) {
                $FolderName = $Device.DriverName -replace '.inf', ''
                $destinationPath = $OutputPath + "\$($Device.ClassName)\" + $FolderName
                # Ensure the output directory exists
                if (-not (Test-Path -Path $destinationPath)) {
                    New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
                }
                
                # Export the driver using pnputil
                Write-Verbose "[$(Get-Date -format s)] Export $($Device.DriverName) to: $destinationPath"
                $null = & pnputil.exe /export-driver $Device.DriverName $destinationPath
            }
        }
    }
    #=================================================
    #=================================================
    # Registry OOBEInProgressDriverUpdatesPostponed
    <#
$Content = @"
:: ========================================================
:: OOBEInProgressDriverUpdatesPostponed
:: ========================================================
reg add "HKEY_LOCAL_MACHINE\SYSTEM\Setup" /v OOBEInProgressDriverUpdatesPostponed /t REG_DWORD /d 0 /f
:: ========================================================
"@
    $ScriptsPath = "C:\Windows\Setup\Scripts"
    $SetupCompleteCmd = "$ScriptsPath\SetupComplete.cmd"
    if (-not (Test-Path $ScriptsPath)) {
        New-Item -Path $ScriptsPath -ItemType Directory -Force -ErrorAction Ignore | Out-Null
    }
    $Content | Out-File -FilePath $SetupCompleteCmd -Append -Encoding ascii -Width 2000 -Force
    #>
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
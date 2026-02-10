function Export-WinpeDriversFromOS {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $Path = "$env:Temp\winpe-drivers"
    )
    Write-Host "[$(Get-Date -format s)] Exporting Drivers from the current OS to $Path"
    $PnputilXml = & pnputil.exe /enum-devices /connected /format xml
    $PnputilXmlObject = [xml]$PnputilXml
    $PnputilDevices = $PnputilXmlObject.PnpUtil.Device | Where-Object {$_.DriverName -match 'oem'} | Sort-Object DriverName -Unique | Sort-Object ClassName
    #$PnputilExtension = $PnputilXmlObject.PnpUtil.Device.ExtensionDriverNames

    if ($PnputilDevices) {
        #return $PnputilExtension
        #return $PnputilXmlObject
        #return $PnputilDevices

        foreach ($Device in $PnputilDevices) {
            # Don't process these Drivers
            if ($Device.ClassName -match "AudioEndpoint|AudioProcessingObject|Biometric|Bluetooth|Camera|ComputeAccelerator|Display|Firmware|MEDIA|Printer|PrintQueue|SoftwareComponent|SoftwareDevice|WSDPrintDevice") {
                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] $($Device.ClassName) - $($Device.DeviceDescription)"
                continue
            }
            if ($Device.DeviceDescription -match "Firmware|Smart Sound") {
                Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] $($Device.ClassName) - $($Device.DeviceDescription)"
                continue
            }

            Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format s)] $($Device.ClassName) - $($Device.DeviceDescription)"
            $FolderName = $Device.DriverName -replace '.inf', ''
            $ExportPath = "$Path\$($Device.ClassName)\$($Device.ManufacturerName)\$FolderName"

            if (-not (Test-Path -Path $ExportPath)) {
                New-Item -ItemType Directory -Path $ExportPath -Force | Out-Null
            }

            $null = & pnputil.exe /export-driver $Device.DriverName $ExportPath

            # Calculate folder size of the exported driver
            $FolderSizeBytes = (Get-ChildItem -Path $ExportPath -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            if (-not $FolderSizeBytes) { $FolderSizeBytes = 0 }

            $FolderSizeMB = [math]::Round($FolderSizeBytes / 1MB, 2)
            Write-Host "[$(Get-Date -format s)] $FolderSizeMB MB"
        }
    }
}
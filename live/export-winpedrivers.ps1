#region Device
$deviceManufacturer = (Get-CimInstance -ClassName CIM_ComputerSystem -ErrorAction Stop).Manufacturer
$deviceManufacturer = $deviceManufacturer -as [string]
if ([string]::IsNullOrWhiteSpace($deviceManufacturer)) {
    $deviceManufacturer = 'OEM'
} else {
    $deviceManufacturer = $deviceManufacturer.Trim()
}
$deviceModel = ((Get-CimInstance -ClassName CIM_ComputerSystem).Model).Trim()
$deviceModel = $deviceModel -as [string]
if ([string]::IsNullOrWhiteSpace($deviceModel)) {
    $deviceModel = 'OEM'
} elseif ($deviceModel -match 'OEM|to be filled') {
    $deviceModel = 'OEM'
}
$deviceProduct = ((Get-CimInstance -ClassName Win32_BaseBoard).Product).Trim()
$deviceSystemSKU = ((Get-CimInstance -ClassName CIM_ComputerSystem).SystemSKUNumber).Trim()
$deviceVersion = ((Get-CimInstance -ClassName Win32_ComputerSystemProduct).Version).Trim()
if ($deviceManufacturer -match 'Dell') {
    $deviceManufacturer = 'Dell'
    $deviceModelId = $deviceSystemSKU
}
if ($deviceManufacturer -match 'Hewlett|Packard|\bHP\b') {
    $deviceManufacturer = 'HP'
    $deviceModelId = $deviceProduct
}
if ($deviceManufacturer -match 'Lenovo') {
    $deviceManufacturer = 'Lenovo'
    $deviceModel = $deviceVersion
    $deviceModelId = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty Model).SubString(0, 4)
}
if ($deviceManufacturer -match 'Microsoft') {
    $deviceManufacturer = 'Microsoft'
    # Surface_Book or Surface_Pro_3
    $deviceModelId = $deviceSystemSKU
    # Surface Book or Surface Pro 3
    # $deviceProduct
}
if ($deviceManufacturer -match 'Panasonic') { $deviceManufacturer = 'Panasonic' }
if ($deviceManufacturer -match 'OEM|to be filled') { $deviceManufacturer = 'OEM' }
#endregion

# Export Path
$ExportPath = "$env:Temp\WinPEDriver\$deviceManufacturer\$deviceModelId $deviceModel"

# Set the export path to the clipboard for easy access
Set-Clipboard -Value "$env:Temp\WinPEDriver"

Write-Host "[$(Get-Date -format s)] Exporting OEMDrivers to $ExportPath"
$PnputilXml = & pnputil.exe /enum-devices /connected /format xml
$PnputilXmlObject = [xml]$PnputilXml
$PnputilDevices = $PnputilXmlObject.PnpUtil.Device | Where-Object {$_.DriverName -match 'oem'} | Sort-Object DriverName -Unique | Sort-Object ClassName
#$PnputilExtension = $PnputilXmlObject.PnpUtil.Device.ExtensionDriverNames

if ($PnputilDevices) {
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
        $ExportPath = "$ExportPath\$($Device.ClassName)\$($Device.ManufacturerName)\$FolderName"

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
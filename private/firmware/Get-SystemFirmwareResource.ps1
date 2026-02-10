function Get-SystemFirmwareResource {
    [CmdLetBinding()]
    param ()

    $UefiFirmwareDevice = Get-SystemFirmwareDevice

    if ($UefiFirmwareDevice) {
        Convert-PNPDeviceIDtoGuid -PNPDeviceID $UefiFirmwareDevice.PNPDeviceID
    }
}
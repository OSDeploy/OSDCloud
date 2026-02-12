function Get-SystemFirmwareDevice {
    [CmdLetBinding()]
    param ()

    Get-CimInstance -ClassName Win32_PnpEntity | Where-Object ClassGuid -eq '{f2e7dd72-6468-4e36-b6f1-6488f42c1b52}' | Where-Object Caption -match 'System'
}
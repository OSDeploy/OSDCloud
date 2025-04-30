function Get-OSDCloudModuleVersion {
    [CmdletBinding()]
    param ()

    return $MyInvocation.MyCommand.Module.Version
}
function Get-OSDCloudModulePath {
    [CmdletBinding()]
    param ()

    return $MyInvocation.MyCommand.Module.ModuleBase
}
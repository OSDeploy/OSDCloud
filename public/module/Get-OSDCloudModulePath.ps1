function Get-OSvDCloudModulePath {
    [CmdletBinding()]
    param ()

    return $MyInvocation.MyCommand.Module.ModuleBase
}
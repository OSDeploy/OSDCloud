function Get-OSvDCloudModuleVersion {
    [CmdletBinding()]
    param ()

    return $MyInvocation.MyCommand.Module.Version
}
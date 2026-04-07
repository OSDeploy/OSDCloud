function Get-OSDCloudModuleVersion {
    <#
    .SYNOPSIS
        Returns the version of the OSDCloud module.

    .DESCRIPTION
        Returns the currently loaded version of the OSDCloud module as a System.Version object.
        This is useful for version checks, logging, and compatibility validation in scripts.

    .OUTPUTS
        System.Version. The version of the OSDCloud module.

    .EXAMPLE
        Get-OSDCloudModuleVersion

        Returns the loaded OSDCloud module version, e.g. '1.0.0'.
    #>
    [CmdletBinding()]
    [OutputType([System.Version])]
    param ()

    $MyInvocation.MyCommand.Module.Version
}
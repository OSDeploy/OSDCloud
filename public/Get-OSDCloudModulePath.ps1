function Get-OSDCloudModulePath {
    <#
    .SYNOPSIS
        Returns the base directory path of the OSDCloud module.

    .DESCRIPTION
        Returns the file system path to the root folder where the OSDCloud module is installed.
        This is useful for locating module-relative resources such as catalogs, templates, and support files.

    .OUTPUTS
        System.String. The absolute path to the OSDCloud module directory.

    .EXAMPLE
        Get-OSDCloudModulePath

        Returns the path to the OSDCloud module directory, e.g. 'C:\Program Files\WindowsPowerShell\Modules\OSDCloud\1.0.0'.
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param ()

    $MyInvocation.MyCommand.Module.ModuleBase
}
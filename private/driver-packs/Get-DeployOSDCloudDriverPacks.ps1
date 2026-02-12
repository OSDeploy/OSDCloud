function Get-DeployOSDCloudDriverPacks {
    <#
    .SYNOPSIS
    Returns the DriverPacks used by OSDCloud

    .DESCRIPTION
    Returns the DriverPacks used by OSDCloud

    .LINK
    https://github.com/OSDeploy/OSD/tree/master/Docs
    #>
    [CmdletBinding()]
    param ()
    $Results = Import-Clixml -Path "$(Get-OSDCloudModulePath)\catalogs\driverpack\build-driverpacks.xml"
    $Results
}
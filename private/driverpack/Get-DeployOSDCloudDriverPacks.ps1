<#
.SYNOPSIS
Retrieves driver pack information for the specified manufacturer and operating system architecture.

.DESCRIPTION
Gets driver pack catalogs based on the device manufacturer and OS architecture. For AMD64 architecture,
manufacturer-specific catalogs are loaded. For ARM64 and other architectures, the default catalog is returned.
Supports Dell, HP, Lenovo, Microsoft (Surface), and generic devices.

.PARAMETER Manufacturer
The device manufacturer name. Defaults to the value from $global:OSDCloudDevice.OSDManufacturer.
Supported values: Dell, HP, Lenovo, Microsoft, or any other value will use the Default catalog.

.PARAMETER Architecture
The operating system architecture. Defaults to the value from $global:OSDCloudDevice.OSArchitecture.
Typically 'amd64' or 'arm64'.

.OUTPUTS
PSCustomObject
Array of driver pack objects containing driver information for the specified manufacturer and architecture.

.EXAMPLE
PS> Get-DeployOSDCloudDriverPacks
Returns driver packs for the current device's manufacturer and architecture.

.EXAMPLE
PS> Get-DeployOSDCloudDriverPacks -Manufacturer 'Dell' -Architecture 'amd64'
Returns driver packs for Dell devices with AMD64 architecture.

.NOTES
Requires Get-OSDCloudModulePath to be available.
Requires manufacturer-specific cmdlets (Get-OSDCloudCatalogDell, Get-OSDCloudCatalogHp, etc.) to be available.
#>
function Get-DeployOSDCloudDriverPacks {
    [CmdletBinding()]
    param (
        [System.String]
        $Manufacturer = $global:OSDCloudDevice.OSDManufacturer,
        [System.String]
        $ProcessorArchitecture = $global:OSDCloudDevice.ProcessorArchitecture
    )

    # Load default catalog once
    $DefaultCatalogPath = Join-Path -Path (Get-OSDCloudModulePath) -ChildPath 'catalogs\driverpack\default.json'
    $DefaultCatalog = Get-Content -Path $DefaultCatalogPath -Raw | ConvertFrom-Json

    if ($ProcessorArchitecture -eq 'amd64') {
        $DriverPackValues = switch ($Manufacturer) {
            'Dell' { Get-OSDCloudCatalogDell }
            'HP' { Get-OSDCloudCatalogHp }
            'Lenovo' { Get-OSDCloudCatalogLenovo }
            'Microsoft' {
                Import-Clixml -Path (Join-Path -Path (Get-OSDCloudModulePath) -ChildPath 'catalogs\driverpack\microsoft.xml')
            }
            default { $DefaultCatalog }
        }
    }
    else {
        $DriverPackValues = $DefaultCatalog
    }

    $DriverPackValues | Where-Object { $_.OSArchitecture -eq $ProcessorArchitecture }
}
function Get-SystemFirmwareUpdate {
    #=================================================
    #	MSCatalog PowerShell Module
    #   Ryan-Jan
    #   https://github.com/ryan-jan/MSCatalog
    #   This excellent work is a good way to gather information from MS
    #   Catalog
    #=================================================
    if ($PSVersionTable.PSVersion.Major -ne 5) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] PowerShell 5.1 is required to run this function"
        return
    }
    if (!(Get-Module -ListAvailable -Name MSCatalog)) {
        Install-Module MSCatalog -Force -SkipPublisherCheck -ErrorAction Ignore
    }
    #=================================================
    #	Make sure the Module was installed
    #=================================================
    if (Get-Module -ListAvailable -Name MSCatalog) {
        if (Test-MicrosoftUpdateCatalog) {
            Try {
                Get-MicrosoftUpdateCatalogResult -Search (Get-SystemFirmwareResource) -SortBy LastUpdated -Descending | Select-Object LastUpdated,Title,Version,Size,Guid -First 1
            }
            Catch {
                #Do nothing
            }
        }
        else {
            Write-Host -ForegroundColor DarkGray "Get-SystemFirmwareUpdate: Could not reach https://www.catalog.update.microsoft.com/"
        }
    }
    else {
        Write-Host -ForegroundColor DarkGray "Get-SystemFirmwareUpdate: Could not install required PowerShell Module MSCatalog"
    }
    #=================================================
}
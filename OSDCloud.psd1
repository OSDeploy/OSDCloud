@{
    Author               = 'David Segura, Gary Blok, Michael Escamilla'
    CompanyName          = 'osdeploy.com'
    CompatiblePSEditions = @('Desktop')
    Copyright            = '(c) 2025 @ osdeploy.com. All rights reserved.'
    Description          = 'The OSDCloud Engine'
    GUID                 = '2fbd5c65-79c7-4561-9a2e-c4a4eebc89c7'
    ModuleVersion        = '25.3.27.1'
    PowerShellVersion    = '5.1'
    RootModule           = 'OSDCloud.psm1'
    FunctionsToExport    = @(
        'Get-OSDCloud'
    )
    PrivateData          = @{
        PSData = @{
            ProjectUri = 'https://github.com/OSDeploy/OSDCloud'
            LicenseUri = 'https://github.com/OSDeploy/OSDCloud/blob/main/LICENSE'
            Tags       = @('OSDeploy', 'OSD', 'OSDWorkspace', 'OSDCloud')
        }
    }
}
OSDCloud
========

OSDCloud is a PowerShell module for deploying Windows with cloud-hosted operating system and driver content.

Overview
--------
- Focused on Windows deployment workflows driven by PowerShell.
- Supports WinPE startup helpers and deployment UX options.
- Provides cmdlets for device info, Wi-Fi setup, and module updates in PE.

Requirements
------------
- Windows PowerShell 5.1
- Windows or WinPE environment (for PE-specific cmdlets)

Install (in Winpe)
-------
```powershell
Install-Module -Name OSDCloud -SkipPublisherCheck -Force
```

Quick start
-----------
```powershell
Import-Module OSDCloud
Get-Command -Module OSDCloud

# Launch the interactive deployment experience
Deploy-OSDCloud
```

Commands
--------
- `Deploy-OSDCloud`
- `Get-OSDCloudInfo`
- `Get-OSDCloudModulePath`
- `Get-OSDCloudModuleVersion`

Documentation
-------------
- Project docs: https://github.com/OSDeploy/OSDCloud/tree/main/docs
- Module page: https://www.powershellgallery.com/packages/OSDCloud
- Issues: https://github.com/OSDeploy/OSDCloud/issues

Local docs in this repo:
- [docs/Deploy-OSDCloud.md](docs/Deploy-OSDCloud.md)
- [docs/Deploy-OSDCloudCLI.md](docs/Deploy-OSDCloudCLI.md)
- [docs/Deploy-OSDCloudGUI.md](docs/Deploy-OSDCloudGUI.md)
- [docs/Export-WinpeDriversFromOS.md](docs/Export-WinpeDriversFromOS.md)
- [docs/Get-OSDCloudInfo.md](docs/Get-OSDCloudInfo.md)
- [docs/Get-OSDCloudModulePath.md](docs/Get-OSDCloudModulePath.md)
- [docs/Get-OSDCloudModuleVersion.md](docs/Get-OSDCloudModuleVersion.md)

Privacy policy
--------------
OSDCloud sends deployment analytics during workflow deployment tasks. See [PRIVACY.md](PRIVACY.md) for details on what data is collected and how to opt out.

License
-------
See [LICENSE](LICENSE).

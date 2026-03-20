# OSDCloud

[![PSGallery Version](https://img.shields.io/powershellgallery/v/OSDCloud.svg?style=flat&logo=powershell&label=PSGallery%20Version)](https://www.powershellgallery.com/packages/OSDCloud) [![PSGallery Downloads](https://img.shields.io/powershellgallery/dt/OSDCloud.svg?style=flat&logo=powershell&label=PSGallery%20Downloads)](https://www.powershellgallery.com/packages/OSDCloud) [![PowerShell](https://img.shields.io/badge/PowerShell-5.1-blue?style=flat&logo=powershell)](https://www.powershellgallery.com/packages/OSDCloud)

OSDCloud is a PowerShell module for deploying Windows with cloud-hosted operating system and driver content.

## Overview

- Focused on Windows deployment workflows driven by PowerShell.
- Supports WinPE startup helpers and deployment UX options.
- Provides cmdlets for device info, Wi-Fi setup, and module updates in PE.

## Requirements

- Windows PowerShell 5.1
- Windows or WinPE environment (for PE-specific cmdlets)

## Install (in WinPE)

```powershell
Install-Module -Name OSDCloud -SkipPublisherCheck -Force
```

## Quick start

```powershell
Import-Module OSDCloud
Get-Command -Module OSDCloud

# Launch the interactive deployment experience
Deploy-OSDCloud
```

## Commands

General commands

- `Deploy-OSDCloud`
- `Get-OSDCloudInfo`
- `Get-OSDCloudModulePath`
- `Get-OSDCloudModuleVersion`

WinPE-only commands

- `Invoke-OSDCloudPEStartup`
- `Invoke-OSDCloudWifi`
- `Show-PEStartupDeviceInfo`
- `Show-PEStartupHardware`
- `Show-PEStartupHardwareErrors`
- `Show-PEStartupIpconfig`
- `Show-PEStartupWifi`
- `Use-PEStartupUpdateModule`

## Documentation

- Project docs: [OSDCloud docs](https://github.com/OSDeploy/OSDCloud/tree/main/docs)
- Module page: [PowerShell Gallery - OSDCloud](https://www.powershellgallery.com/packages/OSDCloud)
- Issues: [GitHub issues](https://github.com/OSDeploy/OSDCloud/issues)

Local docs in this repo:

- [docs/Deploy-OSDCloud.md](docs/Deploy-OSDCloud.md)
- [docs/Get-OSDCloudInfo.md](docs/Get-OSDCloudInfo.md)
- [docs/Get-OSDCloudModulePath.md](docs/Get-OSDCloudModulePath.md)
- [docs/Get-OSDCloudModuleVersion.md](docs/Get-OSDCloudModuleVersion.md)

## Release notes

- See [CHANGELOG.md](CHANGELOG.md) for module release history.
- Current release includes Windows 11 25H2 build 26200.8037 catalog updates.

## Privacy policy

OSDCloud sends deployment analytics during workflow deployment tasks. See [PRIVACY.md](PRIVACY.md) for details on what data is collected and how to opt out.

## License

See [LICENSE](LICENSE).

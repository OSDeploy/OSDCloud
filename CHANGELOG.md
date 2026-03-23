# Changelog

All notable changes to this project will be documented in this file.

## 26.3.23.1 - March 23, 2026

### Added

- Dev-device workflow with full WPF application structure and UI (#53)
- Enhanced clipboard functionality in MainWindow UI (#53)

### Changed

- Updated Microsoft driver pack catalog (#53)
- Changed verbose logging to host output for time synchronization (#50)
- Refactored MainWindow code across default, dev-alpha, dev-beta, and insiders workflows (#53)

## 26.3.12.1 - March 12, 2026

### Added

- Updated OSDCloud OS catalog with Windows 11 25H2 build 26200.8037.

## 26.3.4.1 - March 4, 2026

### Added

- Panasonic driver pack catalog support (#45)
- `Sync-InternetDateTime` function for time synchronization (#45)
- `step-Add-WindowsDriver-Disk` and `step-Export-WindowsDriver-OemWinPE` driver steps (#45)

### Changed

- Enhanced download process with validation and error handling (#46)
- Updated log copying mechanism for improved efficiency (#47)
- Renamed driver export steps to follow consistent `step-Add-WindowsDriver-*` and `step-Save-WindowsDriver-*` naming convention (#45)
- Enhanced logging across multiple workflow steps (#45)
- Updated HP, Lenovo, and default driver pack catalogs (#44)
- Reorganized WiFi and network connection modules (#44)
- Improved PE startup functions and UI handling in MainWindow (#44)

### Removed

- Deprecated `step-drivers-recast-winos.ps1` and `step-drivers-recast-winpe.ps1` (#45)
- Removed `Invoke-PEStartupOSK.ps1` (#44)

## 26.2.16.1 - February 16, 2026

### Added

- Windows 11 25H2 February 2026 OS catalog release (#39)
- OSDCloud by Recast branding (#37)
- `OSDCloud-DownloadFile` function for centralized download handling (#33)
- Curl availability check for downloads (#34)

### Changed

- Updated OSDCloud workflows and task names (#35, #34)
- Improved UI with adjusted column widths in MainWindow layout (#31)
- Updated driver pack management for Windows 11 (#43)
- Updated OS configurations (#38)

### Removed

- Deprecated tasks and unused workflow code (#38, #35)
- Redundant code changes sections (#30)

# OSDCloud – GitHub Copilot Instructions

OSDCloud is a PowerShell 5.1 module for deploying Windows from cloud-hosted OS and driver content.  
It runs in both WinPE environments.

## Key references

- [README.md](../README.md) – overview and quick-start commands
- [CONTRIBUTING.md](../CONTRIBUTING.md) – contribution workflow
- [.github/instructions/powershell.instructions.md](instructions/powershell.instructions.md) – PowerShell conventions (applied to `**/*.ps1,**/*.psm1`)
- [.github/instructions/powershell-pester-5.instructions.md](instructions/powershell-pester-5.instructions.md) – Pester v5 test conventions (applied to `**/*.Tests.ps1`)
- [.github/instructions/commit-messages.instructions.md](instructions/commit-messages.instructions.md) – commit message format

## Architecture

```
public/          # Exported cmdlets loaded in all environments
public-winpe/    # Exported cmdlets loaded ONLY when SystemDrive == X: (WinPE)
private/         # Orchestration helpers – not exported
  datetime/      # Time sync
  dev/           # Disk/partition utilities (dev use)
  driverpack/    # Driver pack catalog readers
  main/          # Core module init (Initialize-OSDCloudModule)
  microsoft-update-catalog/  # MUC lookup
  net/           # Network helpers
  pe-startup/    # WinPE boot sequence
  steps/         # Workflow step implementations
classes/         # PowerShell class definitions (dot-sourced before functions)
catalogs/        # Driver pack XMLs and OS version JSON/XML catalogs
workflow/        # Deployment profiles (classic, default, latest, insiders, …)
  <name>/
    tasks/       # JSON task definitions executed by Invoke-OSDCloudWorkflowTask
    ux/          # UI configuration JSON
    os-amd64.json / os-arm64.json
types/           # Pre-compiled DLLs (HtmlAgilityPack – loaded by OSDCloud.psm1)
core/            # Out-of-band provisioning package assets
```

### Module load order (OSDCloud.psm1)

1. Dot-source `classes/*.ps1` (types must exist before functions)
2. Add `HtmlAgilityPack.dll` (Net45 or netstandard2.0 based on PSEdition)
3. Dot-source `private/**/*.ps1`; dot-source `public/**/*.ps1`; if WinPE, also `public-winpe/**/*.ps1`
4. `Export-ModuleMember -Function '*' -Alias '*' -Cmdlet '*'`
5. Call `Initialize-OSDCloudModule` (sets global metadata)

## Coding conventions

### Every function must

- Use `[CmdletBinding()]` – no exceptions
- Include comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`, `.NOTES`)
- Use full cmdlet names – no aliases in scripts (e.g. `Get-ChildItem`, not `gci`)
- Log with the standard verbose pattern:
  ```powershell
  Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] <message>"
  ```
- Clear the error collection at the start: `$Error.Clear()`

### Do NOT use begin/process/end blocks

Functions are procedural and single-call, not pipeline-aware. Skip the blocks unless a function is genuinely pipeline-oriented.

### Global state

`Initialize-*` functions populate `$global:OSDCloud*` variables; `Invoke-*` and `Get-*` functions read them.  
Key globals: `$global:OSDCloudDevice`, `$global:OSDCloudDeploy`, `$global:OSDCloudWorkflowTasks`, `$global:OSDCloudWorkflowInvoke`, `$global:Architecture`, `$global:IsWinPE`, `$global:IsVM`, `$global:IsOnBattery`.  
Document any new global variables added.

### Naming

| Item | Convention |
|---|---|
| Functions | `Verb-Noun` PascalCase, approved verb (run `Get-Verb`) |
| Parameters | PascalCase |
| Public variables | PascalCase |
| Local/private variables | camelCase |

### WinPE-specific code

- Guard WinPE-only logic with `$env:SystemDrive -eq 'X:'` or the `$global:IsWinPE` flag
- Place WinPE-only exported functions in `public-winpe/`

## Workflows

Deployment channels live in `workflow/<name>/`. Each channel provides JSON task definitions and OS/architecture configs.  
To add a deployment step, add a JSON entry in `workflow/<channel>/tasks/` and implement the step in `private/steps/`.  
Do not hard-code deployment logic in orchestration functions.

## Catalogs

Driver packs: `catalogs/driverpack/` (XML/JSON, mirrored from OEM sources listed in `module.json`).  
OS metadata: `catalogs/operatingsystem/` (named `<build>-<windows-version>.xml`).  
Update catalog files when new OS builds or driver pack versions are released; do not edit them manually for content that should be fetched upstream.

## Testing

No tests exist yet. When adding tests, follow [powershell-pester-5.instructions.md](instructions/powershell-pester-5.instructions.md).  
Place test files adjacent to the function being tested as `<FunctionName>.Tests.ps1`.  
Mock all external dependencies (WMI, network calls, disk operations).

## Build and publish

```powershell
# No local build step required – dot-source or Import-Module directly.
# Publish to PSGallery (requires API key):
Publish-Module -Name OSDCloud -NuGetApiKey $env:PSGALLERY_KEY
```

Publishing is triggered manually via `.github/workflows/publish-module.yaml`.  
Version follows `YY.M.D.revision` format – update `ModuleVersion` in `OSDCloud.psd1` before publishing.

## Common pitfalls

- `public-winpe/` functions are **not loaded outside WinPE** – do not call them in normal-environment code.
- The module requires `curl.exe` to be present for download operations – validated in `Initialize-OSDCloudDeploy`.
- `HtmlAgilityPack.dll` type is loaded once; re-importing silently skips the Add-Type call but may conflict if another version is loaded first.
- Analytics events (PostHog) are sent during workflow execution – see [PRIVACY.md](../PRIVACY.md) for opt-out details.
- Commit scopes: `workflow`, `driver-packs`, `pe-startup`, `deployment`, `classes`, `catalog`, `core`, `wi-fi`, `main`.

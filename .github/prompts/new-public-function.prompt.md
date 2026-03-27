---
description: "Scaffold a new exported OSDCloud cmdlet with all required boilerplate: CmdletBinding, comment-based help, Error.Clear, module metadata variables, and verbose start/end markers. Saves the file to public/ or public-winpe/."
argument-hint: "Verb-Noun [parameters description] [WinPE-only?]"
agent: "agent"
---

Generate a new public OSDCloud cmdlet following the project conventions in [copilot-instructions.md](../copilot-instructions.md) and [powershell.instructions.md](../instructions/powershell.instructions.md).

## Inputs

If the user provided arguments, extract:
- **Function name** (`Verb-Noun` — must use an approved PowerShell verb; verify with `Get-Verb`)
- **Parameters** (names, types, defaults, mandatory/optional)
- **Purpose** (one sentence for `.SYNOPSIS`)
- **WinPE-only** — `true` → place in `public-winpe/`; `false` (default) → place in `public/`

If any of these are missing or ambiguous, ask before generating.

## Output

Create the file `public/<FunctionName>.ps1` (or `public-winpe/<FunctionName>.ps1` for WinPE-only).

The file must contain exactly one function using this structure:

```powershell
function <Verb-Noun> {
    <#
    .SYNOPSIS
        <One-sentence summary.>

    .DESCRIPTION
        <Extended description. Expand on SYNOPSIS. Mention global variables read or set if applicable.>

    .PARAMETER <ParameterName>
        <Description of the parameter.>

    .EXAMPLE
        <Verb-Noun> <example args>

        <What the example does.>

    .NOTES
        Author: <leave blank — do not invent a name>
    #>
    [CmdletBinding()]
    param (
        <# Parameters here — PascalCase names, full .NET types, no aliases in scripts #>
    )
    #=================================================
    $Error.Clear()
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    $ModuleName    = $($MyInvocation.MyCommand.Module.Name)
    $ModuleBase    = $($MyInvocation.MyCommand.Module.ModuleBase)
    $ModuleVersion = $($MyInvocation.MyCommand.Module.Version)
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] ModuleName: $ModuleName"
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] ModuleBase: $ModuleBase"
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] ModuleVersion: $ModuleVersion"
    #=================================================

    <# Implementation here #>

    #=================================================
    Write-Verbose "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    #=================================================
}
```

## Rules

- **No `begin`/`process`/`end` blocks** unless the function is explicitly pipeline-oriented.
- Use **full cmdlet names** — never aliases (`Get-ChildItem`, not `gci`).
- Use **camelCase** for local variables, **PascalCase** for parameters.
- Do **not** include `Export-ModuleMember` — the module root handles that.
- If the function reads global state (`$global:OSDCloudDeploy`, `$global:OSDCloudDevice`, etc.), document that in `.DESCRIPTION`.
- If WinPE-only, add a guard comment inside the function body:  
  `# This function is only called in WinPE (SystemDrive == X:)`
- Remove the three module metadata lines (`$ModuleName`, `$ModuleBase`, `$ModuleVersion` and their `Write-Verbose` calls) only if they are genuinely unused in the implementation.

## After creating the file

Report:
1. The full file path created.
2. Any approved-verb check issues (flag if the verb is not in `Get-Verb` output).
3. Whether a docs entry in `docs/<FunctionName>.md` should be created (prompt the user — do not create it automatically).

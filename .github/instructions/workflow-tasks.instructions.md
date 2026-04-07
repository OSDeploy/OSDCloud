---
description: "Use when authoring or editing workflow task JSON files in workflow/<channel>/tasks/, adding new deployment steps to private/steps/, or updating os-amd64.json / os-arm64.json OS configs. Covers JSON schema, step naming, flag semantics, step function structure, and the step-phase directory layout."
---

# Workflow Task Authoring Guidelines

Deployment workflows live in `workflow/<channel>/tasks/*.json`. Each JSON file defines a named task (a list of ordered steps). Steps are executed sequentially by `Invoke-OSDCloudWorkflowTask`.

## Task file schema

```json
{
    "id": "<UUID v4>",
    "name": "<human-readable task name>",
    "description": "<human-readable description>",
    "author": "osdcloud@recastsoftware.com",
    "version": "<YY.M.D>",
    "amd64": true,
    "arm64": true,
    "default": false,
    "steps": [ ... ]
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `id` | string (UUID v4) | yes | Unique across all task files; generate a new GUID for every new task file |
| `name` | string | yes | Shown in the UX selector |
| `description` | string | yes | May match `name`; shown in tooltips |
| `author` | string | yes | Use `osdcloud@recastsoftware.com` |
| `version` | string | yes | Match the module version format `YY.M.D` |
| `amd64` | boolean | yes | `true` if this task runs on x64 |
| `arm64` | boolean | yes | `true` if this task runs on ARM64 |
| `default` | boolean | yes | Only **one** task per channel may set `"default": true` |

## Step object schema

```json
{
    "name": "Human-Readable Step Description",
    "command": "step-phase-action",
    "parameters": { "Key": "Value" },
    "skip": false,
    "debug": false,
    "verbose": false,
    "pause": false,
    "testinfullos": false
}
```

| Field | Type | Required | Default | Notes |
|---|---|---|---|---|
| `name` | string | yes | — | Short, imperative phrase shown in progress output |
| `command` | string | yes | — | Must match an exported function name in `private/steps/` |
| `parameters` | object | no | `{}` | Passed as splatted arguments to the step function |
| `skip` | boolean | no | `false` | Set `true` to disable a step without removing it |
| `debug` | boolean | no | `false` | Adds `-Debug` when invoking the step |
| `verbose` | boolean | no | `false` | Adds `-Verbose` when invoking the step; only set when diagnosing |
| `pause` | boolean | no | `false` | Pauses execution after the step completes |
| `testinfullos` | boolean | no | `false` | Allows the step to run in a non-WinPE (full OS) environment for testing |

### Skip vs. omit

- **`"skip": true`** — keeps the step visible in the task list but marks it as disabled. Prefer this for steps that may be re-enabled per deployment (e.g., optional driver downloads).
- **Omit the step entirely** — removes it from the pipeline. Only do this if the step is architecturally inappropriate for the channel (e.g., firmware steps in a firmware-free task).

## Step naming convention

Step function names follow the pattern: `step-<phase>-<action>` (all lowercase, hyphen-separated).

| Phase prefix | Directory | Examples |
|---|---|---|
| `step-initialize-*` | `private/steps/1-initialize/` | `step-initialize-osdcloudworkflowtask` |
| `step-test-*` | `private/steps/2-test/` | `step-test-targetdisk` |
| `step-preinstall-*` | `private/steps/3-preinstall/` | `step-preinstall-cleartargetdisk` |
| `step-install-*` | `private/steps/4-install/` | `step-install-downloadwindowsimage` |
| `step-*-WindowsDriver-*` | `private/steps/5-drivers/` | `step-Save-WindowsDriver-Firmware` |
| `step-powershell-*` | `private/steps/6-powershell/` | `step-powershell-savemodule` |
| `step-update-*` | `private/steps/7-update/` | `step-update-setupdisplayedeula` |
| `step-finalize-*` | `private/steps/8-finalize/` | `step-finalize-stoposdcloudworkflow` |
| `step-postaction-*` | `private/steps/9-postaction/` | `step-postaction-restartcomputer` |

## Required first and last steps

Every task **must** start and end with these bookend steps:

```json
{
    "name": "Initialize OSDCloud Workflow",
    "command": "step-initialize-osdcloudworkflowtask",
    "parameters": { "WorkflowTaskName": "<task name here>" },
    "pause": false,
    "skip": false,
    "debug": false,
    "verbose": false,
    "testinfullos": true
},
...
{
    "name": "Stop Logs",
    "command": "step-finalize-osdcloudlogs",
    "testinfullos": true
},
{
    "name": "Stop Workflow",
    "command": "step-finalize-stoposdcloudworkflow",
    "testinfullos": true
}
```

The `WorkflowTaskName` parameter value must match the `name` field at the root of the task file.

## Adding a new step to an existing task

1. Add the JSON step object at the correct position in the `steps` array (respect phase order).
2. Implement the step function in `private/steps/<N>-<phase>/step-<phase>-<action>.ps1`.
3. Follow the step function template (see below).

## Step function template

Place the file in the matching phase subfolder. Use the function name as the filename.

```powershell
function step-phase-action {
    [CmdletBinding()]
    param (
        # Add parameters that match the "parameters" object in the JSON step
    )
    #=================================================
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    $Step = $global:OSDCloudCurrentStep
    #=================================================
    #region Main

    # Implementation here.
    # Read context from $global:OSDCloudWorkflowInvoke (architecture, paths, OS object, etc.)
    # Read deployment config from $global:OSDCloudDeploy
    # Read device info from $global:OSDCloudDevice

    #endregion
    #=================================================
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
```

- Do **not** add comment-based help to step functions (they are internal, not exported cmdlets).
- Do **not** break execution with `throw` for non-fatal conditions; use `Write-Warning` and continue.
- Read `$global:OSDCloudCurrentStep` at the top — it is set by `Invoke-OSDCloudWorkflowTask` before each step call.
- Steps that are destructive (disk clear, reformat) should validate preconditions before proceeding.

## OS configuration files (os-amd64.json / os-arm64.json)

Each channel provides OS picker configuration per architecture.

```json
{
  "OperatingSystem": {
    "default": "Windows 11 25H2",
    "values": ["Windows 11 25H2", "Windows 11 24H2", "Windows 11 23H2"]
  },
  "OSActivation": {
    "default": "Retail",
    "values": ["Retail", "Volume"]
  },
  "OSEdition": {
    "default": "Pro",
    "values": [
      { "Edition": "Pro", "EditionId": "Professional" },
      ...
    ]
  }
}
```

- When adding a new Windows build to the catalog, add it to `values` and update `default` in all channels that should offer it.
- Update `catalogs/operatingsystem/` with the corresponding `<build>-<windows-version>.xml` file.
- Do not edit `OSEdition.values` entries unless the edition list for the build changes.

## Channel conventions

| Channel | Purpose | `default` task |
|---|---|---|
| `default` | Stable production deployments | `osdcloud.json` |
| `classic` | Legacy/proven workflow | check channel |
| `latest` | Cutting-edge features, may change | check channel |
| `insiders` | Pre-release testing only | check channel |
| `dev-alpha` / `dev-beta` | Active development; not for production | varies |
| `dev-device` | Per-device testing scenarios | varies |
| `legacy` | Archived; do not modify | — |

Do not add new steps to the `legacy` channel.

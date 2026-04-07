---
description: "Use when adding a new Windows OS build to catalogs/operatingsystem/, updating driver pack snapshots in catalogs/driverpack/, adding a new Surface model to microsoft.json, or adding a new Panasonic model to panasonic.json. Covers file naming, XML/JSON schemas, the build-number switch statement, microsoft.xml regeneration, and required workflow config changes."
---

# Catalog Update Guidelines

All catalog files live in `catalogs/`. They are committed snapshots used as offline fallbacks or as the primary data source. Do not edit them for content that is fetched dynamically at runtime from OEM sources.

---

## OS catalogs (`catalogs/operatingsystem/`)

### File naming

```
<build>.<revision>-<windows-name>-<version>.xml
```

Examples:
- `26200.8037-win11-25h2.xml`
- `26100.4349-win11-24h2.xml`
- `19045.3803-win10-22h2.xml`

The filename encodes the full servicing build (`build.revision`) and maps to the OS name and version. The first five digits (`build`) are extracted programmatically to identify the OS; the full `build.revision` becomes `OSBuildVersion`.

### XML structure

OS catalog files are MCT XML exported from the Microsoft Media Creation Tool. The root path to ESD entries is:

```
/MCT/Catalogs/Catalog/PublishedMedia/Files/File
```

Each `<File>` element contains:

| Element | Description |
|---|---|
| `FileName` | ESD filename — must start with `<build>.<revision>.` |
| `LanguageCode` | BCP-47 code, e.g. `en-us`, `fr-fr` |
| `Language` | Human-readable language name |
| `Edition` | PowerShell edition ID, e.g. `Professional`, `Education`, `Core` |
| `Architecture` | `x64` or `arm64` |
| `Size` | File size in bytes |
| `Sha256` | SHA-256 hash (preferred; newer builds) |
| `Sha1` | SHA-1 hash (older builds only) |
| `FilePath` | Full download URL (`http://dl.delivery.mp.microsoft.com/...`) |
| `Key` | Empty — leave as `<Key />` |
| `Architecture_Loc` | `%ARCH_64%` or `%ARCH_ARM64%` |
| `Edition_Loc` | `%CLIENT%`, `%BASE_CHINA%`, etc. |
| `IsRetailOnly` | `True` or `False` |

### Adding a new OS build — checklist

1. **Add the XML file** to `catalogs/operatingsystem/` following the naming convention above.

2. **Register the build number** in `private/Get-DeployOSDCloudOperatingSystems.ps1`.  
   Locate the `switch ($OSBuild)` block and add a new case:

   ```powershell
   switch ($OSBuild) {
       '19045' { $OperatingSystem = 'Windows 10 22H2'; $OSName = 'Windows 10'; $OSVersion = '22H2' }
       '22621' { $OperatingSystem = 'Windows 11 22H2'; $OSName = 'Windows 11'; $OSVersion = '22H2' }
       '22631' { $OperatingSystem = 'Windows 11 23H2'; $OSName = 'Windows 11'; $OSVersion = '23H2' }
       '26100' { $OperatingSystem = 'Windows 11 24H2'; $OSName = 'Windows 11'; $OSVersion = '24H2' }
       '26200' { $OperatingSystem = 'Windows 11 25H2'; $OSName = 'Windows 11'; $OSVersion = '25H2' }
       '28000' { $OperatingSystem = 'Windows 11 26H1'; $OSName = 'Windows 11'; $OSVersion = '26H1' }
       # add new build here:
       '<build>' { $OperatingSystem = 'Windows 11 <Ver>'; $OSName = 'Windows 11'; $OSVersion = '<Ver>' }
       default { continue }
   }
   ```

   Without this entry, the build's ESD entries are silently skipped.

3. **Update workflow OS configs** — for every channel that should offer the new build, add the version string to `os-amd64.json` and `os-arm64.json`:

   ```json
   {
     "OperatingSystem": {
       "default": "Windows 11 <Ver>",
       "values": ["Windows 11 <Ver>", "Windows 11 25H2", "Windows 11 24H2"]
     }
   }
   ```

   - Update `default` only if this should become the default selection.
   - Do not add a version string to channels that do not support that build.

4. **Update CHANGELOG.md** with the new build version.

---

## Driver pack catalogs (`catalogs/driverpack/`)

### Overview of catalog files

| File | Format | Manufacturer | Updated by |
|---|---|---|---|
| `dell.xml` | OEM XML snapshot | Dell | Download + replace |
| `hp.xml` | OEM XML snapshot | HP | Download + replace |
| `lenovo.xml` | OEM XML snapshot | Lenovo | Download + replace |
| `microsoft.json` | JSON array | Microsoft (Surface) | Manual edit |
| `microsoft.xml` | PowerShell CliXML | Microsoft (Surface) | Regenerate from JSON |
| `panasonic.json` | Nested JSON | Panasonic | Manual edit |
| `default.json` | JSON array | ARM64 / multi-OEM | Manual edit |

OEM source URLs are defined in `module.json` under each manufacturer key (`driverpackcatalogoem`).  
Dell, HP, and Lenovo catalogs are fetched at runtime by their respective `Get-OSDCloudCatalog*` functions; local files are fallback only.

---

### Updating Dell, HP, or Lenovo snapshots

At runtime, `Get-OSDCloudCatalogDell/Hp/Lenovo` downloads the OEM CAB/XML to `$env:TEMP`, parses it, and falls back to the local snapshot on failure. To refresh the committed snapshot:

1. Download the OEM catalog CAB from the URL in `module.json`:
   - Dell: `https://downloads.dell.com/catalog/DriverPackCatalog.cab`
   - HP: `https://hpia.hpcloud.hp.com/downloads/driverpackcatalog/HPClientDriverPackCatalog.cab`
   - Lenovo: `https://download.lenovo.com/cdrt/td/catalogv2.xml`

2. For Dell and HP: extract the XML from the CAB using `expand.exe`:
   ```powershell
   & expand.exe DriverPackCatalog.cab DriverPackCatalog.xml
   ```

3. Replace the local file:
   - `catalogs/driverpack/dell.xml`
   - `catalogs/driverpack/hp.xml`
   - `catalogs/driverpack/lenovo.xml`

4. Do not edit the OEM XML content manually — it is consumed as-is by the catalog parser.

---

### microsoft.json (Surface driver packs — amd64)

Used for `Manufacturer == 'Microsoft'` on AMD64 devices.  
Read via `Import-Clixml` from `microsoft.xml`; **edit the JSON source, then regenerate the CliXML**.

#### JSON object schema

```json
{
  "CatalogVersion": "YY.MM.DD",
  "ReleaseDate": "YY.MM.DD",
  "Name": "Surface <Model> [<ReleaseDate>]",
  "Manufacturer": "Microsoft",
  "Model": "Surface <Model>",
  "SystemId": "Surface_<ModelId>",
  "FileName": "<filename>.msi",
  "Url": "https://download.microsoft.com/download/.../filename.msi",
  "OperatingSystem": "Windows 11",
  "OSArchitecture": "amd64",
  "HashMD5": "<hash or null>",
  "UpdatePage": "<URL or null>"
}
```

- `CatalogVersion` — use today's date in `YY.MM.DD` format for all entries being updated.
- `Name` — format must be `"<Manufacturer> <Model> [<ReleaseDate>]"`.
- `SystemId` — must match the WMI `Win32_ComputerSystemProduct.Name` for the device.
- `OperatingSystem` — use `"Windows 11"` for current models; only legacy models use `"Windows 10"`.

#### After editing microsoft.json — regenerate microsoft.xml

```powershell
$json = Get-Content 'catalogs\driverpack\microsoft.json' -Raw | ConvertFrom-Json
$json | Export-Clixml 'catalogs\driverpack\microsoft.xml'
```

Both files must be committed together. **Do not edit `microsoft.xml` by hand.**

---

### panasonic.json (Panasonic driver packs)

This file uses a different nested schema compared to other driver pack catalogs. It is read by `Get-OSDCloudCatalogPanasonic`, which flattens the nested structure at runtime and excludes Windows 10 entries.

#### JSON structure

```json
{
  "LastDateModified": "YYYY-MM-DDTHH:MM:SSZ",
  "Manufacturer": "Panasonic",
  "Models": [
    {
      "Alias": "<short model name>",
      "Product": "<WMI product ID>",
      "DriverPacks": [
        {
          "OSVer": "Win11",
          "OSRelease": "25H2",
          "Version": "V2",
          "URL": "https://na.panasonic.com/computer/cab/<filename>.zip",
          "Size": "3.23GB",
          "Hash": "<MD5 hash>",
          "ReleaseDate": "YYYY-MM-DD"
        }
      ]
    }
  ]
}
```

- Update `LastDateModified` at the root whenever any entry is changed.
- `OSVer` must be `"Win11"` — entries with `"Win10"` are filtered out at runtime.
- `Product` must match `Win32_ComputerSystemProduct.Name` for device matching.
- Include one entry per OS release per model; do not deduplicate — the catalog reader deduplicates on `Hash`.

---

### default.json (ARM64 and generic driver packs)

Used for ARM64 deployments (all manufacturers) and AMD64 devices that are not Dell, HP, Lenovo, or Microsoft. Uses the same flat JSON array schema as `microsoft.json`.

Key differences:
- `OSArchitecture` should be `"arm64"` for ARM64-only packs.
- Entries here are the **only** source for ARM64 driver packs — there is no runtime OEM lookup for ARM64.
- `CatalogVersion` — update to today's date (`YY.MM.DD`) for all entries being added or modified in the same update.

---

## Common mistakes

- **Omitting the build switch case** — a new OS XML will load without errors but produce zero OS options in the UX because every `<File>` hits the `default { continue }` branch.
- **Not regenerating `microsoft.xml`** — `Get-DeployOSDCloudDriverPacks` uses `Import-Clixml` on `microsoft.xml` directly; editing only `microsoft.json` has no runtime effect.
- **Editing OEM XML snapshots manually** — Dell/HP/Lenovo XML is replaced wholesale from upstream; manual edits will be lost on the next snapshot refresh.
- **Adding a Windows version string to workflow configs without the catalog XML** — the UX will offer the version but `Get-DeployOSDCloudOperatingSystems` will return no matching ESD entries, causing `Initialize-OSDCloudDeploy` to throw.

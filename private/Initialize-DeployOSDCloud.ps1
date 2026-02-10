function Initialize-DeployOSDCloud {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $Name = 'default'
    )
    $ErrorActionPreference = 'Stop'
    #=================================================
    # Get module details
    $ModuleVersion = $($MyInvocation.MyCommand.Module.Version)
    #=================================================
    # Dependencies
    # Make sure curl.exe is present and throw if not
    if (-not (Get-Command -Name 'curl.exe' -ErrorAction SilentlyContinue)) {
        throw "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSDCloud requires 'curl.exe' which is not available on this system. Please ensure curl.exe is available in the system PATH."
    }
    #=================================================
    # Get-DeploymentDiskObject
    $DeploymentDiskObject = Get-DeploymentDiskObject

    # Make sure Get-DeploymentDiskObject returns a single object
    if (-not $DeploymentDiskObject) {
        throw "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] OSDCloud requires at least one Local Disk, but no compatible Local Disk was found."
    }
    # Warn if multiple disks found and inform which disk will be used
    # Include the Friendly Name of the disk for clarity
    # Include the size in GB for clarity
    if ($DeploymentDiskObject.Count -gt 1) {
        Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Multiple Local Disks were found. OSDCloud will default to DiskNumber: $($DeploymentDiskObject[0].DiskNumber)"
        $DeploymentDiskObject | ForEach-Object {
            Write-Warning "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] DiskNumber: $($_.DiskNumber), FriendlyName: $($_.FriendlyName), Size(GB): $([math]::Round($_.Size / 1GB, 2))"
        }
    }
    # Limit to the first disk found
    $DeploymentDiskObject = $DeploymentDiskObject | Select-Object -First 1
    #=================================================
    # OSDCloudWorkflowDevice
    if (-not ($global:OSDCloudWorkflowDevice)) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Initialize OSDCloud Device $ModuleVersion"
        Initialize-OSDCloudDevice
    }
    #=================================================
    # OSDCloudWorkflowTasks
    # Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Initialize OSDCloud Tasks"
    Initialize-OSDCloudWorkflowTasks -Name $Name
    # Make sure at least one workflow task is defined
    if (-not $global:OSDCloudWorkflowTasks) {
        throw "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Initialize-DeployOSDCloud requires at least one valid workflow task. Please check your OSDCloud Workflow Tasks."
    }
    # Update WorkflowObject and WorkflowTaskName in the Init global variable
    $WorkflowObject = $global:OSDCloudWorkflowTasks | Select-Object -First 1
    $WorkflowTaskName = $WorkflowObject.name
    #=================================================
    # OSDCloudWorkflowSettingsUser
    #TODO : Remove dependency on User Settings for future releases
    # Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Initialize OSDCloud Settings User"
    # Initialize-OSDCloudSettingsUser -Name $Name
    #=================================================
    # OSDCloud Operating Systems
    # Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Get OSDCloud OperatingSystems"

    # Limit to matching Processor Architecture
    $ProcessorArchitecture = $env:PROCESSOR_ARCHITECTURE
    $global:PSOSDCloudOperatingSystems = Get-PSOSDCloudOperatingSystems | Where-Object {$_.OSArchitecture -match "$ProcessorArchitecture"}

    # Need to fail if no OS found for Architecture
    if (-not $global:PSOSDCloudOperatingSystems) {
        throw "No Operating Systems found for Architecture: $ProcessorArchitecture. Please check your OSDCloud OperatingSystems."
    }
    #=================================================
    # OSDCloudWorkflowSettingsOS
    # Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Initialize OSDCloud Workflow Settings OS"
    Initialize-OSDCloudSettingsOS -Name $Name
    #=================================================
    # Set initial Operating System
    <#
        Id              : Windows 11 25H2 amd64 Retail en-gb 26200.7462
        OperatingSystem : Windows 11 25H2
        OSName          : Windows 11
        OSVersion       : 25H2
        OSArchitecture  : amd64
        OSActivation    : Retail
        LanguageCode    : en-gb
        Language        : English (United Kingdom)
        OSBuild         : 26200
        OSBuildVersion  : 26200.7462
        Size            : 5626355066
        Sha1            :
        Sha256          : 566a518dc46ba5ea401381810751a8abcfe7d012b2f81c9709b787358c606926
        FileName        : 26200.7462.251207-0044.25h2_ge_release_svc_refresh_CLIENTCONSUMER_RET_x64FRE_en-gb.esd
        FilePath        : http://dl.delivery.mp.microsoft.com/filestreamingservice/files/79a3f5e0-d04d-4689-a5d4-3ea35f8b189a/26200.7462.251207-0044.25h2_ge_release_svc_refresh_CLIENTCONSUMER_RET_x64FRE_en-gb.esd
    #>
    $OperatingSystem        = $global:OSDCloudWorkflowSettingsOS."OperatingSystem.default"
    $OperatingSystemValues  = [array]$global:OSDCloudWorkflowSettingsOS."OperatingSystem.values"
    $OSActivation           = $global:OSDCloudWorkflowSettingsOS."OSActivation.default"
    $OSActivationValues     = [array]$global:OSDCloudWorkflowSettingsOS."OSActivation.values"
    $OSArchitecture         = $ProcessorArchitecture
    $OSEdition              = $global:OSDCloudWorkflowSettingsOS."OSEdition.default"
    $OSEditionId            = $global:OSDCloudWorkflowSettingsOS."OSEditionId.default"
    $OSEditionValues        = [array]$global:OSDCloudWorkflowSettingsOS."OSEdition.values"
    $OSLanguageCode         = $global:OSDCloudWorkflowSettingsOS."OSLanguageCode.default"
    $OSLanguageCodeValues   = [array]$global:OSDCloudWorkflowSettingsOS."OSLanguageCode.values"
    $OSVersion              = ($global:OSDCloudWorkflowSettingsOS."OperatingSystem.default" -split ' ')[2]
    #=================================================
    # OperatingSystemObject
    $OperatingSystemObject = $global:PSOSDCloudOperatingSystems | Where-Object { $_.OperatingSystem -match $OperatingSystem } | Where-Object { $_.OSActivation -eq $OSActivation } | Where-Object { $_.OSLanguageCode -eq $OSLanguageCode }
    if (-not $OperatingSystemObject) {
        throw "No Operating System found for OperatingSystem: $OperatingSystem, OSActivation: $OSActivation, OSLanguageCode: $OSLanguageCode. Please check your OSDCloud OperatingSystems."
    }
    $OSName             = $OperatingSystemObject.OSName
    $OSBuild            = $OperatingSystemObject.OSBuild
    $OSBuildVersion     = $OperatingSystemObject.OSBuildVersion
    $ImageFileName      = $OperatingSystemObject.FileName
    $ImageFileUrl       = $OperatingSystemObject.FilePath
    #=================================================
    # DriverPack
    $ComputerManufacturer  = $global:OSDCloudWorkflowDevice.ComputerManufacturer
    switch ($ComputerManufacturer) {
        'Dell' {
            $DriverPackValues = Get-OSDCatalogDriverPacks | Where-Object { $_.OSArchitecture -match $OSArchitecture -and $_.Manufacturer -eq 'Dell' }
        }
        'HP' {
            $DriverPackValues = Get-OSDCatalogDriverPacks | Where-Object { $_.OSArchitecture -match $OSArchitecture -and $_.Manufacturer -eq 'HP' }
        }
        'Lenovo' {
            $DriverPackValues = Get-OSDCatalogDriverPacks | Where-Object { $_.OSArchitecture -match $OSArchitecture -and $_.Manufacturer -eq 'Lenovo' }
        }
        Default {
            $DriverPackValues = Get-OSDCatalogDriverPacks | Where-Object { $_.OSArchitecture -match $OSArchitecture }
        }
    }

    # Remove Windows 10 DriverPacks
    $DriverPackValues = $DriverPackValues | Where-Object { $_.OS -match 'Windows 11' }

    $ComputerModel = $global:OSDCloudWorkflowDevice.ComputerModel
    if ($ComputerModel -match 'Surface') {
        $DriverPackValues = $DriverPackValues | Where-Object { $_.Manufacturer -eq 'Microsoft' }
    }

    $ComputerProduct = $global:OSDCloudWorkflowDevice.ComputerProduct
    $DriverPackObject = Get-OSDCatalogDriverPack -Product $ComputerProduct -OSVersion $OSName -OSReleaseID $OSVersion
    if ($DriverPackObject) {
        $DriverPackName = $DriverPackObject.Name
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] DriverPackName: $DriverPackName"
    }
    #=================================================
    # Main
    $global:OSDCloudWorkflowInit = $null
    $global:OSDCloudWorkflowInit = [ordered]@{
        ComputerManufacturer  = $ComputerManufacturer
        ComputerModel         = $ComputerModel
        ComputerProduct       = $ComputerProduct
        DriverPackName        = $DriverPackName
        DriverPackValues      = [array]$DriverPackValues
        Flows                 = [array]$global:OSDCloudWorkflowTasks
        Function              = $($MyInvocation.MyCommand.Name)
        ImageFileName         = $ImageFileName
        ImageFileUrl          = $ImageFileUrl
        LaunchMethod          = 'OSDCloudWorkflow'
        Module                = $($MyInvocation.MyCommand.Module.Name)
        DeploymentDiskObject  = $DeploymentDiskObject
        DriverPackObject      = $DriverPackObject
        OperatingSystemObject = $OperatingSystemObject
        OperatingSystem       = $OperatingSystem
        OperatingSystemValues = $OperatingSystemValues
        OSActivation          = $OSActivation
        OSActivationValues    = $OSActivationValues
        OSArchitecture        = $OSArchitecture
        OSBuild               = $OSBuild
        OSBuildVersion        = $OSBuildVersion
        OSEdition             = $OSEdition
        OSEditionId           = $OSEditionId
        OSEditionValues       = $OSEditionValues
        OSLanguageCode        = $OSLanguageCode
        OSLanguageCodeValues  = $OSLanguageCodeValues
        OSVersion             = $OSVersion
        TimeStart             = $null
        WorkflowName          = $Name
        WorkflowTaskName      = $WorkflowTaskName
        WorkflowObject        = $WorkflowObject
    }
    #=================================================
}
function Initialize-OSDCloudWorkflow {
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
    $OSDModuleVersion = $((Get-OSDModuleVersion).ToString())
    #=================================================
    # OSDCloudWorkflowGather
    if (-not ($global:OSDCloudWorkflowGather)) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] Initialize OSDCloud Gather $ModuleVersion"
        Initialize-OSDCloudWorkflowGather
    }
    $Architecture          = $global:OSDCloudWorkflowGather.Architecture
    $ComputerManufacturer  = $global:OSDCloudWorkflowGather.ComputerManufacturer
    $ComputerModel         = $global:OSDCloudWorkflowGather.ComputerModel
    $ComputerProduct       = $global:OSDCloudWorkflowGather.ComputerProduct
    #=================================================
    # OSDCloudWorkflowTasks
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] Initialize OSDCloud Tasks"
    Initialize-OSDCloudWorkflowTasks -Name $Name
    $WorkflowObject        = $global:OSDCloudWorkflowTasks | Select-Object -First 1
    $WorkflowName          = $WorkflowObject.name
    #=================================================
    # OSDCloudWorkflowOSCatalog
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] Initialize OSDCloud OS Catalog"
    $global:OSDCloudWorkflowOSCatalog = Get-PSOSDCloudOperatingSystems
    $global:OSDCloudWorkflowOSCatalog = $global:OSDCloudWorkflowOSCatalog | Where-Object {$_.OSArchitecture -match "$Architecture"}
    #=================================================
    # OSDCloudWorkflowSettingsUser
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] Initialize OSDCloud Settings User"
    Initialize-OSDCloudWorkflowSettingsUser -Name $Name
    #=================================================
    # OSDCloudWorkflowSettingsOS
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] Initialize OSDCloud Settings OS"
    Initialize-OSDCloudWorkflowSettingsOS -Name $Name
    if ($global:OSDCloudWorkflowSettingsOS."OSGroup.default" -match 'Win11') {
        $OperatingSystem = 'Windows 11'
    } elseif ($global:OSDCloudWorkflowSettingsOS."OperatingSystem.default" -match 'Win10') {
        $OperatingSystem = 'Windows 10'
    } else {
        $OperatingSystem = 'Windows 11'
    }
    #=================================================
    # Configuration
    $OSActivation          = $global:OSDCloudWorkflowSettingsOS."OSActivation.default"
    $OSActivationValues    = [array]$global:OSDCloudWorkflowSettingsOS."OSActivation.values"
    $OSArchitecture        = $Architecture
    $OSEdition             = $global:OSDCloudWorkflowSettingsOS."OSEdition.default"
    $OSEditionId           = $global:OSDCloudWorkflowSettingsOS."OSEditionId.default"
    $OSEditionValues       = [array]$global:OSDCloudWorkflowSettingsOS."OSEdition.values"
    $OSLanguage            = $global:OSDCloudWorkflowSettingsOS."OSLanguageCode.default"
    $OSLanguageValues      = [array]$global:OSDCloudWorkflowSettingsOS."OSLanguageCode.values"
    $OSGroup                = $global:OSDCloudWorkflowSettingsOS."OSGroup.default"
    $OSGroupValues          = [array]$global:OSDCloudWorkflowSettingsOS."OSGroup.values"
    $OSVersion             = ($global:OSDCloudWorkflowSettingsOS."OSGroup.default" -split '-')[1]
    #=================================================
    # OperatingSystemObject
    $OperatingSystemObject = $global:OSDCloudWorkflowOSCatalog | Where-Object { $_.OSGroup -match $OSGroup } | Where-Object { $_.OSActivation -eq $OSActivation } | Where-Object { $_.LanguageCode -eq $OSLanguage }

    $OSBuild            = $OperatingSystemObject.OSBuild
    $OSBuildVersion     = $OperatingSystemObject.OSBuildVersion
    $ImageFileUrl       = $OperatingSystemObject.FilePath
    $ImageFileName      = Split-Path $ImageFileUrl -Leaf
    #=================================================
    # DriverPack
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

    if ($ComputerModel -match 'Surface') {
        $DriverPackValues = $DriverPackValues | Where-Object { $_.Manufacturer -eq 'Microsoft' }
    }

    $DriverPackObject = Get-OSDCatalogDriverPack -Product $ComputerProduct -OSVersion $OperatingSystem -OSReleaseID $OSVersion
    if ($DriverPackObject) {
        $DriverPackName = $DriverPackObject.Name
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] DriverPackName: $DriverPackName"

        # Remove the Windows 10 DriverPacks if Windows 11 is selected
        # if ($DriverPackObject.OS -match 'Windows 11') {
            $DriverPackValues = $DriverPackValues | Where-Object { $_.OS -match 'Windows 11' }
        # }
    }
    #=================================================
    # Main
    $global:OSDCloudWorkflowInit = $null
    $global:OSDCloudWorkflowInit = [ordered]@{
        WorkflowName          = $WorkflowName
        WorkflowObject        = $WorkflowObject
        ComputerManufacturer  = $ComputerManufacturer
        ComputerModel         = $ComputerModel
        ComputerProduct       = $ComputerProduct
        DriverPackName        = $DriverPackName
        DriverPackObject      = $DriverPackObject
        DriverPackValues      = [array]$DriverPackValues
        Flows                 = [array]$global:OSDCloudWorkflowTasks
        Function              = $($MyInvocation.MyCommand.Name)
        ImageFileName         = $ImageFileName
        ImageFileUrl          = $ImageFileUrl
        LaunchMethod          = 'OSDCloudWorkflow'
        Module                = $($MyInvocation.MyCommand.Module.Name)
        OperatingSystem       = $OperatingSystem
        OperatingSystemObject = $OperatingSystemObject
        OSActivation          = $OSActivation
        OSActivationValues    = $OSActivationValues
        OSArchitecture        = $OSArchitecture
        OSBuild               = $OSBuild
        OSBuildVersion        = $OSBuildVersion
        OSEdition             = $OSEdition
        OSEditionId           = $OSEditionId
        OSEditionValues       = $OSEditionValues
        OSLanguage            = $OSLanguage
        OSLanguageValues      = $OSLanguageValues
        OSGroup               = $OSGroup
        OSGroupValues         = $OSGroupValues
        OSVersion             = $OSVersion
        TimeStart             = $null
    }
    #=================================================
}
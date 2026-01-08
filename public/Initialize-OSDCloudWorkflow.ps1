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
    # OSDCloudWorkflowSettingsUser
    #TODO : Remove dependency on User Settings for future releases
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] Initialize OSDCloud Settings User"
    Initialize-OSDCloudWorkflowSettingsUser -Name $Name
    #=================================================
    # OSDCloud Operating Systems
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] Get OSDCloud OperatingSystems"

    # Limit to matching Processor Architecture
    $global:PSOSDCloudOperatingSystems = Get-PSOSDCloudOperatingSystems | Where-Object {$_.OSArchitecture -match "$Architecture"}

    # Need to fail if no OS found for Architecture
    if (-not $global:PSOSDCloudOperatingSystems) {
        throw "No Operating Systems found for Architecture: $Architecture. Please check your OSDCloud OperatingSystems."
    }
    #=================================================
    # OSDCloudWorkflowSettingsOS
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] Initialize OSDCloud Workflow Settings OS"
    Initialize-OSDCloudWorkflowSettingsOS -Name $Name
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
    $OSArchitecture         = $Architecture
    $OSEdition              = $global:OSDCloudWorkflowSettingsOS."OSEdition.default"
    $OSEditionId            = $global:OSDCloudWorkflowSettingsOS."OSEditionId.default"
    $OSEditionValues        = [array]$global:OSDCloudWorkflowSettingsOS."OSEdition.values"
    $OSLanguageCode         = $global:OSDCloudWorkflowSettingsOS."OSLanguageCode.default"
    $OSLanguageCodeValues   = [array]$global:OSDCloudWorkflowSettingsOS."OSLanguageCode.values"
    $OSVersion              = ($global:OSDCloudWorkflowSettingsOS."OperatingSystem.default" -split ' ')[2]
    #=================================================
    # ObjectOperatingSystem
    $ObjectOperatingSystem = $global:PSOSDCloudOperatingSystems | Where-Object { $_.OperatingSystem -match $OperatingSystem } | Where-Object { $_.OSActivation -eq $OSActivation } | Where-Object { $_.OSLanguageCode -eq $OSLanguageCode }
    if (-not $ObjectOperatingSystem) {
        throw "No Operating System found for OperatingSystem: $OperatingSystem, OSActivation: $OSActivation, OSLanguageCode: $OSLanguageCode. Please check your OSDCloud OperatingSystems."
    }
    $OSName             = $ObjectOperatingSystem.OSName
    $OSBuild            = $ObjectOperatingSystem.OSBuild
    $OSBuildVersion     = $ObjectOperatingSystem.OSBuildVersion
    $ImageFileName      = $ObjectOperatingSystem.FileName
    $ImageFileUrl       = $ObjectOperatingSystem.FilePath
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

    # Remove Windows 10 DriverPacks
    $DriverPackValues = $DriverPackValues | Where-Object { $_.OS -match 'Windows 11' }

    if ($ComputerModel -match 'Surface') {
        $DriverPackValues = $DriverPackValues | Where-Object { $_.Manufacturer -eq 'Microsoft' }
    }

    $ObjectDriverPack = Get-OSDCatalogDriverPack -Product $ComputerProduct -OSVersion $OSName -OSReleaseID $OSVersion
    if ($ObjectDriverPack) {
        $DriverPackName = $ObjectDriverPack.Name
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)] [$($MyInvocation.MyCommand.Name)] DriverPackName: $DriverPackName"
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
        DriverPackValues      = [array]$DriverPackValues
        Flows                 = [array]$global:OSDCloudWorkflowTasks
        Function              = $($MyInvocation.MyCommand.Name)
        ImageFileName         = $ImageFileName
        ImageFileUrl          = $ImageFileUrl
        LaunchMethod          = 'OSDCloudWorkflow'
        Module                = $($MyInvocation.MyCommand.Module.Name)
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
        ObjectDriverPack      = $ObjectDriverPack
        ObjectOperatingSystem = $ObjectOperatingSystem
    }
    #=================================================
}
function Initialize-OSDCloudWorkflow {
    [CmdletBinding()]
    param ()
    #=================================================
    # Get module details
    $ModuleVersion = $($MyInvocation.MyCommand.Module.Version)
    $OSDModuleVersion = $((Get-OSDModuleVersion).ToString())
    #=================================================
    # OSDCloudWorkflowGather
    if (-not ($global:OSDCloudWorkflowGather)) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Initialize OSDCloud Gather $ModuleVersion"
        Initialize-OSDCloudWorkflowGather
    }
    $Architecture          = $global:OSDCloudWorkflowGather.Architecture
    $ComputerManufacturer  = $global:OSDCloudWorkflowGather.ComputerManufacturer
    $ComputerModel         = $global:OSDCloudWorkflowGather.ComputerModel
    $ComputerProduct       = $global:OSDCloudWorkflowGather.ComputerProduct
    #=================================================
    # OSDCloudWorkflowFlows
    if (-not ($global:OSDCloudWorkflowFlows)) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Initialize OSDCloud Flows $ModuleVersion"
        Initialize-OSDCloudWorkflowFlows
    }
    $WorkflowObject        = $global:OSDCloudWorkflowFlows | Select-Object -First 1
    $WorkflowName          = $WorkflowObject.name
    #=================================================
    # OSDCloudWorkflowOSCatalog
    if (-not ($global:OSDCloudWorkflowOSCatalog)) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Initialize OSDCloud OS Catalog $ModuleVersion"
        $global:OSDCloudWorkflowOSCatalog = Get-OSDCatalogOperatingSystems
        $global:OSDCloudWorkflowOSCatalog = $global:OSDCloudWorkflowOSCatalog | Where-Object {$_.Architecture -match "$Architecture"}
        # $global:OSDCloudWorkflowOSCatalog = $global:OSDCloudWorkflowOSCatalog | Where-Object {$_.OperatingSystem -match "Windows 11"}
    }
    #=================================================
    # OSDCloudWorkflowUserSettings
    if (-not ($global:OSDCloudWorkflowUserSettings)) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Initialize OSDCloud User Settings $ModuleVersion"
        Initialize-OSDCloudWorkflowUserSettings
    }
    #=================================================
    # OSDCloudWorkflowOSSettings
    if (-not ($global:OSDCloudWorkflowOSSettings)) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Initialize OSDCloud OS Settings $ModuleVersion"
        Initialize-OSDCloudWorkflowOSSettings
    }
    if ($global:OSDCloudWorkflowOSSettings."OSName.default" -match 'Win11') {
        $OperatingSystem = 'Windows 11'
    } elseif ($global:OSDCloudWorkflowOSSettings."OperatingSystem.default" -match 'Win10') {
        $OperatingSystem = 'Windows 10'
    } else {
        $OperatingSystem = 'Windows 11'
    }
    $OSActivation          = $global:OSDCloudWorkflowOSSettings."OSActivation.default"
    $OSActivationValues    = [array]$global:OSDCloudWorkflowOSSettings."OSActivation.values"
    $OSArchitecture        = $Architecture
    $OSEdition             = $global:OSDCloudWorkflowOSSettings."OSEdition.default"
    $OSEditionId           = $global:OSDCloudWorkflowOSSettings."OSEditionId.default"
    $OSEditionValues       = [array]$global:OSDCloudWorkflowOSSettings."OSEdition.values"
    $OSLanguage            = $global:OSDCloudWorkflowOSSettings."OSLanguageCode.default"
    $OSLanguageValues      = [array]$global:OSDCloudWorkflowOSSettings."OSLanguageCode.values"
    $OSName                = $global:OSDCloudWorkflowOSSettings."OSName.default"
    $OSNameValues          = [array]$global:OSDCloudWorkflowOSSettings."OSName.values"
    $OSReleaseID           = ($global:OSDCloudWorkflowOSSettings."OSName.default" -split '-')[1]
    $OperatingSystemObject = $global:OSDCloudWorkflowOSCatalog | Where-Object { $_.DisplayName -match $OSName } | Where-Object { $_.License -eq $OSActivation } | Where-Object { $_.LanguageCode -eq $OSLanguage }
    $OSBuild               = $OperatingSystemObject.Build
    $ImageFileUrl          = $OperatingSystemObject.Url
    $ImageFileName         = Split-Path $ImageFileUrl -Leaf
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

    $DriverPackObject = Get-OSDCatalogDriverPack -Product $ComputerProduct -OSVersion $OperatingSystem -OSReleaseID $OSReleaseID
    if ($DriverPackObject) {
        $DriverPackName = $DriverPackObject.Name
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] DriverPackName: $DriverPackName"

        # Remove the Windows 10 DriverPacks if Windows 11 is selected
        if ($DriverPackObject.OS -match 'Windows 11') {
            $DriverPackValues = $DriverPackValues | Where-Object { $_.OS -match 'Windows 11' }
        }
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
        Flows                 = [array]$global:OSDCloudWorkflowFlows
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
        OSEdition             = $OSEdition
        OSEditionId           = $OSEditionId
        OSEditionValues       = $OSEditionValues
        OSLanguage            = $OSLanguage
        OSLanguageValues      = $OSLanguageValues
        OSName                = $OSName
        OSNameValues          = $OSNameValues
        OSReleaseID           = $OSReleaseID
        TimeStart             = $null
    }
    #=================================================
}
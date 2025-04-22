function Initialize-OSDCloudWorkflow {
    [CmdletBinding()]
    param ()
    #=================================================
    # Start the function
    $Error.Clear()
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message
    #=================================================
    # Get module details
    $ModuleName = $($MyInvocation.MyCommand.Module.Name)
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] ModuleName: $ModuleName"
    $ModuleBase = $($MyInvocation.MyCommand.Module.ModuleBase)
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] ModuleBase: $ModuleBase"
    $ModuleVersion = $($MyInvocation.MyCommand.Module.Version)
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] ModuleVersion: $ModuleVersion"

    $OSDModuleVersion = $((Get-OSDModuleVersion).ToString())
    #=================================================
    # Initialize $global:InitializeOSDCloudGather
    Initialize-OSDCloudGather
    $Architecture          = $global:InitializeOSDCloudGather.Architecture
    $ComputerManufacturer  = $global:InitializeOSDCloudGather.ComputerManufacturer
    $ComputerModel         = $global:InitializeOSDCloudGather.ComputerModel
    $ComputerProduct       = $global:InitializeOSDCloudGather.ComputerProduct
    #=================================================
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Initialize OSDCloud Flows $ModuleVersion"
    # Initialize $global:InitializeOSDCloudFlows
    Initialize-OSDCloudFlows
    $WorkflowObject        = $global:InitializeOSDCloudFlows | Select-Object -First 1
    $WorkflowName          = $WorkflowObject.name
    #=================================================
    # Initialize $global:InitializeOSDCloudUserSettings
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Initialize OSDCloud User Settings $ModuleVersion"
    Initialize-OSDCloudUserSettings
    #=================================================
    # Initialize $global:InitializeOSDCloudOSSettings
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Importing Operating Systems Catalog $OSDModuleVersion"
    $global:InitializeOSDCloudOSCatalog = Get-OSDCatalogOperatingSystems
    $global:InitializeOSDCloudOSCatalog = $global:InitializeOSDCloudOSCatalog | Where-Object {$_.Architecture -match "$Architecture"}
    # $global:InitializeOSDCloudOSCatalog | Where-Object {$_.OperatingSystem -match "Windows 11"}
    #=================================================
    # Initialize $global:InitializeOSDCloudOSSettings
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Initialize OSDCloud OS Settings $ModuleVersion"
    Initialize-OSDCloudOSSettings

    if ($global:InitializeOSDCloudOSSettings."OSName.default" -match 'Win11') {
        $OperatingSystem = 'Windows 11'
    } elseif ($global:InitializeOSDCloudOSSettings."OperatingSystem.default" -match 'Win10') {
        $OperatingSystem = 'Windows 10'
    } else {
        $OperatingSystem = 'Windows 11'
    }
    $OSActivation          = $global:InitializeOSDCloudOSSettings."OSActivation.default"
    $OSActivationValues    = [array]$global:InitializeOSDCloudOSSettings."OSActivation.values"
    $OSArchitecture        = $Architecture
    $OSEdition             = $global:InitializeOSDCloudOSSettings."OSEdition.default"
    $OSEditionId           = $global:InitializeOSDCloudOSSettings."OSEditionId.default"
    $OSEditionValues       = [array]$global:InitializeOSDCloudOSSettings."OSEdition.values"
    $OSLanguage            = $global:InitializeOSDCloudOSSettings."OSLanguageCode.default"
    $OSLanguageValues      = [array]$global:InitializeOSDCloudOSSettings."OSLanguageCode.values"
    $OSName                = $global:InitializeOSDCloudOSSettings."OSName.default"
    $OSNameValues          = [array]$global:InitializeOSDCloudOSSettings."OSName.values"
    $OSReleaseID           = ($global:InitializeOSDCloudOSSettings."OSName.default" -split '-')[1]
    $OperatingSystemObject = $global:InitializeOSDCloudOSCatalog | Where-Object { $_.DisplayName -match $OSName } | Where-Object { $_.License -eq $OSActivation } | Where-Object { $_.LanguageCode -eq $OSLanguage }
    $OSBuild               = $OperatingSystemObject.Build
    $ImageFileUrl          = $OperatingSystemObject.Url
    $ImageFileName         = Split-Path $ImageFileUrl -Leaf
    #=================================================
    #   Set DriverPack
    $DriverPackValues = Get-OSDCatalogDriverPacks | Where-Object { $_.OSArchitecture -match $OSArchitecture }
    $DriverPackObject = Get-OSDCatalogDriverPack -Product $ComputerProduct -OSVersion $OperatingSystem -OSReleaseID $OSReleaseID

    if ($DriverPackObject) {
        $DriverPackName = $DriverPackObject.Name
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] DriverPackName: $DriverPackName"
    }
    #=================================================
    # Main
    $global:InitializeOSDCloudWorkflow = $null
    $global:InitializeOSDCloudWorkflow = [ordered]@{
        WorkflowName          = $WorkflowName
        WorkflowObject        = $WorkflowObject
        ComputerManufacturer  = $ComputerManufacturer
        ComputerModel         = $ComputerModel
        ComputerProduct       = $ComputerProduct
        DriverPackName        = $DriverPackName
        DriverPackObject      = $DriverPackObject
        DriverPackValues      = [array]$DriverPackValues
        Flows                 = [array]$global:InitializeOSDCloudFlows
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
    # $global:InitializeOSDCloudWorkflow
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
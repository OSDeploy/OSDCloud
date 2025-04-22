function Start-OSvDTrashxGUICLIDemo {
    [CmdletBinding()]
    param ()
    #=================================================
    $Error.Clear()
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Start"
    $ModuleName = $($MyInvocation.MyCommand.Module.Name)
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] ModuleName: $ModuleName"
    $ModuleBase = $($MyInvocation.MyCommand.Module.ModuleBase)
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] ModuleBase: $ModuleBase"
    $ModuleVersion = $($MyInvocation.MyCommand.Module.Version)
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] ModuleVersion: $ModuleVersion"
    #=================================================
    Initialize-OSDCloudWorkflow
    #=================================================
    #   Get-Culture
    #=================================================
    $DefaultOSLanguage = $global:InitializeOSDCloudOSSettings."OSLanguageCode.default"
    $DefaultOSLanguageValues = [array]$global:InitializeOSDCloudOSSettings."OSLanguageCode.values"
    $DefaultPSCulture = $PSCulture.ToLower()
    if ($DefaultPSCulture -in $DefaultOSLanguageValues) {
        $OSLanguage = $DefaultPSCulture
    }
    else {
        $OSLanguage = $DefaultOSLanguage
    }
    #=================================================
    #   Get-OSDCatalogDriverPacks
    #=================================================
    $Architecture = $global:InitializeOSDCloudGather.Architecture
    $DriverPackValues = Get-OSDCatalogDriverPacks | Where-Object { $_.Manufacturer -eq $global:InitializeOSDCloudGather.ComputerManufacturer }
    # $DriverPackValues = Get-OSDCatalogDriverPacks | Where-Object { $_.Manufacturer -eq $global:InitializeOSDCloudGather.ComputerManufacturer } | Where-Object { $_.OSArchitecture -eq $Architecture }
    #=================================================
    #   Main
    #=================================================
    $global:InitializeOSDCloudWorkflow = $null
    $global:InitializeOSDCloudWorkflow = [ordered]@{
        ComputerManufacturer  = $global:InitializeOSDCloudGather.ComputerManufacturer
        ComputerModel         = $global:InitializeOSDCloudGather.ComputerModel
        ComputerProduct       = $global:InitializeOSDCloudGather.ComputerProduct
        DriverPackObject      = $null
        DriverPackName        = $null
        DriverPackValues      = [array]$DriverPackValues
        Function              = $($MyInvocation.MyCommand.Name)
        LaunchMethod          = 'OSDCloudWorkflow'
        Module                = $($MyInvocation.MyCommand.Module.Name)
        OSActivation          = $global:InitializeOSDCloudOSSettings."OSActivation.default"
        OSActivationValues    = [array]$global:InitializeOSDCloudOSSettings."OSActivation.values"
        OSArchitecture        = $Architecture
        OSEdition             = $global:InitializeOSDCloudOSSettings."OSEdition.default"
        OSEditionId           = $global:InitializeOSDCloudOSSettings."OSEditionId.default"
        OSEditionValues       = [array]$global:InitializeOSDCloudOSSettings."OSEdition.values"
        # OSImageIndex          = $null
        OSLanguage            = $global:InitializeOSDCloudOSSettings."OSLanguageCode.default"
        OSLanguageValues      = [array]$global:InitializeOSDCloudOSSettings."OSLanguageCode.values"
        OSName                = $global:InitializeOSDCloudOSSettings."OSName.default"
        OSNameValues          = [array]$global:InitializeOSDCloudOSSettings."OSName.values"
        OSReleaseIDValues     = [array]$global:InitializeOSDCloudOSSettings."OSReleaseID.values"
        TimeStart             = [datetime](Get-Date)
    }
    #=================================================
    #   Set Driver Pack
    #   New logic added to Get-OSDCatalogDriverPack
    #   This should match the proper OS Version ReleaseID
    #=================================================
    $global:InitializeOSDCloudWorkflow.DriverPackObject = Get-OSDCatalogDriverPack -Product $global:InitializeOSDCloudWorkflow.ComputerProduct -OSVersion $global:InitializeOSDCloudWorkflow.OperatingSystem -OSReleaseID $global:InitializeOSDCloudOSSettings.OSReleaseID

    if ($global:InitializeOSDCloudWorkflow.DriverPackObject) {
        $global:InitializeOSDCloudWorkflow.DriverPackName = $global:InitializeOSDCloudWorkflow.DriverPackObject.Name
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] DriverPackName: $($global:InitializeOSDCloudWorkflow.DriverPackName)"
    }
    #=================================================
    $global:InitializeOSDCloudWorkflow
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
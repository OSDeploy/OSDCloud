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
    $DefaultOSLanguage = $global:OSDCloudWorkflowOSSettings."OSLanguageCode.default"
    $DefaultOSLanguageValues = [array]$global:OSDCloudWorkflowOSSettings."OSLanguageCode.values"
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
    $Architecture = $global:OSDCloudWorkflowGather.Architecture
    $DriverPackValues = Get-OSDCatalogDriverPacks | Where-Object { $_.Manufacturer -eq $global:OSDCloudWorkflowGather.ComputerManufacturer }
    # $DriverPackValues = Get-OSDCatalogDriverPacks | Where-Object { $_.Manufacturer -eq $global:OSDCloudWorkflowGather.ComputerManufacturer } | Where-Object { $_.OSArchitecture -eq $Architecture }
    #=================================================
    #   Main
    #=================================================
    $global:OSDCloudWorkflowInit = $null
    $global:OSDCloudWorkflowInit = [ordered]@{
        ComputerManufacturer  = $global:OSDCloudWorkflowGather.ComputerManufacturer
        ComputerModel         = $global:OSDCloudWorkflowGather.ComputerModel
        ComputerProduct       = $global:OSDCloudWorkflowGather.ComputerProduct
        DriverPackObject      = $null
        DriverPackName        = $null
        DriverPackValues      = [array]$DriverPackValues
        Function              = $($MyInvocation.MyCommand.Name)
        LaunchMethod          = 'OSDCloudWorkflow'
        Module                = $($MyInvocation.MyCommand.Module.Name)
        OSActivation          = $global:OSDCloudWorkflowOSSettings."OSActivation.default"
        OSActivationValues    = [array]$global:OSDCloudWorkflowOSSettings."OSActivation.values"
        OSArchitecture        = $Architecture
        OSEdition             = $global:OSDCloudWorkflowOSSettings."OSEdition.default"
        OSEditionId           = $global:OSDCloudWorkflowOSSettings."OSEditionId.default"
        OSEditionValues       = [array]$global:OSDCloudWorkflowOSSettings."OSEdition.values"
        # OSImageIndex          = $null
        OSLanguage            = $global:OSDCloudWorkflowOSSettings."OSLanguageCode.default"
        OSLanguageValues      = [array]$global:OSDCloudWorkflowOSSettings."OSLanguageCode.values"
        OSName                = $global:OSDCloudWorkflowOSSettings."OSName.default"
        OSNameValues          = [array]$global:OSDCloudWorkflowOSSettings."OSName.values"
        OSReleaseIDValues     = [array]$global:OSDCloudWorkflowOSSettings."OSReleaseID.values"
        TimeStart             = [datetime](Get-Date)
    }
    #=================================================
    #   Set Driver Pack
    #   New logic added to Get-OSDCatalogDriverPack
    #   This should match the proper OS Version ReleaseID
    #=================================================
    $global:OSDCloudWorkflowInit.DriverPackObject = Get-OSDCatalogDriverPack -Product $global:OSDCloudWorkflowInit.ComputerProduct -OSVersion $global:OSDCloudWorkflowInit.OperatingSystem -OSReleaseID $global:OSDCloudWorkflowOSSettings.OSReleaseID

    if ($global:OSDCloudWorkflowInit.DriverPackObject) {
        $global:OSDCloudWorkflowInit.DriverPackName = $global:OSDCloudWorkflowInit.DriverPackObject.Name
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] DriverPackName: $($global:OSDCloudWorkflowInit.DriverPackName)"
    }
    #=================================================
    $global:OSDCloudWorkflowInit
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
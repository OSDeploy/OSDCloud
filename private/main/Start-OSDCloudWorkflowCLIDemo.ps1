function Start-OSDCloudWorkflowCLIDemo {
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
    Initialize-OSDCloud
    #=================================================
    #   Get-Culture
    #=================================================
    $DefaultOSLanguage = $global:OSDCloudWorkflowOS."OSLanguageCode.default"
    $DefaultOSLanguageValues = [array]$global:OSDCloudWorkflowOS."OSLanguageCode.values"
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
        OSActivation          = $global:OSDCloudWorkflowOS."OSActivation.default"
        OSActivationValues    = [array]$global:OSDCloudWorkflowOS."OSActivation.values"
        OSArchitecture        = $Architecture
        OSEdition             = $global:OSDCloudWorkflowOS."OSEdition.default"
        OSEditionId           = $global:OSDCloudWorkflowOS."OSEditionId.default"
        OSEditionValues       = [array]$global:OSDCloudWorkflowOS."OSEdition.values"
        # OSImageIndex          = $null
        OSLanguage            = $global:OSDCloudWorkflowOS."OSLanguageCode.default"
        OSLanguageValues      = [array]$global:OSDCloudWorkflowOS."OSLanguageCode.values"
        OSName                = $global:OSDCloudWorkflowOS."OSName.default"
        OSNameValues          = [array]$global:OSDCloudWorkflowOS."OSName.values"
        OSReleaseIDValues     = [array]$global:OSDCloudWorkflowOS."OSReleaseID.values"
        TimeStart             = [datetime](Get-Date)
    }
    #=================================================
    #   Set Driver Pack
    #   New logic added to Get-OSDCatalogDriverPack
    #   This should match the proper OS Version ReleaseID
    #=================================================
    $global:OSDCloudWorkflowInit.DriverPackObject = Get-OSDCatalogDriverPack -Product $global:OSDCloudWorkflowInit.ComputerProduct -OSVersion $global:OSDCloudWorkflowInit.OperatingSystem -OSReleaseID $global:OSDCloudWorkflowOS.OSReleaseID

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
function Initialize-OSDCloud {
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
    #=================================================
    #   Import Configuration
    #=================================================
    Initialize-OSDCloudWorkflowGather

    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Importing OS Defaults $ModuleVersion"
    Initialize-OSDCloudWorkflowOS

    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Importing User Settings $ModuleVersion"
    Initialize-OSDCloudWorkflowUser

    #Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Importing Workflow Steps $ModuleVersion"
    #Initialize-OSDCloudWorkflowSteps
    
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Importing Operating Systems $ModuleVersion"
    $global:OSDCatalogOperatingSystems = Get-OSDCatalogOperatingSystems
    $global:OSDCatalogOperatingSystems = $global:OSDCatalogOperatingSystems | Where-Object {$_.Architecture -match "$($global:OSDCloudWorkflowGather.Architecture)"}

    if ($global:OSDCloudWorkflowOS."OSName.default" -match 'Win11') {
        $OperatingSystem = 'Windows 11'
    } elseif ($global:OSDCloudWorkflowOS."OperatingSystem.default" -match 'Win10') {
        $OperatingSystem = 'Windows 10'
    } else {
        $OperatingSystem = 'Windows 11'
    }
    $OSReleaseID = ($global:OSDCloudWorkflowOS."OSReleaseID.default" -split '-')[1]
    #=================================================
    # Main
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
        OperatingSystem       = $OperatingSystem
        OSActivation          = $global:OSDCloudWorkflowOS."OSActivation.default"
        OSActivationValues    = [array]$global:OSDCloudWorkflowOS."OSActivation.values"
        OSArchitecture        = $global:OSDCloudWorkflowGather.Architecture
        OSEdition             = $global:OSDCloudWorkflowOS."OSEdition.default"
        OSEditionId           = $global:OSDCloudWorkflowOS."OSEditionId.default"
        OSEditionValues       = [array]$global:OSDCloudWorkflowOS."OSEdition.values"
        # OSImageIndex          = $null
        OSLanguage            = $global:OSDCloudWorkflowOS."OSLanguageCode.default"
        OSLanguageValues      = [array]$global:OSDCloudWorkflowOS."OSLanguageCode.values"
        OSName                = $global:OSDCloudWorkflowOS."OSName.default"
        OSNameValues          = [array]$global:OSDCloudWorkflowOS."OSName.values"
        OSReleaseID           = $OSReleaseID
        TimeStart             = $null
    }
    #=================================================
    # Launch Frontend
    # $global:OSDCloudWorkflowInit.TimeStart = [datetime](Get-Date)
    # Make sure this is set in the frontend or Invoke-OSDCloudWorkflow will not run
    # This is not a bug, this is a safety feature to prevent accidental runs
    #=================================================
    #   Set DriverPack
    # $global:OSDCloudWorkflowInit.DriverPackValues = Get-OSDCatalogDriverPacks | Where-Object { $_.OSArchitecture -match $global:OSDCloudWorkflowGather.Architecture } | Where-Object { $_.Manufacturer -eq $global:OSDCloudWorkflowGather.ComputerManufacturer }
    $global:OSDCloudWorkflowInit.DriverPackValues = Get-OSDCatalogDriverPacks | Where-Object { $_.OSArchitecture -match $global:OSDCloudWorkflowGather.Architecture }
    $global:OSDCloudWorkflowInit.DriverPackObject = Get-OSDCatalogDriverPack -Product $global:OSDCloudWorkflowInit.ComputerProduct -OSVersion $global:OSDCloudWorkflowInit.OperatingSystem -OSReleaseID $global:OSDCloudWorkflowOS.OSReleaseID

    if ($global:OSDCloudWorkflowInit.DriverPackObject) {
        $global:OSDCloudWorkflowInit.DriverPackName = $global:OSDCloudWorkflowInit.DriverPackObject.Name
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] DriverPackName: $($global:OSDCloudWorkflowInit.DriverPackName)"
    }
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
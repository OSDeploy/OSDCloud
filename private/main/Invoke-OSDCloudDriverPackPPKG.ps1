function Invoke-OSDCloudDriverPackPPKGB {
    <#
    .SYNOPSIS
    Uses DISM in WinPE to expand and apply Driver Packs

    .DESCRIPTION
    Uses DISM in WinPE to expand and apply Driver Packs

    .LINK
    https://github.com/OSDeploy/OSD/tree/master/Docs
    #>
    [CmdletBinding()]
    param ()
    Write-Host 'Adding MSI PPKG'
    $DriverProvisioningPackage = Join-Path (Get-Module -Name 'OSDCloud' -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).ModuleBase "Provisioning\Invoke-OSDCloudDriverPack.ppkg"

    if (Test-Path $DriverProvisioningPackage) {
        Write-Host -ForegroundColor DarkGray "dism.exe /Image=C:\ /Add-ProvisioningPackage /PackagePath:`"$DriverProvisioningPackage`""
        $Dism = "dism.exe"
        $ArgumentList = "/Image=C:\ /Add-ProvisioningPackage /PackagePath:`"$DriverProvisioningPackage`""
        $null = Start-Process -FilePath 'dism.exe' -ArgumentList $ArgumentList -Wait -NoNewWindow
    }
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
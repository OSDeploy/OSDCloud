#=======================================================================
#   Header
#=======================================================================
Write-Host -ForegroundColor DarkGray "========================================================================="
Write-Host -ForegroundColor Green "Start-AutopilotBridge"
#=======================================================================
#   Transcript
#=======================================================================
Write-Host -ForegroundColor DarkGray "========================================================================="
Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Start-Transcript"
$Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-AutopilotBridge.log"
Start-Transcript -Path (Join-Path "$env:SystemRoot\Temp" $Transcript) -ErrorAction Ignore
#=======================================================================
#   Profile OSDeploy
#=======================================================================
$Title = 'OSDeploy Autopilot Bridge'
$DriverUpdate = $true
$WindowsUpdate = $true
$WindowsCapabilityRSAT = $true
$RemoveAppx = @('CommunicationsApps','OfficeHub','People','Skype','Solitaire','Xbox','ZuneMusic','ZuneVideo')
$ProductKey = 'NPPR9-FWDCX-D2C8J-H872K-2YT43'
#=======================================================================
#	WindowsCapabilityRSAT
#=======================================================================
if ($ProductKey) {
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Set-WindowsEdition Enterprise (ChangePK)"
    Invoke-Exe changepk.exe /ProductKey $ProductKey
    Get-WindowsEdition -Online
}
#=======================================================================
#	WindowsCapabilityRSAT
#=======================================================================
if ($WindowsCapabilityRSAT) {
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Windows Capability RSAT"
    $AddWindowsCapability = Get-MyWindowsCapability -Category Rsat -Detail
    foreach ($Item in $AddWindowsCapability) {
        if ($Item.State -eq 'Installed') {
            Write-Host -ForegroundColor DarkGray "$($Item.DisplayName)"
        }
        else {
            Write-Host -ForegroundColor DarkCyan "$($Item.DisplayName)"
            #$Item | Add-WindowsCapability -Online -ErrorAction Ignore | Out-Null
        }
    }
}
#=======================================================================
#	Remove-AppxOnline
#=======================================================================
if ($RemoveAppx) {
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Remove-AppxOnline"

    foreach ($Item in $RemoveAppx) {
        Remove-AppxOnline -Name $Item
    }
}
#=======================================================================
#	DriverUpdate
#=======================================================================
if ($DriverUpdate) {
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) PSWindowsUpdate Driver Update"
    if (!(Get-Module PSWindowsUpdate -ListAvailable)) {
        try {
            Install-Module PSWindowsUpdate -Force
        }
        catch {
            Write-Warning 'Unable to install PSWindowsUpdate PowerShell Module'
            $DriverUpdate = $false
        }
    }
}
if ($DriverUpdate) {
    Get-WindowsUpdate -UpdateType Software -AcceptAll -IgnoreReboot
}
#=======================================================================
#	WindowsUpdate
#=======================================================================
if ($WindowsUpdate) {
    Write-Host -ForegroundColor DarkGray "========================================================================="
    Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) PSWindowsUpdate Windows Update"
    if (!(Get-Module PSWindowsUpdate -ListAvailable)) {
        try {
            Install-Module PSWindowsUpdate -Force
        }
        catch {
            Write-Warning 'Unable to install PSWindowsUpdate PowerShell Module'
            $WindowsUpdate = $false
        }
    }
}
if ($WindowsUpdate) {
    #Add-WUServiceManager -ServiceID "7971f918-a847-4430-9279-4a52d1efe18d" -AddServiceFlag 7
    Add-WUServiceManager -MicrosoftUpdate -Silent
    Install-WindowsUpdate -UpdateType Software -AcceptAll -IgnoreReboot -Install
}
#=======================================================================
#	Stop-Transcript
#=======================================================================
Write-Host -ForegroundColor DarkGray "========================================================================="
Write-Host -ForegroundColor Cyan "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Stop-Transcript"
Stop-Transcript
Write-Host -ForegroundColor DarkGray "========================================================================="
#=======================================================================
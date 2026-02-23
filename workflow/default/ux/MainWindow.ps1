<#!
.SYNOPSIS
	Interactive picker for OSDCloud operating system catalog entries.
#>
[CmdletBinding()]
param()
#================================================
Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase
#================================================
# Variables
$deviceBiosReleaseDate = $global:OSDCloudDevice.BiosReleaseDate
$deviceBiosVersion = $global:OSDCloudDevice.BiosVersion
$deviceOSDManufacturer = $global:OSDCloudDevice.OSDManufacturer
$deviceOSDModel = $global:OSDCloudDevice.OSDModel
$deviceOSDProduct = $global:OSDCloudDevice.OSDProduct
$deviceComputerSystemSKU = $global:OSDCloudDevice.ComputerSystemSKU
$deviceIsAutopilotSpec = $global:OSDCloudDevice.IsAutopilotSpec
$deviceIsTpmSpec = $global:OSDCloudDevice.IsTpmSpec
$deviceSerialNumber = $global:OSDCloudDevice.SerialNumber
$deviceUUID = $global:OSDCloudDevice.UUID
$getOSDCloudModuleVersion = Get-OSDCloudModuleVersion
#================================================
# XAML
$xamlfile = Get-Item -Path "$PSScriptRoot\MainWindow.xaml"
$xaml = Get-Content $xamlfile.FullName 

$stringReader = [System.IO.StringReader]::new($xaml)
$xmlReader = [System.Xml.XmlReader]::Create($stringReader)
$window = [Windows.Markup.XamlReader]::Load($xmlReader)
#================================================
# XAML - Window Title
$deviceTitleParts = @()

if (-not [string]::IsNullOrWhiteSpace($getOSDCloudModuleVersion)) {
	$deviceTitleParts += $getOSDCloudModuleVersion
}
if ($deviceTitleParts.Count -gt 0) {
	$window.Title = "OSDCloud version $($deviceTitleParts -join ' - ')"
}
#================================================
# Logo
$logoImage = $window.FindName('LogoImage')
if ($logoImage) {
	$logoImage.Source = "$PSScriptRoot\logo.png"
}
#================================================
# Menu Items
$RunCmdPrompt = $window.FindName("RunCmdPrompt")
$RunPowerShell = $window.FindName("RunPowerShell")
$RunPwsh = $window.FindName("RunPwsh")
$PrivacyMenuItem = $window.FindName("PrivacyMenuItem")
$LogsMenuItem = $window.FindName("LogsMenuItem")
$WMIMenuItem = $window.FindName("WMIMenuItem")

$RunCmdPrompt.Add_Click({
	try {
		Start-Process -FilePath "cmd.exe"
	} catch {
		[System.Windows.MessageBox]::Show("Failed to open CMD Prompt: $($_.Exception.Message)", "Error", "OK", "Error") | Out-Null
	}
})

$RunPowerShell.Add_Click({
	try {
		Start-Process -FilePath "powershell.exe"
	} catch {
		[System.Windows.MessageBox]::Show("Failed to open PowerShell: $($_.Exception.Message)", "Error", "OK", "Error") | Out-Null
	}
})

if ($RunPwsh) {
	$pwshCommand = Get-Command -Name 'pwsh.exe' -ErrorAction SilentlyContinue
	if ($pwshCommand) {
		$script:PwshPath = $pwshCommand.Source
		$RunPwsh.Visibility = [System.Windows.Visibility]::Visible
		$RunPwsh.Add_Click({
			try {
				Start-Process -FilePath $script:PwshPath
			} catch {
				[System.Windows.MessageBox]::Show("Failed to open PowerShell 7: $($_.Exception.Message)", "Error", "OK", "Error") | Out-Null
			}
		})
	} else {
		$RunPwsh.Visibility = [System.Windows.Visibility]::Collapsed
	}
}

$PrivacyMenuItem.Add_Click({
	$privacyMessage = @"
OSDCloud collects analytic data during the deployment process to identify issues, enhance performance, and improve the overall user experience.
No personally identifiable information (PII) is collected, and all data is anonymized to protect user privacy.

Collected data includes information about the deployment environment and system configuration.
By using OSDCloud, you consent to the collection of analytic data as outlined in the privacy policy

https://github.com/OSDeploy/OSDCloud/blob/main/PRIVACY.md
"@
	[System.Windows.MessageBox]::Show($privacyMessage, "OSDCloud Privacy Statement", "OK", "Information") | Out-Null
})

function Add-NoLogsMenuEntry {
	param(
		[Parameter(Mandatory)]
		[System.Windows.Controls.MenuItem]$MenuItem
	)

	$noLogsItem = [System.Windows.Controls.MenuItem]::new()
	$noLogsItem.Header = 'No logs found'
	$noLogsItem.IsEnabled = $false
	$MenuItem.Items.Add($noLogsItem) | Out-Null
}
function Set-LogsMenuItems {
	$LogsMenuItem.Items.Clear()

	$logsRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath 'osdcloud-logs'
	if (-not (Test-Path -LiteralPath $logsRoot)) {
		Add-NoLogsMenuEntry -MenuItem $LogsMenuItem
		return
	}

	$logFiles = Get-ChildItem -LiteralPath $logsRoot -File -ErrorAction SilentlyContinue | Sort-Object -Property Name
	$logFiles = $logFiles | Where-Object { $_.Name -NotLike "Win32_*.txt"}
	if (-not $logFiles) {
		Add-NoLogsMenuEntry -MenuItem $LogsMenuItem
		return
	}

	foreach ($logFile in $logFiles) {
		$logMenuItem = [System.Windows.Controls.MenuItem]::new()
		# Double underscores so WPF renders underscores literally instead of mnemonics
		$logMenuItem.Header = $logFile.Name -replace '_', '__'
		$logMenuItem.Tag = $logFile.FullName

		$logMenuItem.Add_Click({
			param($sender, $args)
			$logPath = [string]$sender.Tag
			if (-not (Test-Path -LiteralPath $logPath)) {
				[System.Windows.MessageBox]::Show('Log file not found.', 'Open Log', 'OK', 'Warning') | Out-Null
				return
			}

			try {
				Start-Process -FilePath 'notepad.exe' -ArgumentList @("`"$logPath`"") -ErrorAction Stop
			} catch {
				[System.Windows.MessageBox]::Show("Failed to open log: $($_.Exception.Message)", 'Open Log', 'OK', 'Error') | Out-Null
			}
		})

		$LogsMenuItem.Items.Add($logMenuItem) | Out-Null
	}
}
Set-LogsMenuItems
function Set-WMIMenuItems {
	$WMIMenuItem.Items.Clear()

	$logsRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath 'osdcloud-logs'
	if (-not (Test-Path -LiteralPath $logsRoot)) {
		Add-NoLogsMenuEntry -MenuItem $WMIMenuItem
		return
	}

	$logFiles = Get-ChildItem -LiteralPath $logsRoot -File -ErrorAction SilentlyContinue | Sort-Object -Property Name
	$logFiles = $logFiles | Where-Object { $_.Name -Like "Win32_*.txt"}
	if (-not $logFiles) {
		Add-NoLogsMenuEntry -MenuItem $WMIMenuItem
		return
	}

	foreach ($logFile in $logFiles) {
		$logMenuItem = [System.Windows.Controls.MenuItem]::new()
		# Double underscores so WPF renders underscores literally instead of mnemonics
		$logMenuItem.Header = $logFile.Name -replace '_', '__'
		$logMenuItem.Tag = $logFile.FullName

		$logMenuItem.Add_Click({
			param($sender, $args)
			$logPath = [string]$sender.Tag
			if (-not (Test-Path -LiteralPath $logPath)) {
				[System.Windows.MessageBox]::Show('Log file not found.', 'Open Log', 'OK', 'Warning') | Out-Null
				return
			}

			try {
				Start-Process -FilePath 'notepad.exe' -ArgumentList @("`"$logPath`"") -ErrorAction Stop
			} catch {
				[System.Windows.MessageBox]::Show("Failed to open log: $($_.Exception.Message)", 'Open Log', 'OK', 'Error') | Out-Null
			}
		})

		$WMIMenuItem.Items.Add($logMenuItem) | Out-Null
	}
}
Set-WMIMenuItems
#================================================
# TaskSequence
$TaskSequenceCombo = $window.FindName("TaskSequenceCombo")
$TaskSequenceCombo.ItemsSource = $global:OSDCloudDeploy.Flows.Name
$TaskSequenceCombo.SelectedIndex = 0
$TaskSequenceCombo.Add_SelectionChanged({
	if ($SummaryTaskSequenceText) {
		$value = [string]$TaskSequenceCombo.SelectedItem
		$SummaryTaskSequenceText.Text = if (-not [string]::IsNullOrWhiteSpace($value)) { $value } else { 'Not selected' }
	}
})
#================================================
# GlobalVariable Configuration
# Environment Configuration
# Workflow Configuration
if ($global:OSDCloudDeploy.OperatingSystemValues) {
	$OperatingSystemValues = $global:OSDCloudDeploy.OperatingSystemValues
	Write-Verbose "Workflow OperatingSystemValues = $OperatingSystemValues"
}
# Catalog Configuration
else {
	$OperatingSystemValues = $global:DeployOSDCloudOperatingSystems.OperatingSystem | Sort-Object -Unique | Sort-Object -Descending
	Write-Verbose "Catalog OperatingSystemValues = $OperatingSystemValues"
}
$OperatingSystemCombo = $window.FindName("OperatingSystemCombo")
$OperatingSystemCombo.ItemsSource = $OperatingSystemValues
#================================================
# OperatingSystemDefault
if ($global:OSDCloudDeploy.OperatingSystem) {
	$OperatingSystemDefault = $global:OSDCloudDeploy.OperatingSystem
	Write-Verbose "Workflow OperatingSystem = $OperatingSystemDefault"
}
if ($OperatingSystemDefault -and ($OperatingSystemValues -contains $OperatingSystemDefault)) {
	$OperatingSystemCombo.SelectedItem = $OperatingSystemDefault
} elseif ($OperatingSystemValues) {
	$OperatingSystemCombo.SelectedIndex = 0
} else {
	$OperatingSystemCombo.SelectedIndex = -1
}
#================================================
# OSEditionValues
# GlobalVariable Configuration
# Environment Configuration
# Workflow Configuration
if ($global:OSDCloudDeploy.OSEditionValues.Edition) {
	$OSEditionValues = $global:OSDCloudDeploy.OSEditionValues.Edition
	Write-Verbose "Workflow OSEditionValues = $OSEditionValues"
}
else {
	@()
}
$OSEditionCombo = $window.FindName("OSEditionCombo")
$OSEditionCombo.ItemsSource = $OSEditionValues
#================================================
# OSEditionDefault
if ($global:OSDCloudDeploy.OSEdition) {
	$OSEditionDefault = $global:OSDCloudDeploy.OSEdition
	Write-Verbose "Workflow OSEdition = $OSEditionDefault"
}
if ($OSEditionDefault) {
	$OSEditionCombo.SelectedItem = $OSEditionDefault
} elseif ($OperatingSystemValues) {
	$OSEditionCombo.SelectedIndex = 0
} else {
	$OSEditionCombo.SelectedIndex = -1
}
#================================================
# OSActivationValues
# GlobalVariable Configuration
# Environment Configuration
# Workflow Configuration
if ($global:OSDCloudDeploy.OSActivationValues) {
	$OSActivationValues = $global:OSDCloudDeploy.OSActivationValues
	Write-Verbose "Workflow OSActivationValues = $OSActivationValues"
}
else {
	@()
}
$OSActivationCombo = $window.FindName("OSActivationCombo")
$OSActivationCombo.ItemsSource = $OSActivationValues
#================================================
# OSActivationDefault
if ($global:OSDCloudDeploy.OSActivation) {
	$OSActivationDefault = $global:OSDCloudDeploy.OSActivation
	Write-Verbose "Workflow OSActivation = $OSActivationDefault"
}
if ($OSActivationDefault -and ($OSActivationValues -contains $OSActivationDefault)) {
	$OSActivationCombo.SelectedItem = $OSActivationDefault
} elseif ($OSActivationValues) {
	$OSActivationCombo.SelectedIndex = 0
} else {
	$OSActivationCombo.SelectedIndex = -1
}
#================================================
# OSLanguageCodeValues
# GlobalVariable Configuration
# Environment Configuration
# Workflow Configuration
if ($global:OSDCloudDeploy.OSLanguageCodeValues) {
	$OSLanguageCodeValues = $global:OSDCloudDeploy.OSLanguageCodeValues
	Write-Verbose "Workflow OSLanguageCodeValues = $OSLanguageCodeValues"
}
# Catalog Configuration
else {
	$OSLanguageCodeValues = $global:DeployOSDCloudOperatingSystems.OSLanguageCode | Sort-Object -Unique | Sort-Object -Descending
	Write-Verbose "Catalog OSLanguageCodeValues = $OSLanguageCodeValues"
}
$OSLanguageCodeCombo = $window.FindName("OSLanguageCodeCombo")
$OSLanguageCodeCombo.ItemsSource = $OSLanguageCodeValues
#================================================
# OSLanguageCodeDefault
if ($global:OSDCloudDeploy.OSLanguageCode) {
	$OSLanguageCodeDefault = $global:OSDCloudDeploy.OSLanguageCode
	Write-Verbose "Workflow OSLanguage = $OSLanguageCodeDefault"
}
if ($OSLanguageCodeDefault -and ($OSLanguageCodeValues -contains $OSLanguageCodeDefault)) {
	$OSLanguageCodeCombo.SelectedItem = $OSLanguageCodeDefault
} elseif ($OSLanguageCodeValues) {
	$OSLanguageCodeCombo.SelectedIndex = 0
} else {
	$OSLanguageCodeCombo.SelectedIndex = -1
}
#================================================
# DriverPackCombo
# GlobalVariable Configuration
# Environment Configuration
# Workflow Configuration
#================================================
# Import the DriverPack Catalog
$DriverPackCatalog = @('None','Microsoft Update Catalog')
if ($global:OSDCloudDeploy.DriverPackValues) {
	$DriverPackCatalog += $global:OSDCloudDeploy.DriverPackValues | ForEach-Object { $_.Name }
}
$DriverPackCombo = $window.FindName("DriverPackCombo")
$DriverPackCombo.ItemsSource = $DriverPackCatalog
if ($global:OSDCloudDeploy.DriverPackName) {
	$DriverPackCombo.SelectedValue = $global:OSDCloudDeploy.DriverPackName
}
else {
	$DriverPackCombo.SelectedIndex = 0
}
#================================================
# Other Settings
$deviceBiosReleaseDateText = $window.FindName("deviceBiosReleaseDateText")
$deviceBiosReleaseDateText.Text = $deviceBiosReleaseDate
$deviceBiosVersionText = $window.FindName("deviceBiosVersionText")
$deviceBiosVersionText.Text = $deviceBiosVersion
$deviceOSDManufacturerText = $window.FindName("deviceOSDManufacturerText")
$deviceOSDManufacturerText.Text = $deviceOSDManufacturer
$deviceOSDModelText = $window.FindName("deviceOSDModelText")
$deviceOSDModelText.Text = $deviceOSDModel
$deviceOSDProductText = $window.FindName("deviceOSDProductText")
$deviceOSDProductText.Text = $deviceOSDProduct
$deviceComputerSystemSKUText = $window.FindName("deviceComputerSystemSKUText")
$deviceComputerSystemSKUText.Text = $deviceComputerSystemSKU
$deviceSerialNumberText = $window.FindName("deviceSerialNumberText")
$deviceSerialNumberText.Text = $deviceSerialNumber
$deviceIsAutopilotSpecText = $window.FindName("deviceIsAutopilotSpecText")
$deviceIsAutopilotSpecText.Text = $deviceIsAutopilotSpec
$deviceIsTpmSpecText = $window.FindName("deviceIsTpmSpecText")
$deviceIsTpmSpecText.Text = $deviceIsTpmSpec
$deviceUUIDText = $window.FindName("deviceUUIDText")
$deviceUUIDText.Text = $deviceUUID
$SelectedOSLanguageText = $window.FindName("SelectedOSLanguageText")
$SelectedIdText = $window.FindName("SelectedIdText")
$SelectedFileNameText = $window.FindName("SelectedFileNameText")
$DriverPackUrlText = $window.FindName("DriverPackUrlText")
$DriverPackUrlText.Text = [string]$global:OSDCloudDeploy.DriverPackObject.Url
$StartButton = $window.FindName("StartButton")
$StartButton.IsEnabled = $false

function Get-ComboValue {
	param(
		[Parameter(Mandatory)]
		[System.Windows.Controls.ComboBox]$ComboBox
	)

	$value = $ComboBox.SelectedItem
	if ($null -eq $value) {
		return $null
	}

	$text = [string]$value
	if ([string]::IsNullOrWhiteSpace($text)) {
		return $null
	}

	return $text
}

function Set-StartButtonState {
	$StartButton.IsEnabled = ($null -ne $global:OSDCloudDeploy.OperatingSystemObject)
}

function Update-SelectedDetails {
	param(
		[Parameter()]
		$Item
	)

	if (-not $Item) {
		$SelectedIdText.Text = 'No matching catalog entry.'
		$SelectedOSLanguageText.Text = '-'
		$SelectedFileNameText.Text = '-'
		return
	}

	$SelectedIdText.Text = [string]$Item.Id
	$SelectedOSLanguageText.Text = if ($Item.OSLanguage) {
		[string]$Item.OSLanguage
	}
	elseif ($Item.OSLanguageCode) {
		[string]$Item.OSLanguageCode
	}
	else {
		'-'
	}
	$SelectedFileNameText.Text = [string]$Item.FileName
}

function Update-OsResults {
	# Keep filtering logic centralized so every control refreshes the same view.
	$updateOperatingSystem = Get-ComboValue -ComboBox $OperatingSystemCombo
	$updateOSEdition = Get-ComboValue -ComboBox $OSEditionCombo
	$updateOSActivation = Get-ComboValue -ComboBox $OSActivationCombo
	$updateOSLanguageCode = Get-ComboValue -ComboBox $OSLanguageCodeCombo

	Write-Verbose "updateOperatingSystem = $updateOperatingSystem"
	Write-Verbose "updateOSEdition = $updateOSEdition"
	Write-Verbose "updateOSActivation = $updateOSActivation"
	Write-Verbose "updateOSLanguageCode = $updateOSLanguageCode"

    $global:OSDCloudDeploy.OperatingSystemObject = $global:DeployOSDCloudOperatingSystems | `
		Where-Object { $_.OperatingSystem -match $updateOperatingSystem } | `
		Where-Object { $_.OSActivation -eq $updateOSActivation } | `
		Where-Object { $_.OSLanguageCode -eq $updateOSLanguageCode } | Select-Object -First 1
	
    if (-not $global:OSDCloudDeploy.OperatingSystemObject) {
        throw "No Operating System found for OperatingSystem: $updateOperatingSystem, OSActivation: $updateOSActivation, OSLanguageCode: $updateOSLanguageCode. Please check your OSDCloud OperatingSystems."
    }

	$script:SelectedImage = $global:OSDCloudDeploy.OperatingSystemObject

	if ($updateOSEdition -match 'Home') {
		$OSActivationCombo.SelectedValue = 'Retail'
		$OSActivationCombo.IsEnabled = $false
	}
	if ($updateOSEdition -match 'Education') {
		$OSActivationCombo.IsEnabled = $true
	}
	if ($updateOSEdition -match 'Enterprise') {
		$OSActivationCombo.SelectedValue = 'Volume'
		$OSActivationCombo.IsEnabled = $false
	}
	if ($updateOSEdition -match 'Pro') {
		$OSActivationCombo.IsEnabled = $true
	}

	Update-SelectedDetails -Item $script:SelectedImage

	Set-StartButtonState
}

function Update-DriverPackResults {
	$DriverPackName = Get-ComboValue -ComboBox $DriverPackCombo
	$global:OSDCloudDeploy.DriverPackName = $DriverPackName
	$global:OSDCloudDeploy.DriverPackObject = $global:OSDCloudDeploy.DriverPackValues | Where-Object { $_.Name -eq $DriverPackName }
	$DriverPackUrlText.Text = [string]$global:OSDCloudDeploy.DriverPackObject.Url
}

$OperatingSystemCombo.Add_SelectionChanged({ Update-OsResults })
$OSEditionCombo.Add_SelectionChanged({ Update-OsResults })
$OSActivationCombo.Add_SelectionChanged({ Update-OsResults })
$OSLanguageCodeCombo.Add_SelectionChanged({ Update-OsResults })

$DriverPackCombo.Add_SelectionChanged({ Update-DriverPackResults })

$script:SelectionConfirmed = $false

$StartButton.Add_Click({
	$script:SelectionConfirmed = $true
	$window.DialogResult = $true
	$window.Close()
})

Update-OsResults

# Initialize Configuration summary with current values
if ($SummaryTaskSequenceText) {
	$value = [string]$TaskSequenceCombo.SelectedItem
	$SummaryTaskSequenceText.Text = if (-not [string]::IsNullOrWhiteSpace($value)) { $value } else { 'Not selected' }
}

$null = $window.ShowDialog()

if ($script:SelectionConfirmed) {
	#================================================
	# Local Variables
	$OSDCloudWorkflowTaskName = $TaskSequenceCombo.SelectedValue
	$OSDCloudWorkflowTaskObject = $global:OSDCloudDeploy.Flows | Where-Object { $_.Name -eq $OSDCloudWorkflowTaskName } | Select-Object -First 1
	$OperatingSystemObject = $global:OSDCloudDeploy.OperatingSystemObject
	$OSEditionId = $global:OSDCloudDeploy.OSEditionValues | Where-Object { $_.Edition -eq $OSEditionCombo.SelectedValue } | Select-Object -ExpandProperty EditionId
	#================================================
	# Global Variables
	$global:OSDCloudDeploy.WorkflowTaskName = $OSDCloudWorkflowTaskName
	$global:OSDCloudDeploy.WorkflowTaskObject = $OSDCloudWorkflowTaskObject
	# $global:OSDCloudDeploy.DriverPackName = $DriverPackName
	# $global:OSDCloudDeploy.DriverPackObject = $DriverPackObject
	# DriverPackValues
	# Flows
	# Function
	$global:OSDCloudDeploy.ImageFileName = $OperatingSystemObject.FileName
	$global:OSDCloudDeploy.ImageFileUrl = $OperatingSystemObject.FilePath
	# LaunchMethod
	# Module
	$global:OSDCloudDeploy.OperatingSystemObject = $OperatingSystemObject
	$global:OSDCloudDeploy.OperatingSystem = $OperatingSystemObject.OSName
	$global:OSDCloudDeploy.OSActivation = $OperatingSystemObject.OSActivation
	# OSActivationValues
	# OSArchitecture
	$global:OSDCloudDeploy.OSBuild = $OperatingSystemObject.OSBuild
	# OSBuildVersion
	$global:OSDCloudDeploy.OSEdition = Get-ComboValue -ComboBox $OSEditionCombo
	$global:OSDCloudDeploy.OSEditionId = $OSEditionId
	# OSEditionValues
	$global:OSDCloudDeploy.OSLanguageCode = $OperatingSystemObject.OSLanguageCode
	# OSLanguageValues
	$global:OSDCloudDeploy.OperatingSystem = $OperatingSystemObject.OperatingSystem
	# OperatingSystemValues
	$global:OSDCloudDeploy.OSVersion = $OperatingSystemObject.OSVersion
	$global:OSDCloudDeploy.TimeStart = (Get-Date)
	$global:OSDCloudDeploy.LocalImageFileInfo = $LocalImageFileInfo
	$global:OSDCloudDeploy.LocalImageFilePath = $LocalImageFilePath
	$global:OSDCloudDeploy.LocalImageName = $LocalImageName

    $LogsPath = "$env:TEMP\osdcloud-logs"
    if (-not (Test-Path -Path $LogsPath)) {
        New-Item -Path $LogsPath -ItemType Directory -Force | Out-Null
    }
	$global:OSDCloudDeploy | Out-File -FilePath "$LogsPath\OSDCloudDeploy.txt" -Force
}

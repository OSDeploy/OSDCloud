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
$Architecture = $global:OSDCloudWorkflowDevice.ProcessorArchitecture
$BiosReleaseDate = $global:OSDCloudWorkflowDevice.BiosReleaseDate
$BiosVersion = $global:OSDCloudWorkflowDevice.BiosVersion
$ChassisType = $global:OSDCloudWorkflowDevice.ChassisType
$ComputerManufacturer = $global:OSDCloudWorkflowDevice.ComputerManufacturer
$ComputerModel = $global:OSDCloudWorkflowDevice.ComputerModel
$ComputerProduct = $global:OSDCloudWorkflowDevice.ComputerProduct
$ComputerSystemSKUNumber = $global:OSDCloudWorkflowDevice.ComputerSystemSKUNumber
$IsAutopilotReady = $global:OSDCloudWorkflowDevice.IsAutopilotReady
$IsTpmReady = $global:OSDCloudWorkflowDevice.IsTpmReady
$SerialNumber = $global:OSDCloudWorkflowDevice.SerialNumber
$UUID = $global:OSDCloudWorkflowDevice.UUID
#================================================
# XAML
$xamlfile = Get-Item -Path "$PSScriptRoot\MainWindow.xaml"
$xaml = Get-Content $xamlfile.FullName 

$stringReader = [System.IO.StringReader]::new($xaml)
$xmlReader = [System.Xml.XmlReader]::Create($stringReader)
$window = [Windows.Markup.XamlReader]::Load($xmlReader)
$deviceTitleParts = @()
$manufacturerText = [string]$ComputerManufacturer
$modelText = [string]$ComputerModel
$serialText = [string]$SerialNumber

if (-not [string]::IsNullOrWhiteSpace($manufacturerText)) {
	$deviceTitleParts += $manufacturerText
}
if (-not [string]::IsNullOrWhiteSpace($modelText)) {
	$deviceTitleParts += $modelText
}
if (-not [string]::IsNullOrWhiteSpace($serialText)) {
	$deviceTitleParts += "$serialText"
}

if ($deviceTitleParts.Count -gt 0) {
	$window.Title = "OSDCloud on $($deviceTitleParts -join ' - ')"
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
$AboutMenuItem = $window.FindName("AboutMenuItem")
$LogsMenuItem = $window.FindName("LogsMenuItem")
$HardwareMenuItem = $window.FindName("HardwareMenuItem")

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

$AboutMenuItem.Add_Click({
	$aboutMessage = @"
OSDCloud - Community Edition
Placeholder help content will go here. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec in turpis nec leo fermentum interdum.
"@
	[System.Windows.MessageBox]::Show($aboutMessage, "About OSDCloud", "OK", "Information") | Out-Null
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
function Set-HardwareMenuItems {
	$HardwareMenuItem.Items.Clear()

	$logsRoot = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath 'osdcloud-logs-wmi'
	if (-not (Test-Path -LiteralPath $logsRoot)) {
		Add-NoLogsMenuEntry -MenuItem $HardwareMenuItem
		return
	}

	$logFiles = Get-ChildItem -LiteralPath $logsRoot -File -ErrorAction SilentlyContinue | Sort-Object -Property Name
	if (-not $logFiles) {
		Add-NoLogsMenuEntry -MenuItem $HardwareMenuItem
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

		$HardwareMenuItem.Items.Add($logMenuItem) | Out-Null
	}
}
Set-HardwareMenuItems
#================================================
# TaskSequence
$TaskSequenceCombo = $window.FindName("TaskSequenceCombo")
$TaskSequenceCombo.ItemsSource = $global:OSDCloudWorkflowInit.Flows.Name
$TaskSequenceCombo.SelectedIndex = 0
$TaskSequenceCombo.Add_SelectionChanged({
	if ($SummaryTaskSequenceText) {
		$value = [string]$TaskSequenceCombo.SelectedItem
		$SummaryTaskSequenceText.Text = if (-not [string]::IsNullOrWhiteSpace($value)) { $value } else { 'Not selected' }
	}
})
#================================================
# Disk
try {
	$DiskCombo = $window.FindName("DiskCombo")
	if ($DiskCombo) {
		$deploymentDisks = @(Get-DeploymentDiskObject -ErrorAction SilentlyContinue)
		if ($deploymentDisks) {
			$DiskCombo.ItemsSource = $deploymentDisks | Select-Object -ExpandProperty DiskNumber
			if ($DiskCombo.Items.Count -gt 0) {
				$DiskCombo.SelectedIndex = 0
			}
		}
	}
} catch {
	Write-Verbose "Error populating Disk combo: $_"
}
#================================================
# GlobalVariable Configuration
# Environment Configuration
# Workflow Configuration
if ($global:OSDCloudWorkflowInit.OperatingSystemValues) {
	$OperatingSystemValues = $global:OSDCloudWorkflowInit.OperatingSystemValues
	Write-Verbose "Workflow OperatingSystemValues = $OperatingSystemValues"
}
# Catalog Configuration
else {
	$OperatingSystemValues = $global:PSOSDCloudOperatingSystems.OperatingSystem | Sort-Object -Unique | Sort-Object -Descending
	Write-Verbose "Catalog OperatingSystemValues = $OperatingSystemValues"
}
$OperatingSystemCombo = $window.FindName("OperatingSystemCombo")
$OperatingSystemCombo.ItemsSource = $OperatingSystemValues
#================================================
# OperatingSystemDefault
if ($global:OSDCloudWorkflowInit.OperatingSystem) {
	$OperatingSystemDefault = $global:OSDCloudWorkflowInit.OperatingSystem
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
if ($global:OSDCloudWorkflowInit.OSEditionValues.Edition) {
	$OSEditionValues = $global:OSDCloudWorkflowInit.OSEditionValues.Edition
	Write-Verbose "Workflow OSEditionValues = $OSEditionValues"
}
else {
	@()
}
$OSEditionCombo = $window.FindName("OSEditionCombo")
$OSEditionCombo.ItemsSource = $OSEditionValues
#================================================
# OSEditionDefault
if ($global:OSDCloudWorkflowInit.OSEdition) {
	$OSEditionDefault = $global:OSDCloudWorkflowInit.OSEdition
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
if ($global:OSDCloudWorkflowInit.OSActivationValues) {
	$OSActivationValues = $global:OSDCloudWorkflowInit.OSActivationValues
	Write-Verbose "Workflow OSActivationValues = $OSActivationValues"
}
else {
	@()
}
$OSActivationCombo = $window.FindName("OSActivationCombo")
$OSActivationCombo.ItemsSource = $OSActivationValues
#================================================
# OSActivationDefault
if ($global:OSDCloudWorkflowInit.OSActivation) {
	$OSActivationDefault = $global:OSDCloudWorkflowInit.OSActivation
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
if ($global:OSDCloudWorkflowInit.OSLanguageCodeValues) {
	$OSLanguageCodeValues = $global:OSDCloudWorkflowInit.OSLanguageCodeValues
	Write-Verbose "Workflow OSLanguageCodeValues = $OSLanguageCodeValues"
}
# Catalog Configuration
else {
	$OSLanguageCodeValues = $global:PSOSDCloudOperatingSystems.OSLanguageCode | Sort-Object -Unique | Sort-Object -Descending
	Write-Verbose "Catalog OSLanguageCodeValues = $OSLanguageCodeValues"
}
$OSLanguageCodeCombo = $window.FindName("OSLanguageCodeCombo")
$OSLanguageCodeCombo.ItemsSource = $OSLanguageCodeValues
#================================================
# OSLanguageCodeDefault
if ($global:OSDCloudWorkflowInit.OSLanguageCode) {
	$OSLanguageCodeDefault = $global:OSDCloudWorkflowInit.OSLanguageCode
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
$DriverPackCatalog = @('None','Microsoft Catalog')
if ($global:OSDCloudWorkflowInit.DriverPackValues) {
	$DriverPackCatalog += $global:OSDCloudWorkflowInit.DriverPackValues | ForEach-Object { $_.Name }
}
$DriverPackCombo = $window.FindName("DriverPackCombo")
$DriverPackCombo.ItemsSource = $DriverPackCatalog
if ($global:OSDCloudWorkflowInit.DriverPackName) {
	$DriverPackCombo.SelectedValue = $global:OSDCloudWorkflowInit.DriverPackName
}
else {
	$DriverPackCombo.SelectedIndex = 0
}

#================================================
# Optional Settings
$RestartActionCombo = $window.FindName("RestartActionCombo")
$AWZoneTextBox = $window.FindName("AWZoneTextBox")

$RestartActionOptions = @('Restart','Shutdown','Exit')
$RestartActionCombo.ItemsSource = $RestartActionOptions

$RestartActionDefault = if ($global:OSDCloudWorkflowInit.RestartAction) {
	$global:OSDCloudWorkflowInit.RestartAction
} else {
	'Exit'
}

if ($RestartActionDefault -and ($RestartActionOptions -contains $RestartActionDefault)) {
	$RestartActionCombo.SelectedItem = $RestartActionDefault
} else {
	$RestartActionCombo.SelectedIndex = 0
}

if ($AWZoneTextBox) {
	$AWZoneTextBox.Text = if ($global:OSDCloudWorkflowInit.ApplicationWorkspaceZone) {
		[string]$global:OSDCloudWorkflowInit.ApplicationWorkspaceZone
	} else {
		[string]::Empty
	}
}
#================================================
# Other Settings
$ComputerManufacturerText = $window.FindName("ComputerManufacturerText")
$ComputerManufacturerText.Text = $ComputerManufacturer
$ComputerModelText = $window.FindName("ComputerModelText")
$ComputerModelText.Text = $ComputerModel
$ComputerProductText = $window.FindName("ComputerProductText")
$ComputerProductText.Text = $ComputerProduct
$ComputerSystemSKUNumberText = $window.FindName("ComputerSystemSKUNumberText")
$ComputerSystemSKUNumberText.Text = $ComputerSystemSKUNumber
$SerialNumberText = $window.FindName("SerialNumberText")
$SerialNumberText.Text = $SerialNumber
$TotalMemoryText = $window.FindName("TotalMemoryText")
$TotalMemoryText.Text = if ($global:OSDCloudWorkflowDevice.TotalPhysicalMemoryGB) {
	"$($global:OSDCloudWorkflowDevice.TotalPhysicalMemoryGB) GB"
} else {
	'Unknown'
}

$SetupCompleteTextBox = $window.FindName("SetupCompleteTextBox")
$setupCompleteValue = [string]$global:OSDCloudWorkflowInit.SetupCompleteCmd
if ($SetupCompleteTextBox) {
	$SetupCompleteTextBox.Text = if (-not [string]::IsNullOrWhiteSpace($setupCompleteValue)) {
		$setupCompleteValue
	} else {
		[string]::Empty
	}
}

$SelectedOSLanguageText = $window.FindName("SelectedOSLanguageText")
$SelectedIdText = $window.FindName("SelectedIdText")
$SelectedFileNameText = $window.FindName("SelectedFileNameText")
$DriverPackUrlText = $window.FindName("DriverPackUrlText")
$DriverPackUrlText.Text = [string]$global:OSDCloudWorkflowInit.DriverPackObject.Url
$StartButton = $window.FindName("StartButton")
$StartButton.IsEnabled = $false

$SummaryOsNameText = $window.FindName('SummaryOsNameText')
$SummaryOsEditionText = $window.FindName('SummaryOsEditionText')
$SummaryOsActivationText = $window.FindName('SummaryOsActivationText')
$SummaryOsLanguageText = $window.FindName('SummaryOsLanguageText')
$SummaryOsFileText = $window.FindName('SummaryOsFileText')
$SummaryDeviceUUIDText = $window.FindName('SummaryDeviceUUIDText')
$SummaryDeviceManufacturerText = $window.FindName('SummaryDeviceManufacturerText')
$SummaryDeviceModelText = $window.FindName('SummaryDeviceModelText')
$SummaryDeviceSerialText = $window.FindName('SummaryDeviceSerialText')
$SummaryDeviceMemoryText = $window.FindName('SummaryDeviceMemoryText')
$SummaryTaskSequenceText = $window.FindName('SummaryTaskSequenceText')
$SummaryDriverPackText = $window.FindName('SummaryDriverPackText')
$SummaryDriverPackUrlText = $window.FindName('SummaryDriverPackUrlText')
$DiskCombo = $window.FindName('DiskCombo')

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

function Update-Summary {
	if (-not $SummaryOsNameText) {
		return
	}

	$osObject = $global:OSDCloudWorkflowInit.OperatingSystemObject
	$SummaryOsNameText.Text = if ($osObject) { [string]$osObject.OperatingSystem } else { 'Not selected' }
	$SummaryOsEditionText.Text = if ($OSEditionCombo) { Get-ComboValue -ComboBox $OSEditionCombo } else { '-' }
	$SummaryOsActivationText.Text = if ($OSActivationCombo) { Get-ComboValue -ComboBox $OSActivationCombo } else { '-' }
	$SummaryOsLanguageText.Text = if ($osObject -and $osObject.OSLanguageCode) { [string]$osObject.OSLanguageCode } elseif ($OSLanguageCodeCombo) { Get-ComboValue -ComboBox $OSLanguageCodeCombo } else { '-' }
	$SummaryOsFileText.Text = if ($osObject) { [string]$osObject.FileName } else { '-' }

	$SummaryDeviceUUIDText.Text = if (-not [string]::IsNullOrWhiteSpace($UUID)) { $UUID } else { 'Unknown' }
	$SummaryDeviceManufacturerText.Text = if (-not [string]::IsNullOrWhiteSpace($ComputerManufacturer)) { $ComputerManufacturer } else { 'Unknown' }
	$SummaryDeviceModelText.Text = if (-not [string]::IsNullOrWhiteSpace($ComputerModel)) { $ComputerModel } else { 'Unknown' }
	$SummaryDeviceSerialText.Text = if (-not [string]::IsNullOrWhiteSpace($SerialNumber)) { $SerialNumber } else { 'Unknown' }
	$SummaryDeviceMemoryText.Text = if ($global:OSDCloudWorkflowDevice.TotalPhysicalMemoryGB) { "$($global:OSDCloudWorkflowDevice.TotalPhysicalMemoryGB) GB" } else { 'Unknown' }

	if ($SummaryDriverPackText) {
		$driverPackValue = [string]$DriverPackCombo.SelectedItem
		$SummaryDriverPackText.Text = if (-not [string]::IsNullOrWhiteSpace($driverPackValue)) { $driverPackValue } else { 'None' }
	}
	if ($SummaryDriverPackUrlText) {
		$SummaryDriverPackUrlText.Text = if ($DriverPackUrlText) { [string]$DriverPackUrlText.Text } else { 'None' }
	}
}

function Set-StartButtonState {
	$StartButton.IsEnabled = ($null -ne $global:OSDCloudWorkflowInit.OperatingSystemObject)
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

    $global:OSDCloudWorkflowInit.OperatingSystemObject = $global:PSOSDCloudOperatingSystems | `
		Where-Object { $_.OperatingSystem -match $updateOperatingSystem } | `
		Where-Object { $_.OSActivation -eq $updateOSActivation } | `
		Where-Object { $_.OSLanguageCode -eq $updateOSLanguageCode } | Select-Object -First 1
	
    if (-not $global:OSDCloudWorkflowInit.OperatingSystemObject) {
        throw "No Operating System found for OperatingSystem: $updateOperatingSystem, OSActivation: $updateOSActivation, OSLanguageCode: $updateOSLanguageCode. Please check your OSDCloud OperatingSystems."
    }

	$script:SelectedImage = $global:OSDCloudWorkflowInit.OperatingSystemObject

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

	Update-Summary

	Set-StartButtonState
}

function Update-DriverPackResults {
	$DriverPackName = Get-ComboValue -ComboBox $DriverPackCombo
	$global:OSDCloudWorkflowInit.DriverPackName = $DriverPackName
	$global:OSDCloudWorkflowInit.DriverPackObject = $global:OSDCloudWorkflowInit.DriverPackValues | Where-Object { $_.Name -eq $DriverPackName }
	$DriverPackUrlText.Text = [string]$global:OSDCloudWorkflowInit.DriverPackObject.Url
	Update-Summary
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
	$OSDCloudWorkflowName = $TaskSequenceCombo.SelectedValue
	$OSDCloudWorkflowObject = $global:OSDCloudWorkflowInit.Flows | Where-Object { $_.Name -eq $OSDCloudWorkflowName } | Select-Object -First 1
	$OperatingSystemObject = $global:OSDCloudWorkflowInit.OperatingSystemObject
	$OSEditionId = $global:OSDCloudWorkflowInit.OSEditionValues | Where-Object { $_.Edition -eq $OSEditionCombo.SelectedValue } | Select-Object -ExpandProperty EditionId
	#================================================
	# Global Variables
	$global:OSDCloudWorkflowInit.WorkflowName = $OSDCloudWorkflowName
	$global:OSDCloudWorkflowInit.WorkflowObject = $OSDCloudWorkflowObject
	# $global:OSDCloudWorkflowInit.DriverPackName = $DriverPackName
	# $global:OSDCloudWorkflowInit.DriverPackObject = $DriverPackObject
	# DriverPackValues
	# Flows
	# Function
	$global:OSDCloudWorkflowInit.ImageFileName = $OperatingSystemObject.FileName
	$global:OSDCloudWorkflowInit.ImageFileUrl = $OperatingSystemObject.FilePath
	# LaunchMethod
	# Module
	$global:OSDCloudWorkflowInit.OperatingSystemObject = $OperatingSystemObject
	$global:OSDCloudWorkflowInit.OperatingSystem = $OperatingSystemObject.OSName
	$global:OSDCloudWorkflowInit.OSActivation = $OperatingSystemObject.OSActivation
	# OSActivationValues
	# OSArchitecture
	$global:OSDCloudWorkflowInit.OSBuild = $OperatingSystemObject.OSBuild
	# OSBuildVersion
	$global:OSDCloudWorkflowInit.OSEdition = Get-ComboValue -ComboBox $OSEditionCombo
	$global:OSDCloudWorkflowInit.OSEditionId = $OSEditionId
	# OSEditionValues
	$global:OSDCloudWorkflowInit.OSLanguageCode = $OperatingSystemObject.OSLanguageCode
	# OSLanguageValues
	$global:OSDCloudWorkflowInit.OperatingSystem = $OperatingSystemObject.OperatingSystem
	# OperatingSystemValues
	$global:OSDCloudWorkflowInit.OSVersion = $OperatingSystemObject.OSVersion
	$global:OSDCloudWorkflowInit.TimeStart = (Get-Date)
	$global:OSDCloudWorkflowInit.LocalImageFileInfo = $LocalImageFileInfo
	$global:OSDCloudWorkflowInit.LocalImageFilePath = $LocalImageFilePath
	$global:OSDCloudWorkflowInit.LocalImageName = $LocalImageName
	$global:OSDCloudWorkflowInit.RestartAction = Get-ComboValue -ComboBox $RestartActionCombo

	if ([string]::IsNullOrWhiteSpace($AWDeploymentTextBox.Text)) {
		$global:OSDCloudWorkflowInit.ApplicationWorkspaceDeployment = $null
		$global:OSDCloudWorkflowInit.ApplicationWorkspaceZone = $null
	} else {
		$global:OSDCloudWorkflowInit.ApplicationWorkspaceDeployment = $AWDeploymentTextBox.Text.Trim()
	}

	if ([string]::IsNullOrWhiteSpace($AWZoneTextBox.Text)) {
		$global:OSDCloudWorkflowInit.ApplicationWorkspaceDeployment = $null
		$global:OSDCloudWorkflowInit.ApplicationWorkspaceZone = $null
	} else {
		$global:OSDCloudWorkflowInit.ApplicationWorkspaceZone = $AWZoneTextBox.Text.Trim()
	}

	if ($SetupCompleteTextBox) {
		$global:OSDCloudWorkflowInit.SetupCompleteCmd = $SetupCompleteTextBox.Text
	}

    $LogsPath = "$env:TEMP\osdcloud-logs"
    if (-not (Test-Path -Path $LogsPath)) {
        New-Item -Path $LogsPath -ItemType Directory -Force | Out-Null
    }
	$global:OSDCloudWorkflowInit | Out-File -FilePath "$LogsPath\OSDCloudWorkflowInit.txt" -Force
}

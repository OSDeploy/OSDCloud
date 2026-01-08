<#!
.SYNOPSIS
	Interactive picker for OSDCloud operating system catalog entries.
#>
[CmdletBinding()]
param(
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[System.String]$OSCatalogPath
)
#================================================
Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase
#================================================
# Import the OS Catalog
$OSCatalog = $global:PSOSDCloudOperatingSystems

# Import the Custom OS Catalog
if ($OSCatalogPath) {
	$resolvedCatalogPath = [System.IO.Path]::GetFullPath($OSCatalogPath)
	if (-not (Test-Path -LiteralPath $resolvedCatalogPath)) {
		throw "Catalog file not found at '$resolvedCatalogPath'."
	}

	try {
		$OSCatalog = Get-Content -LiteralPath $resolvedCatalogPath -Raw | ConvertFrom-Json -ErrorAction Stop
	} catch {
		throw "Unable to load '$resolvedCatalogPath'. $($_.Exception.Message)"
	}

	if (-not $OSCatalog) {
		throw "Catalog '$resolvedCatalogPath' did not return any items."
	}
}
#================================================
# Variables
$Architecture = $global:OSDCloudWorkflowGather.IsAutopilotReady
$BiosReleaseDate = $global:OSDCloudWorkflowGather.BiosReleaseDate
$BiosVersion = $global:OSDCloudWorkflowGather.BiosVersion
$ChassisTypeChassisType = $global:OSDCloudWorkflowGather.ChassisTypeChassisType
$ComputerManufacturer = $global:OSDCloudWorkflowInit.ComputerManufacturer
$ComputerModel = $global:OSDCloudWorkflowInit.ComputerModel
$ComputerProduct = $global:OSDCloudWorkflowInit.ComputerProduct
$ComputerSystemSKUNumber = $global:OSDCloudWorkflowGather.ComputerSystemSKUNumber
$IsAutopilotReady = $global:OSDCloudWorkflowGather.IsAutopilotReady
$IsTpmReady = $global:OSDCloudWorkflowGather.IsTpmReady
$SerialNumber = $global:OSDCloudWorkflowGather.SerialNumber
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
#================================================
# TaskSequence
$TaskSequenceCombo = $window.FindName("TaskSequenceCombo")
$TaskSequenceCombo.ItemsSource = $global:OSDCloudWorkflowInit.Flows.Name
$TaskSequenceCombo.SelectedIndex = 0
#================================================
# OperatingSystemValues
# GlobalVariable Configuration
# Environment Configuration
# Workflow Configuration
if ($global:OSDCloudWorkflowInit.OperatingSystemValues) {
	$OperatingSystemValues = $global:OSDCloudWorkflowInit.OperatingSystemValues
	Write-Verbose "Workflow OperatingSystemValues = $OperatingSystemValues"
}
# Catalog Configuration
else {
	$OperatingSystemValues = $OSCatalog.OperatingSystem | Sort-Object -Unique | Sort-Object -Descending
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
	$OSLanguageCodeValues = $OSCatalog.OSLanguageCode | Sort-Object -Unique | Sort-Object -Descending
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
$DriverPackCombo.SelectedValue = $global:OSDCloudWorkflowInit.DriverPackName
#================================================
# Optional Settings
$RestartActionCombo = $window.FindName("RestartActionCombo")
$WorkspaceUrlTextBox = $window.FindName("WorkspaceUrlTextBox")

$RestartActionOptions = @('Restart','Shutdown','Exit')
$RestartActionCombo.ItemsSource = $RestartActionOptions

$RestartActionDefault = if ($global:OSDCloudWorkflowInit.RestartAction) {
	$global:OSDCloudWorkflowInit.RestartAction
} else {
	'Restart'
}

<#
if ($RestartActionDefault -and ($RestartActionOptions -contains $RestartActionDefault)) {
	$RestartActionCombo.SelectedItem = $RestartActionDefault
} else {
	$RestartActionCombo.SelectedIndex = 0
}

$WorkspaceUrlTextBox.Text = if ($global:OSDCloudWorkflowInit.ApplicationWorkspaceUrl) {
	[string]$global:OSDCloudWorkflowInit.ApplicationWorkspaceUrl
} else {
	[string]::Empty
}

#>
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
$TotalMemoryText.Text = if ($global:OSDCloudWorkflowGather.TotalPhysicalMemoryGB) {
	"$($global:OSDCloudWorkflowGather.TotalPhysicalMemoryGB) GB"
} else {
	'Unknown'
}

$Win32TpmTextBox = $window.FindName("Win32TpmTextBox")
$Win32TpmTextBox.Text = if ($global:OSDCloudWorkflowGather.Win32Tpm) {
	$global:OSDCloudWorkflowGather.Win32Tpm | Out-String
} else {
	'Win32Tpm data is not available.'
}

$NetworkInformationTextBox = $window.FindName("NetworkInformationTextBox")
$NetworkInformationTextBox.Text = if ($global:OSDCloudWorkflowGather.NetworkAdapter) {
	ipconfig | Out-String
} else {
	'Network information is not available.'
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
$DriverPackUrlText.Text = [string]$global:OSDCloudWorkflowInit.ObjectDriverPack.Url
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
	$StartButton.IsEnabled = ($null -ne $script:SelectedImage)
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
	} elseif ($Item.OSLanguageCode) {
		[string]$Item.OSLanguageCode
	} else {
		'-'
	}
	$SelectedFileNameText.Text = [string]$Item.FileName
}

function Update-OsResults {
	# Keep filtering logic centralized so every control refreshes the same view.
	$osgroup = Get-ComboValue -ComboBox $OperatingSystemCombo
	$edition = Get-ComboValue -ComboBox $OSEditionCombo
	$activation = Get-ComboValue -ComboBox $OSActivationCombo
	$language = Get-ComboValue -ComboBox $OSLanguageCodeCombo

	$filtered = $OSCatalog | Where-Object {
		($null -eq $osgroup -or $_.OperatingSystem -eq $osgroup) -and
		($null -eq $activation -or $_.OSActivation -eq $activation) -and
		($null -eq $language -or $_.OSLanguageCode -eq $language)
	} | Sort-Object Id

	if ($filtered.Count -gt 0) {
		$script:SelectedImage = $filtered[0]
	} else {
		$script:SelectedImage = $null
	}

	if ($edition -match 'Home') {
		$OSActivationCombo.SelectedValue = 'Retail'
		$OSActivationCombo.IsEnabled = $false
	}
	if ($edition -match 'Education') {
		$OSActivationCombo.IsEnabled = $true
	}
	if ($edition -match 'Enterprise') {
		$OSActivationCombo.SelectedValue = 'Volume'
		$OSActivationCombo.IsEnabled = $false
	}
	if ($edition -match 'Pro') {
		$OSActivationCombo.IsEnabled = $true
	}

	Update-SelectedDetails -Item $script:SelectedImage

	Set-StartButtonState
}

function Update-DriverPackResults {
	$DriverPackName = Get-ComboValue -ComboBox $DriverPackCombo
	$global:OSDCloudWorkflowInit.DriverPackName = $DriverPackName
	$global:OSDCloudWorkflowInit.ObjectDriverPack = $global:OSDCloudWorkflowInit.DriverPackValues | Where-Object { $_.Name -eq $DriverPackName }

	$DriverPackUrlText.Text = [string]$global:OSDCloudWorkflowInit.ObjectDriverPack.Url
}

$OperatingSystemCombo.Add_SelectionChanged({ Update-OsResults })
$OSEditionCombo.Add_SelectionChanged({ Update-OsResults })
$OSActivationCombo.Add_SelectionChanged({ Update-OsResults })
$OSLanguageCodeCombo.Add_SelectionChanged({ Update-OsResults })

$DriverPackCombo.Add_SelectionChanged({ Update-DriverPackResults })

$script:SelectedImage = $null
$script:SelectionConfirmed = $false

$StartButton.Add_Click({
	$selection = $script:SelectedImage
	if (-not $selection) {
		[System.Windows.MessageBox]::Show('No catalog entry is available. Adjust the filters and try again.', 'OSDCloud', 'OK', 'Information') | Out-Null
		return
	}

	$script:SelectedImage = $selection
	$script:SelectionConfirmed = $true
	$window.DialogResult = $true
	$window.Close()
})

Update-OsResults

$null = $window.ShowDialog()

if ($script:SelectionConfirmed -and $script:SelectedImage) {
	#================================================
	# Local Variables
	$OSDCloudWorkflowName = $TaskSequenceCombo.SelectedValue
	$OSDCloudWorkflowObject = $global:OSDCloudWorkflowInit.Flows | Where-Object { $_.Name -eq $OSDCloudWorkflowName } | Select-Object -First 1
	$ObjectOperatingSystem = $script:SelectedImage
	$OSEditionId = $global:OSDCloudWorkflowInit.OSEditionValues | Where-Object { $_.Edition -eq $OSEditionCombo.SelectedValue } | Select-Object -ExpandProperty OSEditionId
	#================================================
	# Global Variables
	$global:OSDCloudWorkflowInit.WorkflowName = $OSDCloudWorkflowName
	$global:OSDCloudWorkflowInit.WorkflowObject = $OSDCloudWorkflowObject
	# $global:OSDCloudWorkflowInit.DriverPackName = $DriverPackName
	# $global:OSDCloudWorkflowInit.ObjectDriverPack = $ObjectDriverPack
	# DriverPackValues
	# Flows
	# Function
	$global:OSDCloudWorkflowInit.ImageFileName = $ObjectOperatingSystem.FileName
	$global:OSDCloudWorkflowInit.ImageFileUrl = $ObjectOperatingSystem.FilePath
	# LaunchMethod
	# Module
	$global:OSDCloudWorkflowInit.ObjectOperatingSystem = $ObjectOperatingSystem
	$global:OSDCloudWorkflowInit.OperatingSystem = $ObjectOperatingSystem.OSName
	$global:OSDCloudWorkflowInit.OSActivation = $ObjectOperatingSystem.OSActivation
	# OSActivationValues
	# OSArchitecture
	$global:OSDCloudWorkflowInit.OSBuild = $ObjectOperatingSystem.OSBuild
	# OSBuildVersion
	$global:OSDCloudWorkflowInit.OSEdition = Get-ComboValue -ComboBox $OSEditionCombo
	$global:OSDCloudWorkflowInit.OSEditionId = $OSEditionId
	# OSEditionValues
	$global:OSDCloudWorkflowInit.OSLanguageCode = $ObjectOperatingSystem.OSLanguageCode
	# OSLanguageValues
	$global:OSDCloudWorkflowInit.OperatingSystem = $ObjectOperatingSystem.OperatingSystem
	# OperatingSystemValues
	$global:OSDCloudWorkflowInit.OSVersion = $ObjectOperatingSystem.OSVersion
	$global:OSDCloudWorkflowInit.TimeStart = (Get-Date)
	$global:OSDCloudWorkflowInit.LocalImageFileInfo = $LocalImageFileInfo
	$global:OSDCloudWorkflowInit.LocalImageFilePath = $LocalImageFilePath
	$global:OSDCloudWorkflowInit.LocalImageName = $LocalImageName
	$global:OSDCloudWorkflowInit.RestartAction = Get-ComboValue -ComboBox $RestartActionCombo
	$workspaceUrl = $WorkspaceUrlTextBox.Text
	if ([string]::IsNullOrWhiteSpace($workspaceUrl)) {
		$global:OSDCloudWorkflowInit.ApplicationWorkspaceUrl = $null
	} else {
		$global:OSDCloudWorkflowInit.ApplicationWorkspaceUrl = $workspaceUrl.Trim()
	}
	if ($SetupCompleteTextBox) {
		$global:OSDCloudWorkflowInit.SetupCompleteCmd = $SetupCompleteTextBox.Text
	}
}

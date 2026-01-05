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
$OSCatalog = $global:OSDCloudWorkflowOSCatalog

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
#================================================
# Menu Items
$OpenCmdMenuItem = $window.FindName("OpenCmdMenuItem")
$OpenPowerShellMenuItem = $window.FindName("OpenPowerShellMenuItem")
$AboutMenuItem = $window.FindName("AboutMenuItem")

$OpenCmdMenuItem.Add_Click({
	try {
		Start-Process -FilePath "cmd.exe"
	} catch {
		[System.Windows.MessageBox]::Show("Failed to open CMD Prompt: $($_.Exception.Message)", "Error", "OK", "Error") | Out-Null
	}
})

$OpenPowerShellMenuItem.Add_Click({
	try {
		Start-Process -FilePath "powershell.exe"
	} catch {
		[System.Windows.MessageBox]::Show("Failed to open PowerShell: $($_.Exception.Message)", "Error", "OK", "Error") | Out-Null
	}
})

$AboutMenuItem.Add_Click({
	$aboutMessage = @"
OSDCloud - Community Edition
Placeholder help content will go here. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec in turpis nec leo fermentum interdum.
"@
	[System.Windows.MessageBox]::Show($aboutMessage, "About OSDCloud", "OK", "Information") | Out-Null
})
#================================================
# TaskSequence
$TaskSequenceCombo = $window.FindName("TaskSequenceCombo")
$TaskSequenceCombo.ItemsSource = $global:OSDCloudWorkflowInit.Flows.Name
$TaskSequenceCombo.SelectedIndex = 0
#================================================
# OSGroupValues
# GlobalVariable Configuration
# Environment Configuration
# Workflow Configuration
if ($global:OSDCloudWorkflowInit.OSGroupValues) {
	$OSGroupValues = $global:OSDCloudWorkflowInit.OSGroupValues
	Write-Verbose "Workflow OSGroupValues = $OSGroupValues"
}
# Catalog Configuration
else {
	$OSGroupValues = $OSCatalog.OSGroup | Sort-Object -Unique | Sort-Object -Descending
	Write-Verbose "Catalog OSGroupValues = $OSGroupValues"
}
$OSGroupCombo = $window.FindName("OSGroupCombo")
$OSGroupCombo.ItemsSource = $OSGroupValues
#================================================
# OSGroupDefault
if ($global:OSDCloudWorkflowInit.OSGroup) {
	$OSGroupDefault = $global:OSDCloudWorkflowInit.OSGroup
	Write-Verbose "Workflow OSGroup = $OSGroupDefault"
}
if ($OSGroupDefault -and ($OSGroupValues -contains $OSGroupDefault)) {
	$OSGroupCombo.SelectedItem = $OSGroupDefault
} elseif ($OSGroupValues) {
	$OSGroupCombo.SelectedIndex = 0
} else {
	$OSGroupCombo.SelectedIndex = -1
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
} elseif ($OSGroupValues) {
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
# OSLanguageValues
# GlobalVariable Configuration
# Environment Configuration
# Workflow Configuration
if ($global:OSDCloudWorkflowInit.OSLanguageValues) {
	$OSLanguageValues = $global:OSDCloudWorkflowInit.OSLanguageValues
	Write-Verbose "Workflow OSLanguageValues = $OSLanguageValues"
}
# Catalog Configuration
else {
	$OSLanguageValues = $OSCatalog.OSGroup | Sort-Object -Unique | Sort-Object -Descending
	Write-Verbose "Catalog OSLanguageValues = $OSLanguageValues"
}
$LanguageCodeCombo = $window.FindName("LanguageCodeCombo")
$LanguageCodeCombo.ItemsSource = $OSLanguageValues
#================================================
# OSLanguageDefault
if ($global:OSDCloudWorkflowInit.OSLanguage) {
	$OSLanguageDefault = $global:OSDCloudWorkflowInit.OSLanguage
	Write-Verbose "Workflow OSLanguage = $OSLanguageDefault"
}
if ($OSLanguageDefault -and ($OSLanguageValues -contains $OSLanguageDefault)) {
	$LanguageCodeCombo.SelectedItem = $OSLanguageDefault
} elseif ($LanguageCodeValues) {
	$LanguageCodeCombo.SelectedIndex = 0
} else {
	$LanguageCodeCombo.SelectedIndex = -1
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

$SelectedLanguageText = $window.FindName("SelectedLanguageText")
$SelectedIdText = $window.FindName("SelectedIdText")
$SelectedFileNameText = $window.FindName("SelectedFileNameText")
$DriverPackUrlText = $window.FindName("DriverPackUrlText")
$DriverPackUrlText.Text = [string]$global:OSDCloudWorkflowInit.DriverPackObject.Url
$ResultStatusText = $window.FindName("ResultStatusText")
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
		$SelectedLanguageText.Text = '-'
		$SelectedFileNameText.Text = '-'
		return
	}

	$SelectedIdText.Text = [string]$Item.Id
	$SelectedLanguageText.Text = if ($Item.Language) {
		[string]$Item.Language
	} elseif ($Item.LanguageCode) {
		[string]$Item.LanguageCode
	} else {
		'-'
	}
	$SelectedFileNameText.Text = [string]$Item.FileName
}

function Update-OsResults {
	# Keep filtering logic centralized so every control refreshes the same view.
	$group = Get-ComboValue -ComboBox $OSGroupCombo
	$edition = Get-ComboValue -ComboBox $OSEditionCombo
	$activation = Get-ComboValue -ComboBox $OSActivationCombo
	$language = Get-ComboValue -ComboBox $LanguageCodeCombo

	$filtered = $OSCatalog | Where-Object {
		($null -eq $group -or $_.OSGroup -eq $group) -and
		($null -eq $activation -or $_.OSActivation -eq $activation) -and
		($null -eq $language -or $_.LanguageCode -eq $language)
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

	$ResultStatusText.Text = if ($filtered.Count -gt 0) {
		#('Showing {0} of {1} matching image{2}' -f 1, $filtered.Count, $(if ($filtered.Count -eq 1) { '' } else { 's' }))
	} else {
		#'No matching images for the selected filters.'
	}

	Set-StartButtonState
}

function Update-DriverPackResults {
	$DriverPackName = Get-ComboValue -ComboBox $DriverPackCombo
	$global:OSDCloudWorkflowInit.DriverPackName = $DriverPackName
	$global:OSDCloudWorkflowInit.DriverPackObject = $global:OSDCloudWorkflowInit.DriverPackValues | Where-Object { $_.Name -eq $DriverPackName }

	$DriverPackUrlText.Text = [string]$global:OSDCloudWorkflowInit.DriverPackObject.Url
}

$OSGroupCombo.Add_SelectionChanged({ Update-OsResults })
$OSEditionCombo.Add_SelectionChanged({ Update-OsResults })
$OSActivationCombo.Add_SelectionChanged({ Update-OsResults })
$LanguageCodeCombo.Add_SelectionChanged({ Update-OsResults })

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
	$OperatingSystemObject = $script:SelectedImage
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
	$global:OSDCloudWorkflowInit.OSLanguage = $OperatingSystemObject.LanguageCode
	# OSLanguageValues
	$global:OSDCloudWorkflowInit.OSGroup = $OperatingSystemObject.OSGroup
	# OSGroupValues
	$global:OSDCloudWorkflowInit.OSVersion = $OperatingSystemObject.OSVersion
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
}

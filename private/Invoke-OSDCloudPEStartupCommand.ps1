function Invoke-OSDCloudPEStartupCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.String]
        $Command,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Normal', 'Minimized', 'Maximized', 'Hidden')]
        [System.String]
        $WindowStyle = 'Normal',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Asynchronous', 'Synchronous')]
        [System.String]
        $Run = 'Synchronous',

		[switch]
		$NoExit,

		[switch]
		$Wait
	)
    #=================================================
    $Error.Clear()
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Start"
    #=================================================
	# https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-setup-runasynchronous
	# https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-setup-runsynchronous

	if ($NoExit) {
		$PSNoExit = '-NoExit '
	} else {
		$PSNoExit = $null
	}

$Unattend = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
	<settings pass="windowsPE">
		<component name="Microsoft-Windows-Setup" processorArchitecture="amd64"
			publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
			xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
			xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<Run$($Run)>
				<Run$($Run)Command wcm:action="add">
					<Order>1</Order>
					<Description>$Command</Description>
					<Path>powershell.exe -NoLogo -NoProfile -WindowStyle $WindowStyle $PSNoExit-Command $Command</Path>
				</Run$($Run)Command>
			</Run$($Run)>
		</component>
		<component name="Microsoft-Windows-Setup" processorArchitecture="arm64"
			publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS"
			xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
			xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<Run$($Run)>
				<Run$($Run)Command wcm:action="add">
					<Order>1</Order>
					<Description>$Command</Description>
					<Path>powershell.exe -NoLogo -NoProfile -WindowStyle $WindowStyle $PSNoExit-Command $Command</Path>
				</Run$($Run)Command>
			</Run$($Run)>
		</component>
	</settings>
</unattend>
"@

	$Unattend | Out-File -FilePath "$env:Temp\$Command.xml" -Encoding utf8 -Force

	if ($Wait -and $NoExit) {
		Write-Host -ForegroundColor Yellow "[$(Get-Date -format G)] This window may need to be closed to continue the WinPE startup process"
	}

	if ($Wait) {
		Start-Process -FilePath wpeinit -Wait -ArgumentList "-unattend:$env:Temp\$Command.xml"
	} else {
		Start-Process -FilePath wpeinit -ArgumentList "-unattend:$env:Temp\$Command.xml"
	}
    #=================================================
    Write-Verbose "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Done"
    #=================================================
}
function step-install-downloadwindowsimage {
    [CmdletBinding()]
    param (
        $OperatingSystemObject = $global:OSDCloudWorkflowInvoke.OperatingSystemObject
    )
    #=================================================
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message
    $Step = $global:OSDCloudCurrentStep
    #=================================================
    # Is there an OperatingSystem Object?
    if (-not ($OperatingSystemObject)) {
        Write-Warning "[$(Get-Date -format s)] OperatingSystemObject is not set."
        Write-Warning 'Press Ctrl+C to exit OSDCloud'
        Start-Sleep -Seconds 86400
        exit
    }
    #=================================================
    # Is there a FilePath?
    if (-not ($OperatingSystemObject.FilePath)) {
        Write-Warning "[$(Get-Date -format s)] OperatingSystemObject does not have a FilePath to validate."
        Write-Warning 'Press Ctrl+C to exit OSDCloud'
        Start-Sleep -Seconds 86400
        exit
    }
    #=================================================
    # Is it reachable online?
    $IsOnline = $false
    try {
        $WebRequest = Invoke-WebRequest -Uri $OperatingSystemObject.FilePath -UseBasicParsing -Method Head
        if ($WebRequest.StatusCode -eq 200) {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] OperatingSystemObject FilePath returned a 200 status code. OK."
            $IsOnline = $true
        }
    }
    catch {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] OperatingSystemObject FilePath is not reachable."
    }
    #=================================================
    # Does the file exist on a Drive?
    $IsOffline = $false
    $FileName = $OperatingSystemObject.FileName
    $MatchingFiles = @()
    $MatchingFiles = Get-PSDrive -PSProvider FileSystem | ForEach-Object {
        Get-ChildItem "$($_.Name):\OSDCloud\OS\" -Include "$FileName" -File -Recurse -Force -ErrorAction Ignore
    }
    
    if ($MatchingFiles) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] OperatingSystemObject is available offline. OK."
        $IsOffline = $true
    }
    else {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] OperatingSystemObject is not available offline."
    }
    #=================================================
    # Nothing to do if it is unavailable online and offline
    if ($IsOnline -eq $false -and $IsOffline -eq $false) {
        Write-Warning "[$(Get-Date -format s)] OperatingSystemObject is not available online or offline."
        Write-Warning 'Press Ctrl+C to exit OSDCloud'
        Start-Sleep -Seconds 86400
        exit
    }
    #=================================================
    # Create Download Directory
    $DownloadPath = "C:\OSDCloud\OS"
    $ItemParams = @{
        ErrorAction = 'SilentlyContinue'
        Force       = $true
        ItemType    = 'Directory'
        Path        = $DownloadPath
    }
    if (!(Test-Path $ItemParams.Path -ErrorAction SilentlyContinue)) {
        New-Item @ItemParams | Out-Null
    }
    #=================================================
    # Is there a USB drive available?
    $USBDrive = Get-DeviceUSBVolume | Where-Object { ($_.FileSystemLabel -match "OSDCloud|USB-DATA") } | `
                Where-Object { $_.SizeGB -ge 16 } | Where-Object { $_.SizeRemainingGB -ge 10 } | Select-Object -First 1
    
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] $($OperatingSystemObject.FilePath)"
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] FileName: $FileName"

    if ($USBDrive) {
        $USBDownloadPath = "$($USBDrive.DriveLetter):\OSDCloud\OS\$($OperatingSystemObject.OperatingSystem)"
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] DownloadPath: $USBDownloadPath"

        if (-not (Test-Path $USBDownloadPath)) {
            $null = New-Item -Path $USBDownloadPath -ItemType Directory -Force
        }
        $SaveWebFile = OSDCloud-DownloadFile -SourceUrl $OperatingSystemObject.FilePath -DestinationDirectory "$USBDownloadPath" -DestinationName $FileName

        if ($SaveWebFile) {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Copy Offline OS to $DownloadPath"
            $null = Copy-Item -Path $SaveWebFile.FullName -Destination $DownloadPath -Force
            $FileInfo = Get-Item "$DownloadPath\$($SaveWebFile.Name)"
        }
    }
    else {
        # $SaveWebFile is a FileInfo Object, not a path
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] DownloadPath: $DownloadPath"
        $SaveWebFile = OSDCloud-DownloadFile -SourceUrl $OperatingSystemObject.FilePath -DestinationDirectory $DownloadPath -ErrorAction Stop
        $FileInfo = $SaveWebFile
    }
    #=================================================
    # Do we have FileInfo for the downloaded file?
    if (-not ($FileInfo)) {
        Write-Warning "[$(Get-Date -format s)] Unable to download the WindowsImage from the Internet."
        Write-Warning 'Press Ctrl+C to exit OSDCloud'
        Start-Sleep -Seconds 86400
        exit
    }
    #=================================================
    # Store this as a FileInfo Object
    $global:OSDCloudWorkflowInvoke.FileInfoWindowsImage = $FileInfo
    $global:OSDCloudWorkflowInvoke.WindowsImagePath = $global:OSDCloudWorkflowInvoke.FileInfoWindowsImage.FullName
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] WindowsImagePath:  $($global:OSDCloudWorkflowInvoke.WindowsImagePath)"
    #=================================================
    # Check the File Hash
    if ($OperatingSystemObject.Sha1) {
        $FileHash = (Get-FileHash -Path $FileInfo.FullName -Algorithm SHA1).Hash
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Microsoft Verified ESD SHA1: $($OperatingSystemObject.Sha1)"
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Downloaded ESD SHA1: $FileHash"

        if ($OperatingSystemObject.Sha1 -notmatch $FileHash) {
            Write-Warning "[$(Get-Date -format s)] Unable to deploy this Operating System."
            Write-Warning "[$(Get-Date -format s)] Downloaded ESD SHA1 does not match the verified Microsoft ESD SHA1."
            Write-Warning 'Press Ctrl+C to exit OSDCloud'
            Start-Sleep -Seconds 86400
        }
        else {
            Write-Host -ForegroundColor Green "[$(Get-Date -format s)] Downloaded ESD SHA1 matches the verified Microsoft ESD SHA1. OK."
        }
    }
    if ($OperatingSystemObject.Sha256) {
        $FileHash = (Get-FileHash -Path $FileInfo.FullName -Algorithm SHA256).Hash
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Microsoft Verified ESD SHA256: $($OperatingSystemObject.Sha256)"
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Downloaded ESD SHA256: $FileHash"

        if ($OperatingSystemObject.Sha256 -notmatch $FileHash) {
            Write-Warning "[$(Get-Date -format s)] Unable to deploy this Operating System."
            Write-Warning "[$(Get-Date -format s)] Downloaded ESD SHA256 does not match the verified Microsoft ESD SHA256."
            Write-Warning 'Press Ctrl+C to exit OSDCloud'
            Start-Sleep -Seconds 86400
        }
        else {
            Write-Host -ForegroundColor Green "[$(Get-Date -format s)] Downloaded ESD SHA256 matches the verified Microsoft ESD SHA256. OK."
        }
    }
    #=================================================
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
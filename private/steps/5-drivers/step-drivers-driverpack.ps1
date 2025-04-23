function step-drivers-driverpack {
    [CmdletBinding()]
    param (
        [System.String]
        $DriverPackName = $global:OSDCloudWorkflowInvoke.DriverPackName,

        [System.String]
        $DriverPackGuid = $global:OSDCloudWorkflowInvoke.DriverPackObject.Guid,

        $DriverPackObject = $global:OSDCloudWorkflowInvoke.DriverPackObject
    )
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSvDCloudWorkflowCurrentStep
    #=================================================
    # Is DriverPackName set to None?
    if ($DriverPackName -eq 'None') {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] DriverPackName is set to None. OK."
        return
    }
    #=================================================
    # Is DriverPackName set to Microsoft Update Catalog?
    if ($DriverPackName -eq 'Microsoft Update Catalog') {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] DriverPackName is set to Microsoft Update Catalog. OK."
        return
    }
    #=================================================
    # Is there a DriverPack Object?
    if (-not ($DriverPackObject)) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] DriverPackObject is not set. OK."
        return
    }
    #=================================================
    # Is there a DriverPack Guid?
    if (-not ($DriverPackGuid)) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] DriverPackObject.GUID is not set. OK."
        return
    }
    #=================================================
    # Is there a URL?
    if (-not $($DriverPackObject.Url)) {
        Write-Warning "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] DriverPackObject does not have a Url to validate."
        Write-Warning 'Press Ctrl+C to cancel OSDCloud'
        Start-Sleep -Seconds 86400
        exit
    }
    #=================================================
    # Is it reachable online?
    $IsOnline = $false
    try {
        $WebRequest = Invoke-WebRequest -Uri $DriverPackObject.Url -UseBasicParsing -Method Head
        if ($WebRequest.StatusCode -eq 200) {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] DriverPack URL returned a 200 status code. OK."
            $IsOnline = $true
        }
    }
    catch {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] DriverPack URL is not reachable."
    }
    #=================================================
    # Does the file exist on a Drive?
    $IsOffline = $false
    $FileName = Split-Path $DriverPackObject.Url -Leaf
    $MatchingFiles = @()
    $MatchingFiles = Get-PSDrive -PSProvider FileSystem | ForEach-Object {
        Get-ChildItem "$($_.Name):\OSDCloud\DriverPacks\" -Include "$FileName" -File -Recurse -Force -ErrorAction Ignore
    }
    
    if ($MatchingFiles) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] DriverPack is available offline. OK."
        $IsOffline = $true
    }
    else {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] DriverPack is not available offline."
    }
    #=================================================
    # Nothing to do if it is unavailable online and offline
    if ($IsOnline -eq $false -and $IsOffline -eq $false) {
        Write-Warning "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] DriverPack is not available online or offline. Continue."
        return
    }
    #=================================================
    # Example DriverPackObject
    <#
        CatalogVersion : 25.04.11
        Status         :
        ReleaseDate    : 24.09.23
        Manufacturer   : HP
        Model          : ZBook Firefly 16 inch G11 Mobile Workstation PC
        Legacy         :
        Product        : 8cd1
        Name           : HP ZBook Firefly 16 inch G11 Mobile Workstation PC Win11 24H2 sp155206
        PackageID      : sp155206
        FileName       : sp155206.exe
        Url            : https://ftp.hp.com/pub/softpaq/sp155001-155500/sp155206.exe
        OS             : Windows 11 x64
        OSReleaseId    : 24H2
        OSBuild        : 26100
        OSArchitecture : amd64
        HashMD5        : 862E812233F66654AFF1A1D2246644A5
        Guid           : e9ee2f88-5aa5-407b-935e-274b39be7c2b
    #>
    #=================================================
    # Variables
    $ScriptsPath = "C:\Windows\Setup\Scripts"
    $SetupCompleteCmd = "$ScriptsPath\SetupComplete.cmd"
    $SetupSpecializeCmd = "C:\Windows\Temp\osdcloud\SetupSpecialize.cmd"
    $Manufacturer = $DriverPackObject.Manufacturer
    $FileName = $DriverPackObject.FileName
    $Url = $DriverPackObject.Url
    #=================================================
    # Create DownloadPath Directory
    $DownloadPath = "C:\Windows\Temp\osdcloud\drivers-driverpack-$Manufacturer"
    $Params = @{
        ErrorAction = 'SilentlyContinue'
        Force       = $true
        ItemType    = 'Directory'
        Path        = $DownloadPath
    }
    if (!(Test-Path $Params.Path -ErrorAction SilentlyContinue)) {
        New-Item @Params | Out-Null
    }
    #=================================================
    # Is there a USB drive available?
    $USBDrive = Get-USBVolume | Where-Object { ($_.FileSystemLabel -match "OSDCloud|USB-DATA") } | Where-Object { $_.SizeGB -ge 16 } | Where-Object { $_.SizeRemainingGB -ge 10 } | Select-Object -First 1

    if ($USBDrive) {
        $USBDownloadPath = "$($USBDrive.DriveLetter):\OSDCloud\DriverPacks\$Manufacturer"
        $FileName = Split-Path $DriverPackObject.Url -Leaf

        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Url: $($DriverPackObject.Url)"
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] USBDownloadPath: $USBDownloadPath"
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] FileName: $FileName"

        # Download the file
        if (-not (Test-Path $USBDownloadPath)) {
            $null = New-Item -Path $USBDownloadPath -ItemType Directory -Force
        }
        $SaveWebFile = Save-WebFile -SourceUrl $DriverPackObject.Url -DestinationDirectory "$USBDownloadPath" -DestinationName $FileName

        if ($SaveWebFile) {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Copying Offline DriverPack to $DownloadPath"
            $null = Copy-Item -Path $SaveWebFile.FullName -Destination $DownloadPath -Force
            $FileInfo = Get-Item "$DownloadPath\$($SaveWebFile.Name)"
        }
    }
    else {
        # $SaveWebFile is a FileInfo Object, not a path
        if (-not (Test-Path $DownloadPath)) {
            $null = New-Item -Path $DownloadPath -ItemType Directory -Force
        }
        $SaveWebFile = Save-WebFile -SourceUrl $DriverPackObject.Url -DestinationDirectory $DownloadPath -ErrorAction Stop
        $FileInfo = $SaveWebFile
    }
    #=================================================
    # Verify download
    $OutFileObject = Get-Item $FileInfo.FullName

    if (! (Test-Path $OutFileObject)) {
        Write-Warning "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Unable to download $Url"
        return
    }

    $DriverPackObject | ConvertTo-Json | Out-File "$($OutFileObject.FullName).json" -Encoding ascii -Width 2000 -Force
    
    $DownloadedFile = $OutFileObject.FullName
    $ExpandPath = 'C:\Windows\Temp\osdcloud\drivers-driverpack'
    if (-NOT (Test-Path "$ExpandPath")) {
        New-Item $ExpandPath -ItemType Directory -Force -ErrorAction Ignore | Out-Null
    }
    Write-Host -ForegroundColor DarkGray "DriverPack: $DownloadedFile"
    #=================================================
    #   Cab
    #=================================================
    if ($OutFileObject.Extension -eq '.cab') {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Expanding CAB DriverPack to $ExpandPath"
        Expand -R "$DownloadedFile" -F:* "$ExpandPath" | Out-Null
        return
    }
    #=================================================
    #   Zip
    #=================================================
    if ($OutFileObject.Extension -eq '.zip') {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Expanding ZIP DriverPack to $ExpandPath"
        Expand-Archive -Path $DownloadedFile -DestinationPath $ExpandPath -Force
        return
    }
    #=================================================
    #   Dell
    #=================================================
    if ($OutFileObject.Extension -eq '.exe') {
        if ($OutFileObject.VersionInfo.FileDescription -match 'Dell') {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Expanding Dell DriverPack to $ExpandPath"
            Write-Host -ForegroundColor DarkGray "FileDescription: $($OutFileObject.VersionInfo.FileDescription)"
            Write-Host -ForegroundColor DarkGray "ProductVersion: $($OutFileObject.VersionInfo.ProductVersion)"
            $null = New-Item -Path $ExpandPath -ItemType Directory -Force -ErrorAction Ignore | Out-Null
            Start-Process -FilePath $DownloadedFile -ArgumentList "/s /e=`"$ExpandPath`"" -Wait
            return
        }
    }
    #=================================================
    #   HP
    #=================================================
    if ($OutFileObject.Extension -eq '.exe') {
        if ($OutFileObject.VersionInfo.InternalName -match 'hpsoftpaqwrapper') {
            Write-Host -ForegroundColor DarkGray "FileDescription: $($OutFileObject.VersionInfo.FileDescription)"
            Write-Host -ForegroundColor DarkGray "InternalName: $($OutFileObject.VersionInfo.InternalName)"
            Write-Host -ForegroundColor DarkGray "OriginalFilename: $($OutFileObject.VersionInfo.OriginalFilename)"
            Write-Host -ForegroundColor DarkGray "ProductVersion: $($OutFileObject.VersionInfo.ProductVersion)"
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Expanding HP DriverPack to $ExpandPath"
            # Start-Process -FilePath $DownloadedFile -ArgumentList "/s /e /f `"$ExpandPath`"" -Wait
            & 7za x "$($OutFileObject.FullName)" -o"C:\Windows\Temp\osdcloud\drivers-driverpack"
            return
        }
    }
    #=================================================
    #   Lenovo
    #=================================================
    if (($Manufacturer -eq 'Lenovo') -and (Test-Path $DownloadPath)) {
        if (-not (Test-Path $ScriptsPath)) {
            New-Item -Path $ScriptsPath -ItemType Directory -Force -ErrorAction Ignore | Out-Null
        }
        Write-Host -ForegroundColor DarkGray "FileDescription: $($OutFileObject.VersionInfo.FileDescription)"
        Write-Host -ForegroundColor DarkGray "ProductVersion: $($OutFileObject.VersionInfo.ProductVersion)"
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Adding Lenovo DriverPack to $SetupCompleteCmd"

$Content = @"
:: ========================================================
:: OSDCloud DriverPack Installation for Lenovo
:: ========================================================
$DownloadedFile /SILENT /SUPPRESSMSGBOXES
robocopy C:\Drivers $ExpandPath *.* /e /move /ndl /nfl /r:0 /w:0
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" /v Path /t REG_SZ /d "$ExpandPath" /f
pnpunattend.exe AuditSystem /L
rd /s /q C:\Drivers
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" /v Path /f
:: ========================================================
"@
        $Content | Out-File -FilePath $SetupSpecializeCmd -Append -Encoding ascii -Width 2000 -Force

        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Adding Provisioning Package for SetupSpecialize"
        $ProvisioningPackage = Join-Path $(Get-OSvDCloudModulePath) "content\setup-specialize\setupspecialize.ppkg"

        if (Test-Path $ProvisioningPackage) {
            Write-Host -ForegroundColor DarkGray "dism.exe /Image=C:\ /Add-ProvisioningPackage /PackagePath:`"$ProvisioningPackage`""
            $Dism = "dism.exe"
            $ArgumentList = "/Image=C:\ /Add-ProvisioningPackage /PackagePath:`"$ProvisioningPackage`""
            $null = Start-Process -FilePath 'dism.exe' -ArgumentList $ArgumentList -Wait -NoNewWindow
        }
    }
    #=================================================
    #   Surface
    #=================================================
    if (($Manufacturer -eq 'Microsoft') -and (Test-Path $DownloadedFile)) {
        if (-not (Test-Path $ScriptsPath)) {
            New-Item -Path $ScriptsPath -ItemType Directory -Force -ErrorAction Ignore | Out-Null
        }
        Write-Host -ForegroundColor DarkGray "FileDescription: $($OutFileObject.VersionInfo.FileDescription)"
        Write-Host -ForegroundColor DarkGray "ProductVersion: $($OutFileObject.VersionInfo.ProductVersion)"
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Adding Surface DriverPack to $SetupCompleteCmd"

$Content = @"
:: ========================================================
:: OSDCloud DriverPack Installation for Microsoft Surface
:: ========================================================
msiexec /i $DownloadedFile /qn /norestart /l*v C:\Windows\Temp\osdcloud-logs\drivers-driverpack-microsoft.log
:: ========================================================
"@
        $Content | Out-File -FilePath $SetupCompleteCmd -Append -Encoding ascii -Width 2000 -Force
    }
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
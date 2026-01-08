function step-drivers-driverpack {
    [CmdletBinding()]
    param (
        [System.String]
        $DriverPackName = $global:OSDCloudWorkflowInvoke.DriverPackName,

        [System.String]
        $DriverPackGuid = $global:OSDCloudWorkflowInvoke.ObjectDriverPack.Guid,

        $ObjectDriverPack = $global:OSDCloudWorkflowInvoke.ObjectDriverPack
    )
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format s)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudWorkflowCurrentStep
    #=================================================
    # Is DriverPackName set to None?
    if ($DriverPackName -eq 'None') {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] DriverPackName is set to None. OK."
        return
    }
    #=================================================
    # Is DriverPackName set to Microsoft Update Catalog?
    if ($DriverPackName -eq 'Microsoft Update Catalog') {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] DriverPackName is set to Microsoft Update Catalog. OK."
        return
    }
    #=================================================
    # Is there a DriverPack Object?
    if (-not ($ObjectDriverPack)) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] ObjectDriverPack is not set. OK."
        return
    }
    #=================================================
    # Is there a DriverPack Guid?
    if (-not ($DriverPackGuid)) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] ObjectDriverPack.GUID is not set. OK."
        return
    }
    #=================================================
    # Is there a URL?
    if (-not $($ObjectDriverPack.Url)) {
        Write-Warning "[$(Get-Date -format s)] ObjectDriverPack does not have a Url to validate."
        Write-Warning 'Press Ctrl+C to cancel OSDCloud'
        Start-Sleep -Seconds 86400
        exit
    }
    #=================================================
    # Is it reachable online?
    $IsOnline = $false
    try {
        $WebRequest = Invoke-WebRequest -Uri $ObjectDriverPack.Url -UseBasicParsing -Method Head
        if ($WebRequest.StatusCode -eq 200) {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] DriverPack URL returned a 200 status code. OK."
            $IsOnline = $true
        }
    }
    catch {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] DriverPack URL is not reachable."
    }
    #=================================================
    # Does the file exist on a Drive?
    $IsOffline = $false
    $FileName = Split-Path $ObjectDriverPack.Url -Leaf
    $MatchingFiles = @()
    $MatchingFiles = Get-PSDrive -PSProvider FileSystem | ForEach-Object {
        Get-ChildItem "$($_.Name):\OSDCloud\DriverPacks\" -Include "$FileName" -File -Recurse -Force -ErrorAction Ignore
    }
    
    if ($MatchingFiles) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] DriverPack is available offline. OK."
        $IsOffline = $true
    }
    else {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] DriverPack is not available offline."
    }
    #=================================================
    # Nothing to do if it is unavailable online and offline
    if ($IsOnline -eq $false -and $IsOffline -eq $false) {
        Write-Warning "[$(Get-Date -format s)] DriverPack is not available online or offline. Continue."
        return
    }
    #=================================================
    # Example ObjectDriverPack
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
    $FileName = $ObjectDriverPack.FileName
    $LogPath = "C:\Windows\Temp\osdcloud-logs"
    $Manufacturer = $ObjectDriverPack.Manufacturer
    $ScriptsPath = "C:\Windows\Setup\Scripts"
    $SetupCompleteCmd = "$ScriptsPath\SetupComplete.cmd"
    $SetupSpecializeCmd = "C:\Windows\Temp\osdcloud\SetupSpecialize.cmd"
    $Url = $ObjectDriverPack.Url
    #=================================================
    # Create DownloadPath Directory
    $DownloadPath = "C:\Windows\Temp\osdcloud-driverpack-download"
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
        $FileName = Split-Path $ObjectDriverPack.Url -Leaf

        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Url: $($ObjectDriverPack.Url)"
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] USBDownloadPath: $USBDownloadPath"
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] FileName: $FileName"

        # Download the file
        if (-not (Test-Path $USBDownloadPath)) {
            $null = New-Item -Path $USBDownloadPath -ItemType Directory -Force
        }
        $SaveWebFile = Save-WebFile -SourceUrl $ObjectDriverPack.Url -DestinationDirectory "$USBDownloadPath" -DestinationName $FileName

        if ($SaveWebFile) {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Copying Offline DriverPack to $DownloadPath"
            $null = Copy-Item -Path $SaveWebFile.FullName -Destination $DownloadPath -Force
            $FileInfo = Get-Item "$DownloadPath\$($SaveWebFile.Name)"
        }
    }
    else {
        # $SaveWebFile is a FileInfo Object, not a path
        if (-not (Test-Path $DownloadPath)) {
            $null = New-Item -Path $DownloadPath -ItemType Directory -Force
        }
        $SaveWebFile = Save-WebFile -SourceUrl $ObjectDriverPack.Url -DestinationDirectory $DownloadPath -ErrorAction Stop
        $FileInfo = $SaveWebFile
    }
    #=================================================
    # Verify download
    $OutFileObject = Get-Item $FileInfo.FullName

    if (! (Test-Path $OutFileObject)) {
        Write-Warning "[$(Get-Date -format s)] Unable to download $Url"
        return
    }

    $ObjectDriverPack | ConvertTo-Json | Out-File "$($OutFileObject.FullName).json" -Encoding ascii -Width 2000 -Force
    
    $DownloadedFile = $OutFileObject.FullName
    $ExpandPath = 'C:\Windows\Temp\osdcloud-driverpack-expand'
    if (-not (Test-Path "$ExpandPath")) {
        New-Item $ExpandPath -ItemType Directory -Force -ErrorAction Ignore | Out-Null
    }
    Write-Host -ForegroundColor DarkGray "DriverPack: $DownloadedFile"
    #=================================================
    #   Cab
    #=================================================
    if ($OutFileObject.Extension -eq '.cab') {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Expand CAB DriverPack to $ExpandPath"
        Expand -R "$DownloadedFile" -F:* "$ExpandPath" | Out-Null

        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Applying drivers in $ExpandPath"
        Add-WindowsDriver -Path "C:\" -Driver $ExpandPath -Recurse -ForceUnsigned -LogPath "$LogPath\drivers-driverpack.log" -ErrorAction SilentlyContinue | Out-Null

        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Removing C:\Windows\Temp\osdcloud-driverpack-download"
        Remove-Item -Path "C:\Windows\Temp\osdcloud-driverpack-download" -Recurse -Force -ErrorAction SilentlyContinue
        
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Removing $ExpandPath"
        Remove-Item -Path $ExpandPath -Recurse -Force -ErrorAction SilentlyContinue
        
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Removing C:\Drivers"
        Remove-Item -Path "C:\Drivers" -Recurse -Force -ErrorAction SilentlyContinue
        return
    }
    #=================================================
    #   Zip
    #=================================================
    if ($OutFileObject.Extension -eq '.zip') {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Expand ZIP DriverPack to $ExpandPath"
        Expand-Archive -Path $DownloadedFile -DestinationPath $ExpandPath -Force

        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Applying drivers in $ExpandPath"
        Add-WindowsDriver -Path "C:\" -Driver $ExpandPath -Recurse -ForceUnsigned -LogPath "$LogPath\drivers-driverpack.log" -ErrorAction SilentlyContinue | Out-Null

        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Removing C:\Windows\Temp\osdcloud-driverpack-download"
        Remove-Item -Path "C:\Windows\Temp\osdcloud-driverpack-download" -Recurse -Force -ErrorAction SilentlyContinue

        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Removing $ExpandPath"
        Remove-Item -Path $ExpandPath -Recurse -Force -ErrorAction SilentlyContinue
        
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Removing C:\Drivers"
        Remove-Item -Path "C:\Drivers" -Recurse -Force -ErrorAction SilentlyContinue
        return
    }
    #=================================================
    #   Dell
    #=================================================
    if (($OutFileObject.Extension -eq '.exe') -and ($OutFileObject.VersionInfo.FileDescription -match 'Dell')) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] FileDescription: $($OutFileObject.VersionInfo.FileDescription)"
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] ProductVersion: $($OutFileObject.VersionInfo.ProductVersion)"

        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Expand Dell DriverPack to $ExpandPath"
        $null = New-Item -Path $ExpandPath -ItemType Directory -Force -ErrorAction Ignore | Out-Null
        Start-Process -FilePath $DownloadedFile -ArgumentList "/s /e=`"$ExpandPath`"" -Wait

        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Applying drivers in $ExpandPath"
        Add-WindowsDriver -Path "C:\" -Driver $ExpandPath -Recurse -ForceUnsigned -LogPath "$LogPath\drivers-driverpack.log" -ErrorAction SilentlyContinue | Out-Null

        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Removing C:\Windows\Temp\osdcloud-driverpack-download"
        Remove-Item -Path "C:\Windows\Temp\osdcloud-driverpack-download" -Recurse -Force -ErrorAction SilentlyContinue
        
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Removing $ExpandPath"
        Remove-Item -Path $ExpandPath -Recurse -Force -ErrorAction SilentlyContinue
        
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Removing C:\Drivers"
        Remove-Item -Path "C:\Drivers" -Recurse -Force -ErrorAction SilentlyContinue
        return
    }
    #=================================================
    #   HP
    #=================================================
    if (($OutFileObject.Extension -eq '.exe') -and ($OutFileObject.VersionInfo.InternalName -match 'hpsoftpaqwrapper')) {
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] FileDescription: $($OutFileObject.VersionInfo.FileDescription)"
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] InternalName: $($OutFileObject.VersionInfo.InternalName)"
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] ProductVersion: $($OutFileObject.VersionInfo.ProductVersion)"

        if (Test-Path -Path $env:windir\System32\7za.exe) {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Expand HP DriverPack to $ExpandPath"
            # Start-Process -FilePath $DownloadedFile -ArgumentList "/s /e /f `"$ExpandPath`"" -Wait
            & 7za x "$DownloadedFile" -o"C:\Windows\Temp\osdcloud-driverpack-expand"

            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Applying drivers in $ExpandPath"
            Add-WindowsDriver -Path "C:\" -Driver $ExpandPath -Recurse -ForceUnsigned -LogPath "$LogPath\drivers-driverpack.log" -ErrorAction SilentlyContinue | Out-Null

            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Removing C:\Windows\Temp\osdcloud-driverpack-download"
            Remove-Item -Path "C:\Windows\Temp\osdcloud-driverpack-download" -Recurse -Force -ErrorAction SilentlyContinue
            
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Removing $ExpandPath"
            Remove-Item -Path $ExpandPath -Recurse -Force -ErrorAction SilentlyContinue

            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Removing C:\Drivers"
            Remove-Item -Path "C:\Drivers" -Recurse -Force -ErrorAction SilentlyContinue
        }
        else {
            Write-Warning "[$(Get-Date -format s)] 7zip 7za.exe needs to be added to WinPE to expand HP DriverPacks"
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] HP DriverPack is saved at $DownloadedFile"

            Remove-Item -Path $ExpandPath -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "C:\Drivers" -Recurse -Force -ErrorAction SilentlyContinue
        }
        return
    }
    #=================================================
    #   Lenovo
    #=================================================
    if (($OutFileObject.Extension -eq '.exe') -and ($ObjectDriverPack.Manufacturer -match 'Lenovo')) {
        if (-not (Test-Path $ScriptsPath)) {
            New-Item -Path $ScriptsPath -ItemType Directory -Force -ErrorAction Ignore | Out-Null
        }
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Adding Lenovo DriverPack to $SetupCompleteCmd"

$Content = @"
:: ========================================================
:: OSDCloud DriverPack Installation for Lenovo
:: ========================================================
$DownloadedFile /SILENT /SUPPRESSMSGBOXES
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" /v Path /t REG_SZ /d "C:\Drivers" /f
pnpunattend.exe AuditSystem /L
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" /v Path /f
rd /s /q C:\Drivers
rd /s /q C:\Windows\Temp\osdcloud-driverpack-download
:: ========================================================
"@
        $Content | Out-File -FilePath $SetupCompleteCmd -Append -Encoding ascii -Width 2000 -Force
        Remove-Item -Path $ExpandPath -Recurse -Force -ErrorAction SilentlyContinue
        return

        <#
        # Write-Host -ForegroundColor DarkGray "FileDescription: $($OutFileObject.VersionInfo.FileDescription)"
        # Write-Host -ForegroundColor DarkGray "ProductVersion: $($OutFileObject.VersionInfo.ProductVersion)"
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Adding Lenovo DriverPack to $SetupSpecializeCmd"

$Content = @"
:: ========================================================
:: OSDCloud DriverPack Installation for Lenovo
:: ========================================================
$DownloadedFile /SILENT /SUPPRESSMSGBOXES
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" /v Path /t REG_SZ /d "C:\Drivers" /f
pnpunattend.exe AuditSystem /L
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" /v Path /f
rd /s /q C:\Drivers
rd /s /q C:\Windows\Temp\osdcloud-driverpack-download
:: ========================================================
"@

        $SetupSpecializePath = "C:\Windows\Temp\osdcloud"
        $Params = @{
            ErrorAction = 'SilentlyContinue'
            Force       = $true
            ItemType    = 'Directory'
            Path        = $SetupSpecializePath
        }
        if (!(Test-Path $Params.Path -ErrorAction SilentlyContinue)) {
            New-Item @Params | Out-Null
        }

        $Content | Out-File -FilePath $SetupSpecializeCmd -Append -Encoding ascii -Width 2000 -Force

        $ProvisioningPackage = Join-Path $(Get-OSDCloudModulePath) "core\setupspecialize\setupspecialize.ppkg"

        if (Test-Path $ProvisioningPackage) {
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Adding Provisioning Package for SetupSpecialize"
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] dism.exe /Image=C:\ /Add-ProvisioningPackage /PackagePath:`"$ProvisioningPackage`""
            $ArgumentList = "/Image=C:\ /Add-ProvisioningPackage /PackagePath:`"$ProvisioningPackage`""
            $null = Start-Process -FilePath 'dism.exe' -ArgumentList $ArgumentList -Wait -NoNewWindow
        }

        Remove-Item -Path $ExpandPath -Recurse -Force -ErrorAction SilentlyContinue
        return
        #>
    }
    #=================================================
    #   Surface
    #=================================================
    if (($OutFileObject.Extension -eq '.msi') -and ($OutFileObject.Name -match 'surface')) {
        if (-not (Test-Path $ScriptsPath)) {
            New-Item -Path $ScriptsPath -ItemType Directory -Force -ErrorAction Ignore | Out-Null
        }
        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Adding Surface DriverPack to $SetupCompleteCmd"

$Content = @"
:: ========================================================
:: OSDCloud DriverPack Installation for Microsoft Surface
:: ========================================================
msiexec /i $DownloadedFile /qn /norestart /l*v C:\Windows\Temp\osdcloud-logs\drivers-driverpack-microsoft.log
rd /s /q C:\Windows\Temp\osdcloud-driverpack-download
:: ========================================================
"@
        $Content | Out-File -FilePath $SetupCompleteCmd -Append -Encoding ascii -Width 2000 -Force
        Remove-Item -Path $ExpandPath -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "C:\Drivers" -Recurse -Force -ErrorAction SilentlyContinue
        return
    }
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
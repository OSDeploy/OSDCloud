function step-drivers-recast-winre {
    [CmdletBinding()]
    param ()
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudCurrentStep
    #=================================================
    $LogPath = "C:\Windows\Temp\osdcloud-logs"

    $DriverPath = "C:\Windows\Temp\osdcloud-drivers-recast"

    $WinrePath = "C:\Windows\System32\Recovery\winre.wim"
    $WinreMountPath = "C:\Windows\Temp\mount-winre"

    if ((Test-Path -Path $DriverPath) -and (Test-Path -Path $WinrePath)) {
        if (-not (Test-Path -Path $LogPath)) {
            New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
        }
        if (-not (Test-Path -Path $WinreMountPath)) {
            New-Item -ItemType Directory -Path $WinreMountPath -Force | Out-Null
        }

        $Params = @{
            Path        = $WinreMountPath
            ImagePath   = $WinrePath
            Index       = 1
            LogPath     = "$LogPath\mount-winre.log"
        }
        $MountWinRE = Mount-WindowsImage @Params | Out-Null

        if ($MountWinRE) {
            Add-WindowsDriver -Path $WinreMountPath -Driver "$DriverPath" -Recurse -ForceUnsigned -LogPath "$LogPath\drivers-recast-winre.log" -ErrorAction SilentlyContinue
        }

        Dismount-WindowsImage -Path $WinreMountPath -Save -LogPath "$LogPath\dismount-winre.log" -ErrorAction SilentlyContinue | Out-Null

        if (Test-Path -Path $WinreMountPath) {
            Remove-Item -Path $WinreMountPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
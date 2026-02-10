function step-install-expandwindowsimage {
    [CmdletBinding()]
    param ()
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudTaskCurrentStep
    #=================================================
    #region Main
    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] C:\"
    #=================================================
    #   Create ScratchDirectory
    $Params = @{
        ErrorAction = 'SilentlyContinue'
        Force       = $true
        ItemType    = 'Directory'
        Path        = 'C:\OSDCloud\Temp'
    }
    if (-not (Test-Path $Params.Path -ErrorAction SilentlyContinue)) {
        New-Item @Params | Out-Null
    }
    #=================================================
    # Build the Params
    if ($global:OSDCloudInitialize.LocalImageFileDestination.FullName -match '.swm') {
        #TODO - Add support for multiple SWM files
        $Params = @{
            ApplyPath             = 'C:\'
            ErrorAction           = 'Stop'
            ImagePath             = $global:OSDCloudInitialize.LocalImageFileDestination.FullName
            Name                  = (Get-WindowsImage -ImagePath $global:OSDCloudInitialize.LocalImageFileDestination.FullName).ImageName
            ScratchDirectory      = 'C:\OSDCloud\Temp'
            SplitImageFilePattern = ($global:OSDCloudInitialize.LocalImageFileDestination.FullName).replace('install.swm', 'install*.swm')
        }
    }
    else {
        $Params = @{
            ApplyPath        = 'C:\'
            ErrorAction      = 'Stop'
            ImagePath        = $global:OSDCloudWorkflowInvoke.WindowsImagePath
            Index            = $global:OSDCloudWorkflowInvoke.WindowsImageIndex
            ScratchDirectory = 'C:\OSDCloud\Temp'
        }
    }

    $global:OSDCloudWorkflowInvoke.ParamsExpandWindowsImage = $Params
    #=================================================
    # Expand WindowsImage
    if ($IsWinPE -eq $true) {
        try {
            Expand-WindowsImage @Params | Out-Null
        }
        catch {
            Write-Warning "[$(Get-Date -format s)] Expand-WindowsImage failed."
            Write-Warning "[$(Get-Date -format s)] $_"
            Write-Warning 'Press Ctrl+C to cancel OSDCloud'
            Start-Sleep -Seconds 86400
            exit
        }
    }
    #=================================================
    # Remove OS after expanding the image
    $Params = @{
        ErrorAction = 'SilentlyContinue'
        Force       = $true
        Path        = 'C:\OSDCloud\Temp'
    }
    if (Test-Path $Params.Path -ErrorAction SilentlyContinue) {
        Remove-Item @Params | Out-Null
    }
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
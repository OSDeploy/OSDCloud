function step-install-getwindowsimageindex {
    <#
        .SYNOPSIS
        First, verify the WindowsImage to ensure that it is valid for deployment.
        Second, determine the ImageIndex to expand, or to allow the user to select the ImageIndex.

        .INPUTS
        $global:OSDCloudWorkflowInvoke.FileInfoWindowsImage
        Contains the FileInfo object of the WindowsImage to be expanded.
        This variable was created step-install-downloadwindowsimage

        $global:OSDCloudWorkflowInvoke.FileInfoWindowsImage.FullName
        Contains the FullName of the WindowsImage to be expanded.
        This variable was created by step-install-downloadwindowsimage

        $global:OSDCloudWorkflowFrontend.OSEditionId
        Contains the EditionId of the WindowsImage to be expanded.
        This property may not exist and is created by the Frontend.

        $global:OSDCloudWorkflowFrontend.LocalImageName
        Contains the ImageName of the WindowsImage to be expanded.
        This property may not exist and is created by the Frontend.

        .OUTPUTS
        $global:OSDCloudWorkflowInvoke.WindowsImageIndex
        Contains the ImageIndex of the WindowsImage to be expanded.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [System.String]
        $ImagePath = $global:OSDCloudWorkflowInvoke.FileInfoWindowsImage.FullName,

        [Parameter(Mandatory = $false)]
        [System.String]
        $EditionId = $global:OSDCloudWorkflowFrontend.OSEditionId,

        [Parameter(Mandatory = $false)]
        [System.String]
        $ImageName = $global:OSDCloudWorkflowFrontend.LocalImageName
    )
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSDCloudWorkflowCurrentStep
    #=================================================
    #region Do we have a WindowsImage to test?
    if ($null -eq $ImagePath) {
        Write-Warning "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] WindowsImage does not have an ImagePath."
        Write-Warning 'Press Ctrl+C to exit OSDCloud'
        Start-Sleep -Seconds 86400
        exit
    }
    #endregion
    #=================================================
    #region Does the Path exist?
    if (!(Test-Path $ImagePath)) {
        Write-Warning "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] WindowsImage does not exist at the ImagePath."
        Write-Warning $ImagePath
        Write-Warning 'Press Ctrl+C to exit OSDCloud'
        Start-Sleep -Seconds 86400
        exit
    }
    #endregion
    #=================================================
    #region Does Get-WindowsImage work?
    try {
        $WindowsImage = Get-WindowsImage -ImagePath $ImagePath -ErrorAction Stop
    }
    catch {
        Write-Warning "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Unable to verify the Windows Image using Get-WindowsImage."
        Write-Host -ForegroundColor DarkYellow "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] $_"
        Write-Warning 'Press Ctrl+C to exit OSDCloud'
        Start-Sleep -Seconds 86400
        exit
    }
    #endregion
    #=================================================
    #region Is there only one ImageIndex?
    $WindowsImageCount = ($WindowsImage).Count

    if ($WindowsImageCount -eq 1) {
        # Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] OSDCloud only found a single ImageIndex to expand"
        $global:OSDCloudWorkflowInvoke.WindowsImageIndex = 1
        return
    }
    #endregion
    #=================================================
    #region Get the ImageIndex of the ImageName
    if ($ImageName) {
        $ImageIndex = ($WindowsImage | Where-Object { $_.ImageName -eq $ImageName }).ImageIndex
        $global:OSDCloudWorkflowInvoke.WindowsImageIndex = $ImageIndex
        return
    }
    #endregion
    #=================================================
    #region Get the ImageIndex of the EditionId
    if ($EditionId) {
        $MatchingWindowsImage = $WindowsImage | `
            ForEach-Object { Get-WindowsImage -ImagePath $ImagePath -Index $_.ImageIndex } | `
            Where-Object { $_.EditionId -eq $EditionId }

        if ($MatchingWindowsImage -and $MatchingWindowsImage.Count -eq 1) {
            $global:OSDCloudWorkflowInvoke.WindowsImage = $MatchingWindowsImage
            $global:OSDCloudWorkflowInvoke.WindowsImageIndex = $MatchingWindowsImage.ImageIndex
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] EditionId $EditionId found at ImageIndex $($global:OSDCloudWorkflowInvoke.WindowsImageIndex)"
            return
        }
    }
    #endregion
    #=================================================
    #region Unable to determine which ImageIndex to apply, so prompt the user to select the ImageIndex
    Write-Host -ForegroundColor DarkCyan "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Select the WindowsImage to expand"
    $SelectWindowsImage = $WindowsImage | Where-Object { $_.ImageSize -gt 3000000000 }

    if ($SelectWindowsImage) {
        $SelectWindowsImage | Select-Object -Property ImageIndex, ImageName | Format-Table | Out-Host
    
        do {
            $SelectReadHost = Read-Host -Prompt 'Select an WindowsImage to expand by ImageIndex [Number]'
        }
        until (((($SelectReadHost -ge 0) -and ($SelectReadHost -in $SelectWindowsImage.ImageIndex))))
    
        $global:OSDCloudWorkflowInvoke.WindowsImageIndex = $SelectReadHost
        return
    }
    #endregion
    #=================================================
    #region Everything we tried failed, so exit OSDCloud
    Write-Warning "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Unable to determine the ImageIndex to apply."
    Write-Warning 'Press Ctrl+C to exit OSDCloud'
    Start-Sleep -Seconds 86400
    exit
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message; Write-Debug -Message $Message
    #=================================================
}
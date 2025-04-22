function step-install-getwindowsimageindex {
    <#
        .SYNOPSIS
        First, verify the WindowsImage to ensure that it is valid for deployment.
        Second, determine the ImageIndex to expand, or to allow the user to select the ImageIndex.

        .INPUTS
        $global:InvokeOSDCloudWorkflow.FileInfoWindowsImage
        Contains the FileInfo object of the WindowsImage to be expanded.
        This variable was created step-install-downloadwindowsimage

        $global:InvokeOSDCloudWorkflow.FileInfoWindowsImage.FullName
        Contains the FullName of the WindowsImage to be expanded.
        This variable was created by step-install-downloadwindowsimage

        $global:InitializeOSDCloudWorkflow.OSEditionId
        Contains the EditionId of the WindowsImage to be expanded.
        This property may not exist and is created by the Frontend.

        $global:InitializeOSDCloudWorkflow.LocalImageName
        Contains the ImageName of the WindowsImage to be expanded.
        This property may not exist and is created by the Frontend.

        .OUTPUTS
        $global:InvokeOSDCloudWorkflow.WindowsImageIndex
        Contains the ImageIndex of the WindowsImage to be expanded.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [System.String]
        $ImagePath = $global:InvokeOSDCloudWorkflow.FileInfoWindowsImage.FullName,

        [Parameter(Mandatory = $false)]
        [System.String]
        $EditionId = $global:InitializeOSDCloudWorkflow.OSEditionId,

        [Parameter(Mandatory = $false)]
        [System.String]
        $ImageName = $global:InitializeOSDCloudWorkflow.LocalImageName
    )
    #=================================================
    # Start the step
    $Message = "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] Start"
    Write-Debug -Message $Message; Write-Verbose -Message $Message

    # Get the configuration of the step
    $Step = $global:OSvDCloudWorkflowCurrentStep
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
        $global:InvokeOSDCloudWorkflow.WindowsImageIndex = 1
        return
    }
    #endregion
    #=================================================
    #region Get the ImageIndex of the ImageName
    if ($ImageName) {
        $ImageIndex = ($WindowsImage | Where-Object { $_.ImageName -eq $ImageName }).ImageIndex
        $global:InvokeOSDCloudWorkflow.WindowsImageIndex = $ImageIndex
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
            $global:InvokeOSDCloudWorkflow.WindowsImage = $MatchingWindowsImage
            $global:InvokeOSDCloudWorkflow.WindowsImageIndex = $MatchingWindowsImage.ImageIndex
            Write-Host -ForegroundColor DarkGray "[$(Get-Date -format G)][$($MyInvocation.MyCommand.Name)] EditionId $EditionId found at ImageIndex $($global:InvokeOSDCloudWorkflow.WindowsImageIndex)"
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
    
        $global:InvokeOSDCloudWorkflow.WindowsImageIndex = $SelectReadHost
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
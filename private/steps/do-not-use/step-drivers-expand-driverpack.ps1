function step-drivers-expand-driverpack {
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
    if ($global:OSDCloudWorkflowInvoke.DriverPackExpand) {
        $DriverPacks = Get-ChildItem -Path 'C:\Drivers' -File

        foreach ($Item in $DriverPacks) {
            $SaveMyDriverPack = $Item.FullName
            $ExpandFile = $Item.FullName
            Write-Verbose -Verbose "[$(Get-Date -format s)] DriverPack: $ExpandFile"
            #=================================================
            #   Cab
            #=================================================
            if ($Item.Extension -eq '.cab') {
                $DestinationPath = Join-Path $Item.Directory $Item.BaseName
        
                if (-not (Test-Path "$DestinationPath")) {
                    New-Item $DestinationPath -ItemType Directory -Force -ErrorAction Ignore | Out-Null
                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] DriverPack CAB is being expanded to $DestinationPath"
                    Expand -R "$ExpandFile" -F:* "$DestinationPath" | Out-Null
                }
                Continue
            }
            #=================================================
            #   Zip
            #=================================================
            if ($Item.Extension -eq '.zip') {
                $DestinationPath = Join-Path $Item.Directory $Item.BaseName
    
                if (-not (Test-Path "$DestinationPath")) {
                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] DriverPack ZIP is being expanded to $DestinationPath"
                    Expand-Archive -Path $ExpandFile -DestinationPath $DestinationPath -Force
                }
                Continue
            }
            #=================================================
            #   Dell Update Package
            #=================================================
            if ($Item.Extension -eq '.exe' -and $global:OSDCloudWorkflowInvoke.Manufacturer -eq 'Dell') {
                $DestinationPath = Join-Path $Item.Directory $Item.BaseName
                if (-not (Test-Path "$DestinationPath")) {
                    Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Dell Update Package is being expanded to $DestinationPath"
                    Start-Process -FilePath $ExpandFile -ArgumentList "/s /e=$DestinationPath" -Wait
                }
                Continue
            }
            #=================================================
            #   HP Softpaq
            #=================================================
            if ($global:OSDCloudWorkflowInvoke.Manufacturer -eq 'HP') {
                #If HP
                if ($Item.Extension -eq '.exe') {
                    #If found an EXE in c:\drivers
                    if (Test-Path -Path $env:windir\System32\7za.exe) {
                        #If 7zip is found
                        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Found 7zip, using to Expand HP Softpaq"
                        Write-Host "[$(Get-Date -format s)] SaveMyDriverPack: $SaveMyDriverPack"
                        Write-Host "[$(Get-Date -format s)] SaveMyDriverPack.FullName: $($SaveMyDriverPack.FullName)"
                        $DestinationPath = Join-Path $Item.Directory $Item.BaseName
                        if (-not (Test-Path "$DestinationPath")) {
                            #If DestinationPath does not exist already
                            Write-Host "[$(Get-Date -format s)] HP Driver Pack $ExpandFile is being expanded to $DestinationPath"
                            Start-Process -FilePath $env:windir\System32\7za.exe -ArgumentList "x $ExpandFile -o$DestinationPath -y" -Wait -NoNewWindow -PassThru
                            Write-Host "[$(Get-Date -format s)] 7zip has expanded the HP Driver Pack to $DestinationPath"
                            #$global:OSDCloudWorkflowInvoke.OSDCloudUnattend = $true
                            $DriverPPKGNeeded = $false #Disable PPKG for HP Driver Pack during Specialize
                            $global:OSDCloudWorkflowInvoke.DriverPackName = 'None' #Skips adding MS Update Catalog drivers into Process
                        }
                        Continue
                    }
                    else {
                        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] 7zip not found, unable to expand HP Softpaq"
                        Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] Please add 7zip your OSDCloud Boot Media to use this feature"
                    }
                }
            }
        }
    }
    #endregion
    #=================================================
    # End the function
    $Message = "[$(Get-Date -format s)] [$($MyInvocation.MyCommand.Name)] End"
    Write-Verbose -Message $Message;Write-Debug -Message $Message
    #=================================================
}
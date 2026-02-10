#region PoSHPF - Version 1.2
# Grab all resources (MahApps, etc), all XAML files, and any potential static resources
$global:resources = Get-ChildItem -Path "$PSScriptRoot\Resources\*.dll" -ErrorAction SilentlyContinue
$global:XAML = Get-ChildItem -Path "$PSScriptRoot\*.xaml" | Where-Object { $_.Name -ne 'App.xaml' } -ErrorAction SilentlyContinue #Changed path and exclude App.xaml
$global:MediaResources = Get-ChildItem -Path "$PSScriptRoot\Media" -ErrorAction SilentlyContinue

# This class allows the synchronized hashtable to be available across threads,
# but also passes a couple of methods along with it to do GUI things via the
# object's dispatcher.
class SyncClass {
    #Hashtable containing all forms/windows and controls - automatically created when newing up
    [hashtable]$SyncHash = [hashtable]::Synchronized(@{}) 
    
    # method to close the window - pass window name
    [void]CloseWindow($windowName) { 
        $this.SyncHash.$windowName.Dispatcher.Invoke([action] { $this.SyncHash.$windowName.Close() }, 'Normal') 
    }
    
    # method to update GUI - pass object name, property and value   
    [void]UpdateElement($object, $property, $value) { 
        $this.SyncHash.$object.Dispatcher.Invoke([action] { $this.SyncHash.$object.$property = $value }, 'Normal') 
    } 
}
$global:SyncClass = [SyncClass]::new() # create a new instance of this SyncClass to use.

###################
## Import Resources
###################
# Load WPF Assembly
Add-Type -assemblyName PresentationFramework

# Load Resources
foreach ($dll in $resources) { [System.Reflection.Assembly]::LoadFrom("$($dll.FullName)") | out-null }

##############
## Import XAML
##############
$xp = '[^a-zA-Z_0-9]' # All characters that are not a-Z, 0-9, or _
$vx = @()             # An array of XAML files loaded

foreach ($x in $XAML) { 
    # Items from XAML that are known to cause issues
    # when PowerShell parses them.
    $xamlToRemove = @(
        'mc:Ignorable="d"',
        "x:Class=`"(.*?)`"",
        "xmlns:local=`"(.*?)`""
    )

    $xaml = Get-Content $x.FullName # Load XAML
    $xaml = $xaml -replace 'x:N', 'N' # Rename x:Name to just Name (for consumption in variables later)
    foreach ($xtr in $xamlToRemove) { $xaml = $xaml -replace $xtr } # Remove items from $xamlToRemove
    
    # Create a new variable to store the XAML as XML
    New-Variable -Name "xaml$(($x.BaseName) -replace $xp, '_')" -Value ($xaml -as [xml]) -Force
    
    # Add XAML to list of XAML documents processed
    $vx += "$(($x.BaseName) -replace $xp, '_')"
}
#######################
## Add Media Resources
#######################
$imageFileTypes = @('.jpg', '.bmp', '.gif', '.tif', '.png') # Supported image filetypes
$avFileTypes = @('.mp3', '.wav', '.wmv') # Supported audio/visual filetypes
$xp = '[^a-zA-Z_0-9]' # All characters that are not a-Z, 0-9, or _
if ($MediaResources.Count -gt 0) {
    ## Okay... the following code is just silly. I know
    ## but hear me out. Adding the nodes to the elements
    ## directly caused big issues - mainly surrounding the
    ## "x:" namespace identifiers. This is a hacky fix but
    ## it does the trick.
    foreach ($v in $vx) {
        $xml = ((Get-Variable -Name "xaml$($v)").Value) # Load the XML

        # add the resources needed for strings
        $xml.DocumentElement.SetAttribute('xmlns:sys', 'clr-namespace:System;assembly=System')

        # if the document doesn't already have a "Window.Resources" create it
        if ($null -eq ($xml.DocumentElement.'Window.Resources')) { 
            $fragment = '<Window.Resources>' 
            $fragment += '<ResourceDictionary>'
        }
        
        # Add each StaticResource with the key of the base name and source to the full name
        foreach ($sr in $MediaResources) {
            $srname = "$($sr.BaseName -replace $xp, '_')$($sr.Extension.Substring(1).ToUpper())" #convert name to basename + Uppercase Extension
            if ($sr.Extension -in $imageFileTypes) { $fragment += "<BitmapImage x:Key=`"$srname`" UriSource=`"$($sr.FullName)`" />" }
            if ($sr.Extension -in $avFileTypes) { 
                $uri = [System.Uri]::new($sr.FullName)
                $fragment += "<sys:Uri x:Key=`"$srname`">$uri</sys:Uri>" 
            }    
        }

        # if the document doesn't already have a "Window.Resources" close it
        if ($null -eq ($xml.DocumentElement.'Window.Resources')) {
            $fragment += '</ResourceDictionary>'
            $fragment += '</Window.Resources>'
            $xml.DocumentElement.InnerXml = $fragment + $xml.DocumentElement.InnerXml
        }
        # otherwise just add the fragment to the existing resource dictionary
        else {
            $xml.DocumentElement.'Window.Resources'.ResourceDictionary.InnerXml += $fragment
        }

        # Reset the value of the variable
        (Get-Variable -Name "xaml$($v)").Value = $xml
    }
}
#################
## Create "Forms"
#################
$forms = @()
foreach ($x in $vx) {
    $Reader = (New-Object System.Xml.XmlNodeReader ((Get-Variable -Name "xaml$($x)").Value)) #load the xaml we created earlier into XmlNodeReader
    New-Variable -Name "form$($x)" -Value ([Windows.Markup.XamlReader]::Load($Reader)) -Force #load the xaml into XamlReader
    $forms += "form$($x)" #add the form name to our array
    $SyncClass.SyncHash.Add("form$($x)", (Get-Variable -Name "form$($x)").Value) #add the form object to our synched hashtable
}
#################################
## Create Controls (Buttons, etc)
#################################
$controls = @()
$xp = '[^a-zA-Z_0-9]' # All characters that are not a-Z, 0-9, or _
foreach ($x in $vx) {
    $xaml = (Get-Variable -Name "xaml$($x)").Value #load the xaml we created earlier
    $xaml.SelectNodes('//*[@Name]') | ForEach-Object { #find all nodes with a "Name" attribute
        $cname = "form$($x)Control$(($_.Name -replace $xp, '_'))"
        Set-Variable -Name "$cname" -Value $SyncClass.SyncHash."form$($x)".FindName($_.Name) #create a variale to hold the control/object
        $controls += (Get-Variable -Name "form$($x)Control$($_.Name)").Name #add the control name to our array
        $SyncClass.SyncHash.Add($cname, $SyncClass.SyncHash."form$($x)".FindName($_.Name)) #add the control directly to the hashtable
    }
}
############################
## FORMS AND CONTROLS OUTPUT
############################
<# Write-Host -ForegroundColor Cyan "The following forms were created:"
$forms | %{ Write-Host -ForegroundColor Yellow "  `$$_"} #output all forms to screen
if($controls.Count -gt 0){
    Write-Host ""
    Write-Host -ForegroundColor Cyan "The following controls were created:"
    $controls | %{ Write-Host -ForegroundColor Yellow "  `$$_"} #output all named controls to screen
} #>
#######################
## DISABLE A/V AUTOPLAY
#######################
foreach ($x in $vx) {
    $carray = @()
    $fts = $syncClass.SyncHash."form$($x)"
    foreach ($c in $fts.Content.Children) {
        if ($c.GetType().Name -eq 'MediaElement') { #find all controls with the type MediaElement
            $c.LoadedBehavior = 'Manual' #Don't autoplay
            $c.UnloadedBehavior = 'Stop' #When the window closes, stop the music
            $carray += $c #add the control to an array
        }
    }
    if ($carray.Count -gt 0) {
        New-Variable -Name "form$($x)PoSHPFCleanupAudio" -Value $carray -Force # Store the controls in an array to be accessed later
        $syncClass.SyncHash."form$($x)".Add_Closed({
                foreach ($c in (Get-Variable "form$($x)PoSHPFCleanupAudio").Value) {
                    $c.Source = $null #stops any currently playing media
                }
            })
    }
}

#####################
## RUNSPACE FUNCTIONS
#####################
## Yo dawg... Runspace to clean up Runspaces
## Thank you Boe Prox / Stephen Owen
#region RSCleanup
$Script:JobCleanup = [hashtable]::Synchronized(@{}) 
$Script:Jobs = [system.collections.arraylist]::Synchronized((New-Object System.Collections.ArrayList)) #hashtable to store all these runspaces
$jobCleanup.Flag = $True #cleanup jobs
$newRunspace = [runspacefactory]::CreateRunspace() #create a new runspace for this job to cleanup jobs to live
$newRunspace.ApartmentState = 'STA'
$newRunspace.ThreadOptions = 'ReuseThread'
$newRunspace.Open()
$newRunspace.SessionStateProxy.SetVariable('jobCleanup', $jobCleanup) #pass the jobCleanup variable to the runspace
$newRunspace.SessionStateProxy.SetVariable('jobs', $jobs) #pass the jobs variable to the runspace
$jobCleanup.PowerShell = [PowerShell]::Create().AddScript({
        #Routine to handle completed runspaces
        Do {    
            Foreach ($runspace in $jobs) {            
                If ($runspace.Runspace.isCompleted) {
                    #if runspace is complete
                    [void]$runspace.powershell.EndInvoke($runspace.Runspace)  #then end the script
                    $runspace.powershell.dispose()                            #dispose of the memory
                    $runspace.Runspace = $null                                #additional garbage collection
                    $runspace.powershell = $null                              #additional garbage collection
                } 
            }
            #Clean out unused runspace jobs
            $temphash = $jobs.clone()
            $temphash | Where-Object {
                $_.runspace -eq $Null
            } | ForEach-Object {
                $jobs.remove($_)
            }        
            Start-Sleep -Seconds 1 #lets not kill the processor here 
        } while ($jobCleanup.Flag)
    })
$jobCleanup.PowerShell.Runspace = $newRunspace
$jobCleanup.Thread = $jobCleanup.PowerShell.BeginInvoke() 
#endregion RSCleanup

#This function creates a new runspace for a script block to execute
#so that you can do your long running tasks not in the UI thread.
#Also the SyncClass is passed to this runspace so you can do UI
#updates from this thread as well.
function Start-BackgroundScriptBlock($scriptBlock) {
    $newRunspace = [runspacefactory]::CreateRunspace()
    $newRunspace.ApartmentState = 'STA'
    $newRunspace.ThreadOptions = 'ReuseThread'          
    $newRunspace.Open()
    $newRunspace.SessionStateProxy.SetVariable('SyncClass', $SyncClass) 
    $PowerShell = [PowerShell]::Create().AddScript($scriptBlock)
    $PowerShell.Runspace = $newRunspace
    $PowerShell.BeginInvoke()

    #Add it to the job list so that we can make sure it is cleaned up
    <#     [void]$Jobs.Add(
        [pscustomobject]@{
            PowerShell = $PowerShell
            Runspace = $PowerShell.BeginInvoke()
        }
    ) #>
}
#================================================
#   Window Functions
#   Minimize Command and PowerShell Windows
#================================================
$Script:showWindowAsync = Add-Type -MemberDefinition @'
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
'@ -Name 'Win32ShowWindowAsync' -Namespace Win32Functions -PassThru
function Hide-CmdWindow() {
    $CMDProcess = Get-Process -Name cmd -ErrorAction Ignore
    foreach ($Item in $CMDProcess) {
        $null = $showWindowAsync::ShowWindowAsync((Get-Process -Id $Item.id).MainWindowHandle, 2)
    }
}
function Hide-PowershellWindow() {
    $null = $showWindowAsync::ShowWindowAsync((Get-Process -Id $pid).MainWindowHandle, 2)
}
function Show-PowershellWindow() {
    $null = $showWindowAsync::ShowWindowAsync((Get-Process -Id $pid).MainWindowHandle, 10)
}
#endregion
#=================================================
# Tpm
if ($global:OSDCloudWorkflowDevice.IsTpmReady -eq $true) {
    $formMainWindowControlIsTpmReady.Foreground = 'Green'
}
else {
    $formMainWindowControlIsTpmReady.Foreground = 'Red'
}

# Autopilot
if ($global:OSDCloudWorkflowDevice.IsAutopilotReady -eq $true) {
    $formMainWindowControlIsAutopilotReady.Foreground = 'Green'
}
else {
    $formMainWindowControlIsAutopilotReady.Foreground = 'Red'
}
#endregion
#=================================================
#region OSDCloud Workflow Library
$global:OSDCloudWorkflowInit.Flows | ForEach-Object {
    $formMainWindowControlTaskComboBox.Items.Add($_.Name) | Out-Null
}
$formMainWindowControlTaskComboBox.SelectedIndex = 0
#endregion
#=================================================
#region OperatingSystem
$global:OSDCloudWorkflowInit.OperatingSystemValues | ForEach-Object {
    $formMainWindowControlOperatingSystemCombo.Items.Add($_) | Out-Null
}
$formMainWindowControlOperatingSystemCombo.SelectedValue = $global:OSDCloudWorkflowInit.OperatingSystem
#endregion
#=================================================
#region OSLanguage
$global:OSDCloudWorkflowInit.OSLanguageCodeValues | ForEach-Object {
    $formMainWindowControlOSLanguageCodeCombo.Items.Add($_) | Out-Null
}
$formMainWindowControlOSLanguageCodeCombo.SelectedValue = $global:OSDCloudWorkflowInit.OSLanguageCode
#endregion
#=================================================
#region OSEdition
$global:OSDCloudWorkflowInit.OSEditionValues | ForEach-Object {
    $formMainWindowControlOSEditionCombo.Items.Add($_.Edition) | Out-Null
}

$global:OSDCloudWorkflowInit.OSEditionValues | ForEach-Object {
    $formMainWindowControlOSEditionIdCombo.Items.Add($_.EditionId) | Out-Null
}
#endregion
#=================================================
#region OSActivation
$global:OSDCloudWorkflowInit.OSActivationValues | ForEach-Object {
    $formMainWindowControlOSActivationCombo.Items.Add($_) | Out-Null
}
#endregion
#=================================================
#region DriverPack
$global:OSDCloudWorkflowInit.DriverPackValues | ForEach-Object {
    $formMainWindowControlDriverPackCombo.Items.Add($_.Name) | Out-Null
}
if ($global:OSDCloudWorkflowInit.DriverPackName) {
    $formMainWindowControlDriverPackCombo.SelectedValue = $global:OSDCloudWorkflowInit.DriverPackName
}
#endregion
#=================================================
#region Set-FormConfigurationCloud
function Set-FormConfigurationCloud {
    $formMainWindowControlOperatingSystemLabel.Content = 'Operating System'

    <#
    $OperatingSystemEditions = $global:PSOSDCloudOperatingSystems | `
        Where-Object {$_.OperatingSystem -eq "$($formMainWindowControlOperatingSystemCombo.SelectedValue)"} | `
        Where-Object {$_.OSLanguageCode -eq "$($formMainWindowControlOSLanguageCodeCombo.SelectedValue)"} | `
        Select-Object -ExpandProperty OSEdition -Unique
    #>

    $formMainWindowControlOSLanguageCodeCombo.IsEnabled = $true
    $formMainWindowControlOSLanguageCodeCombo.Visibility = 'Visible'
    $formMainWindowControlOSLanguageCodeCombo.SelectedValue = $global:OSDCloudWorkflowInit.OSLanguageCode

    $formMainWindowControlOSEditionLabel.Content = 'Edition'
    $formMainWindowControlOSEditionCombo.IsEnabled = $true
    $formMainWindowControlOSEditionCombo.Visibility = 'Visible'
    $formMainWindowControlOSEditionCombo.SelectedValue = $global:OSDCloudWorkflowInit.OSEdition

    $formMainWindowControlOSActivationCombo.IsEnabled = $true
    $formMainWindowControlOSActivationCombo.Visibility = 'Visible'
    $formMainWindowControlOSActivationCombo.SelectedValue = $global:OSDCloudWorkflowInit.OSActivation

    $formMainWindowControlOSEditionIdCombo.IsEnabled = $false
    $formMainWindowControlOSEditionIdCombo.Visibility = 'Visible'
    $formMainWindowControlOSEditionIdCombo.SelectedValue = $global:OSDCloudWorkflowInit.OSEditionId

    $formMainWindowControlImageNameCombobox.Items.Clear()
    $formMainWindowControlImageNameCombobox.Visibility = 'Collapsed'
}
Set-FormConfigurationCloud
#endregion
#=================================================
#region CustomImage
<#
[array]$OSDCloudWorkflowSettingsOSIso = @()
[array]$OSDCloudWorkflowSettingsOSIso = Find-OSDCloudAsset -Name '*.iso' -Path '\OSDCloud\OS\' | Where-Object { $_.Length -gt 3GB }

foreach ($Item in $OSDCloudWorkflowSettingsOSIso) {
    if ((Get-DiskImage -ImagePath $Item.FullName).Attached) {
        #ISO is already mounted
    }
    else {
        Write-Host "Mounting OSDCloud OS ISO $($Item.FullName)" -ForegroundColor Cyan
        $Results = Mount-DiskImage -ImagePath $Item.FullName
        $Results | Select-Object -Property Attached, DevicePath, ImagePath, Number, Size | Format-List
    }
}

$CustomImageChildItem = @()
[array]$CustomImageChildItem = Find-OSDCloudAsset -Name '*.wim' -Path '\OSDCloud\OS\'
[array]$CustomImageChildItem += Find-OSDCloudAsset -Name 'install.wim' -Path '\Sources\'
[array]$CustomImageChildItem += Find-OSDCloudAsset -Name '*.esd' -Path '\OSDCloud\OS\'
[array]$CustomImageChildItem += Find-OSDCloudAsset -Name '*install.swm' -Path '\OSDCloud\OS\'
$CustomImageChildItem = $CustomImageChildItem | Sort-Object -Property Length -Unique | Sort-Object FullName | Where-Object { $_.Length -gt 2GB }
        
if ($CustomImageChildItem) {
    $OSDCloudOperatingSystem = Get-OSDCatalogOperatingSystems
    $CustomImageChildItem = $CustomImageChildItem | Where-Object { $_.Name -notin $OSDCloudOperatingSystem.FileName }
    $CustomImageChildItem | ForEach-Object {
        $formMainWindowControlOperatingSystemCombo.Items.Add($_) | Out-Null
    }
}
#>
#endregion
#================================================
#region OSEdition
$formMainWindowControlOSEditionCombo.add_SelectionChanged(
    {
        # Home
        if ($formMainWindowControlOSEditionCombo.SelectedValue -match 'Home') {
            $formMainWindowControlOSActivationCombo.SelectedValue = 'Retail'
            $formMainWindowControlOSActivationCombo.IsEnabled = $false
        }

        # Education
        if ($formMainWindowControlOSEditionCombo.SelectedValue -match 'Education') {
            $formMainWindowControlOSActivationCombo.IsEnabled = $true
        }

        # Enterprise
        if ($formMainWindowControlOSEditionCombo.SelectedValue -match 'Enterprise') {
            $formMainWindowControlOSActivationCombo.SelectedValue = 'Volume'
            $formMainWindowControlOSActivationCombo.IsEnabled = $false
        }

        # Pro
        if ($formMainWindowControlOSEditionCombo.SelectedValue -match 'Pro') {
            $formMainWindowControlOSActivationCombo.IsEnabled = $true
        }

        $formMainWindowControlOSEditionIdCombo.SelectedValue = $global:OSDCloudWorkflowInit.OSEditionValues | Where-Object { $_.Edition -eq $formMainWindowControlOSEditionCombo.SelectedValue } | Select-Object -ExpandProperty EditionId
    }
)
#endregion
#================================================
#region Operating System
<#
function Set-FormConfigurationLocal {
    $formMainWindowControlOSLanguageCodeCombo.Visibility = 'Collapsed'
    $formMainWindowControlOSEditionLabel.Content = 'ImageName'
    $formMainWindowControlOSEditionCombo.Visibility = 'Collapsed'
    $formMainWindowControlOSEditionIdLabel.Visibility = 'Collapsed'
    $formMainWindowControlOSEditionIdCombo.Visibility = 'Collapsed'
    $formMainWindowControlOSActivationLabel.Visibility = 'Collapsed'
    $formMainWindowControlOSActivationCombo.Visibility = 'Collapsed'
    $formMainWindowControlImageNameCombobox.Visibility = 'Visible'
    $formMainWindowControlImageNameCombobox.Items.Clear()
    $formMainWindowControlImageNameCombobox.IsEnabled = $true
    $GetWindowsImageOptions = Get-WindowsImage -ImagePath $formMainWindowControlOperatingSystemCombo.SelectedValue
    $GetWindowsImageOptions | ForEach-Object {
        $formMainWindowControlImageNameCombobox.Items.Add($_.ImageName) | Out-Null
    }
    $formMainWindowControlImageNameCombobox.SelectedIndex = 0
    $formMainWindowControlOperatingSystemLabel.Content = 'Windows Image'
    $formMainWindowControlOSEditionLabel.Content = 'Image Name'
}

$formMainWindowControlOperatingSystemCombo.add_SelectionChanged(
    {
        if ($formMainWindowControlOperatingSystemCombo.SelectedValue -like 'Windows 1*64') {
            Set-FormConfigurationCloud
        }
        else {
            Set-FormConfigurationLocal
        }
    }
)
#>
#endregion
#================================================
#region Menu Controls
$formMainWindowControlStartMSInfo.add_Click({ Start-Process msinfo32.exe })
$formMainWindowControlStartOSK.add_Click({ Start-Process osk.exe })
$formMainWindowControlStartCmdPrompt.add_Click({ Start-Process cmd })
$formMainWindowControlStartPowerShell.add_Click({ Start-Process PowerShell.exe })
#endregion
#================================================
#region StartButton
$formMainWindowControlStartButton.add_Click(
    {
        $formMainWindow.Close()
        Show-PowershellWindow
        #================================================
        #   ImageFile
        #================================================
        $OperatingSystem = $formMainWindowControlOperatingSystemCombo.SelectedValue

        # Determine OperatingSystem
        if ($OperatingSystem -in $global:OSDCloudWorkflowInit.OperatingSystemValues) {

            $OSActivation = $formMainWindowControlOSActivationCombo.SelectedValue
            $OSLanguageCode = $formMainWindowControlOSLanguageCodeCombo.SelectedValue
            $OSEdition = $formMainWindowControlOSEditionCombo.SelectedValue
            $OSEditionId = $formMainWindowControlOSEditionIdCombo.SelectedValue
            $OSVersion = $OperatingSystem.Split(' ')[2]
            
            $OperatingSystemObject = $global:PSOSDCloudOperatingSystems | Where-Object { $_.OperatingSystem -match $OperatingSystem } | Where-Object { $_.OSActivation -eq $OSActivation } | Where-Object { $_.OSLanguageCode -eq $OSLanguageCode }
            
            $ImageFileUrl = $OperatingSystemObject.FilePath
            $ImageFileName = $OperatingSystemObject.FileName
            $OSBuild = $OperatingSystemObject.OSBuild

            $LocalImageFileInfo = Find-OSDCloudAsset -Name $OperatingSystemObject.FileName -Path '\OSDCloud\OS\' | Sort-Object FullName | Where-Object { $_.Length -gt 3GB }
            $LocalImageFileInfo = $LocalImageFileInfo | Where-Object { $_.FullName -notlike 'C*' } | Where-Object { $_.FullName -notlike 'X*' } | Select-Object -First 1
        }
        else {
            $OperatingSystem = $null
            $LocalImageFilePath = $formMainWindowControlOperatingSystemCombo.SelectedValue
            if ($LocalImageFilePath) {
                $LocalImageFileInfo = $CustomImageChildItem | Where-Object { $_.FullName -eq "$LocalImageFilePath" }
                $ImageFileName = Split-Path -Path $LocalImageFileInfo.FullName -Leaf
                $LocalImageName = $formMainWindowControlImageNameCombobox.SelectedValue
            }
        }
        #================================================
        #   Workflow
        #================================================
        $OSDCloudWorkflowTaskName = $formMainWindowControlTaskComboBox.SelectedValue
        $OSDCloudWorkflowObject = $global:OSDCloudWorkflowInit.Flows | Where-Object { $_.Name -eq $OSDCloudWorkflowTaskName } | Select-Object -First 1
        #================================================
        #   DriverPack
        #================================================
        if ($formMainWindowControlDriverPackCombo.Text) {
            $DriverPackName = $formMainWindowControlDriverPackCombo.Text
            $DriverPackObject = $global:OSDCloudWorkflowInit.DriverPackValues | Where-Object { $_.Name -eq $DriverPackName }
        }
        #================================================
        #   Global Variables
        #================================================
        $global:OSDCloudWorkflowInit.WorkflowTaskName = $OSDCloudWorkflowTaskName
        $global:OSDCloudWorkflowInit.WorkflowObject = $OSDCloudWorkflowObject
        $global:OSDCloudWorkflowInit.OperatingSystem = $OperatingSystem
        $global:OSDCloudWorkflowInit.OSActivation = $OSActivation
        $global:OSDCloudWorkflowInit.OSBuild = $OSBuild
        $global:OSDCloudWorkflowInit.OSEdition = $OSEdition
        $global:OSDCloudWorkflowInit.OSEditionId = $OSEditionId
        $global:OSDCloudWorkflowInit.OSLanguageCode = $OSLanguageCode
        $global:OSDCloudWorkflowInit.OSVersion = $OSVersion
        $global:OSDCloudWorkflowInit.DriverPackName = $DriverPackName
        $global:OSDCloudWorkflowInit.ImageFileName = $ImageFileName
        $global:OSDCloudWorkflowInit.ImageFileUrl = $ImageFileUrl
        $global:OSDCloudWorkflowInit.LocalImageFileInfo = $LocalImageFileInfo
        $global:OSDCloudWorkflowInit.LocalImageFilePath = $LocalImageFilePath
        $global:OSDCloudWorkflowInit.LocalImageName = $LocalImageName

        $global:OSDCloudWorkflowInit.DriverPackObject = $DriverPackObject
        $global:OSDCloudWorkflowInit.OperatingSystemObject = $OperatingSystemObject
        
        $global:OSDCloudWorkflowInit.TimeStart = (Get-Date)
        #=================================================
        #   Invoke-OSDCloudWorkflow.ps1
        #=================================================
        # Write-Host -ForegroundColor DarkGray "[$(Get-Date -format s)] [OSDCloud Frontend]"
        # $global:OSDCloudWorkflowFrontend | Out-Host
        # Invoke-OSDCloudWorkflow
        #=================================================
    }
)
#endregion
#================================================
#region Customizations
#TODO fix the Version since this is not a Module function it doesn't give a version
$ModuleVersion = $($MyInvocation.MyCommand.Module.Version)
$formMainWindow.Title = "OSDCloud on $($global:OSDCloudWorkflowInit.ComputerManufacturer) $($global:OSDCloudWorkflowInit.ComputerModel)"
#endregion
#================================================
#region Branding
$formMainWindowControlBrandingTitleControl.Content = 'OSDCloud'
$formMainWindowControlBrandingTitleControl.Foreground = '#0067C0'
#endregion
#================================================
#region Startup
Hide-CmdWindow
Hide-PowershellWindow
########################
## WIRE UP YOUR CONTROLS
########################
# simple example: $formMainWindowControlButton.Add_Click({ your code })
#
# example with BackgroundScriptBlock and UpdateElement
# $formmainControlButton.Add_Click({
#     $sb = {
#         $SyncClass.UpdateElement("formmainControlProgress","Value",25)
#     }
#     Start-BackgroundScriptBlock $sb
# })

############################
###### DISPLAY DIALOG ######
############################
[void]$formMainWindow.ShowDialog()

##########################
##### SCRIPT CLEANUP #####
##########################
$jobCleanup.Flag = $false #Stop Cleaning Jobs
$jobCleanup.PowerShell.Runspace.Close() #Close the runspace
$jobCleanup.PowerShell.Dispose() #Remove the runspace from memory
#endregion
#================================================
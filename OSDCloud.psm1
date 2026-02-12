# Get public and private function definition files.
$Classes = @(Get-ChildItem -Path "$PSScriptRoot\classes\*.ps1")
$Private = @( Get-ChildItem -Path $PSScriptRoot\private\*.ps1 -ErrorAction SilentlyContinue -Recurse )
$Public = @( Get-ChildItem -Path $PSScriptRoot\public\*.ps1 -ErrorAction SilentlyContinue -Recurse )
$PublicWinPE = @( Get-ChildItem -Path $PSScriptRoot\public-winpe\*.ps1 -ErrorAction SilentlyContinue -Recurse )

try {
    if (!([System.Management.Automation.PSTypeName]'HtmlAgilityPack.HtmlDocument').Type) {
        if ($PSVersionTable.PSEdition -eq "Desktop") {
            Add-Type -Path "$PSScriptRoot\types\Net45\HtmlAgilityPack.dll"
        } else {
            Add-Type -Path "$PSScriptRoot\types\netstandard2.0\HtmlAgilityPack.dll"
        }
    }
} catch {
    $Err = $_
    throw $Err
}

$FoundErrors = @(
    if ($env:SystemDrive -eq 'X:') {
        foreach ($Import in @($Private + $Public + $PublicWinPE + $Classes)) {
            try { . $Import.Fullname}
            catch {
                Write-Error -Message "Failed to import functions from $($Import.Fullname): $_"
                $true
            }
        }
    } else {
        foreach ($Import in @($Private + $Public + $Classes)) {
            try { . $Import.Fullname}
            catch {
                Write-Error -Message "Failed to import functions from $($Import.Fullname): $_"
                $true
            }
        }
    }
)

if ($FoundErrors.Count -gt 0) {
    $ModuleName = (Get-ChildItem $PSScriptRoot\*.psd1).BaseName
    Write-Warning "Importing module $ModuleName failed. Fix errors before continuing."
    break
}

Export-ModuleMember -Function '*' -Alias '*' -Cmdlet '*'
Initialize-OSDCloudModule
# Get public and private function definition files.
$Private = @( Get-ChildItem -Path $PSScriptRoot\private\*.ps1 -ErrorAction SilentlyContinue -Recurse )
$Public = @( Get-ChildItem -Path $PSScriptRoot\public\*.ps1 -ErrorAction SilentlyContinue -Recurse )
$PublicWinPE = @( Get-ChildItem -Path $PSScriptRoot\public-winpe\*.ps1 -ErrorAction SilentlyContinue -Recurse )

$FoundErrors = @(
    if ($env:SystemDrive -eq 'X:') {
        foreach ($Import in @($Private + $Public + $PublicWinPE)) {
            try { . $Import.Fullname}
            catch {
                Write-Error -Message "Failed to import functions from $($Import.Fullname): $_"
                $true
            }
        }
    } else {
        foreach ($Import in @($Private + $Public)) {
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

# Set-Alias -Name OSDCloud -Value Start-OSDCloudPilot -Scope Global
Export-ModuleMember -Function '*' -Alias '*' -Cmdlet '*'
Initialize-OSDCloudModule
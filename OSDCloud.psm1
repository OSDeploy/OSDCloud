# Get public and private function definition files.
$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue -Recurse )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue -Recurse )

$FoundErrors = @(
    foreach ($Import in @($Private + $Public)) {
        Try {
            . $Import.Fullname
        } Catch {
            Write-Error -Message "Failed to import functions from $($Import.Fullname): $_"
            $true
        }
    }
)

if ($FoundErrors.Count -gt 0) {
    $ModuleName = (Get-ChildItem $PSScriptRoot\*.psd1).BaseName
    Write-Warning "Importing module $ModuleName failed. Fix errors before continuing."
    break
}

Set-Alias -Name OSDCloud -Value Start-OSDCloudPilot -Scope Global
Export-ModuleMember -Function '*' -Alias '*' -Cmdlet '*'
Initialize-OSDCloudModule
<#
.SYNOPSIS
Tests to see if a Uri by Invoke-WebRequest -Method Head
.DESCRIPTION
Tests to see if a Uri by Invoke-WebRequest -Method Head
.LINK
https://github.com/OSDeploy/OSD/tree/master/Docs
#>
function Test-OSDCloudInternetConnection
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline)]
        # Uri to test
        [System.Uri]
        $Uri = 'google.com'
    )
    $Params = @{
        Method = 'Head'
        Uri = $Uri
        UseBasicParsing = $true
        Headers = @{'Cache-Control'='no-cache'}
    }

    try {
        Write-Verbose "Test-OSDCloudInternetConnection OK: $Uri"
        Invoke-WebRequest @Params | Out-Null
        $true
    }
    catch {
        Write-Verbose "Test-OSDCloudInternetConnection FAIL: $Uri"
        $false
    }
    finally {
        $Error.Clear()
    }
}
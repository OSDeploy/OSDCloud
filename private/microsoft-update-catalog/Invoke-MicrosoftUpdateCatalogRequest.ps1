function Invoke-MicrosoftUpdateCatalogRequest {
    param (
        [Parameter(Mandatory = $true)]
        [string] $Uri,

        [Parameter(Mandatory = $false)]
        [string] $Method = "Get"
    )

    try {
        $Headers = @{
            "Cache-Control" = "no-cache"
            "Pragma"        = "no-cache"
        }

        $Params = @{
            Uri             = $Uri
            UseBasicParsing = $true
            ErrorAction     = "Stop"
            Headers         = $Headers
        }

        $Results = Invoke-WebRequest @Params
        $HtmlDoc = [HtmlAgilityPack.HtmlDocument]::new()
        $HtmlDoc.LoadHtml($Results.RawContent.ToString())
        $NoResults = $HtmlDoc.GetElementbyId("ctl00_catalogBody_noResultText")
        $ErrorText = $HtmlDoc.GetElementbyId("errorPageDisplayedError")

        if ($null -eq $NoResults -and $null -eq $ErrorText) {
            return [MicrosoftUpdateCatalogResponse]::new($HtmlDoc)
        }
        elseif ($ErrorText) {
            if ($ErrorText.InnerText -match '8DDD0010') {
                throw "[$(Get-Date -format s)] The catalog.microsoft.com site has encountered an error with code 8DDD0010. Please try again later."
            }
            else {
                throw "[$(Get-Date -format s)] The catalog.microsoft.com site has encountered an error: $($ErrorText.InnerText)"
            }
        }
        else {
            Write-Verbose "[$(Get-Date -format s)] Unable to find results for $Uri"
        }
    }
    catch {
        Write-Warning "$_"
    }
}
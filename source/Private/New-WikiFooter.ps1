<#
    .SYNOPSIS
        Creates the Wiki footer file if one does not already exist.

    .DESCRIPTION
        Creates the Wiki footer file if one does not already exist.

    .PARAMETER Path
        The path for the Wiki footer file.

    .PARAMETER BaseName
        The base name of the Wiki footer file. Defaults to '_Footer.md'.

    .EXAMPLE
        New-WikiFooter -Path $path

        Creates the Wiki footer.
#>
function New-WikiFooter
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        $BaseName = '_Footer.md'
    )

    $wikiFooterPath = Join-Path -Path $path -ChildPath $BaseName

    if (-not (Test-Path -Path $wikiFooterPath))
    {
        Write-Verbose -Message ($localizedData.GenerateWikiFooterMessage -f $BaseName)

        $wikiFooter = @()

        Out-File -InputObject $wikiFooter -FilePath $wikiFooterPath -Encoding 'ascii'
    }
}

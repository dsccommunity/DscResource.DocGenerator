<#
    .SYNOPSIS
        Creates the Wiki footer file if one does not already exist.

    .DESCRIPTION
        Creates the Wiki footer file if one does not already exist.

    .PARAMETER OutputPath
        The path in which the Wiki footer file should be generated.

    .PARAMETER WikiSourcePath
        The path in which the code should check for an existing Wiki footer file.

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
        $OutputPath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WikiSourcePath,

        [Parameter()]
        [System.String]
        $BaseName = '_Footer.md'
    )

    $wikiFooterOutputPath = Join-Path -Path $OutputPath -ChildPath $BaseName
    $wikiFooterWikiSourcePath = Join-Path -Path $WikiSourcePath -ChildPath $BaseName

    if (-not (Test-Path -Path $wikiFooterWikiSourcePath))
    {
        Write-Verbose -Message ($localizedData.GenerateWikiFooterMessage -f $BaseName)

        $wikiFooter = @()

        Out-File -InputObject $wikiFooter -FilePath $wikiFooterOutputPath -Encoding 'ascii'
    }
}

<#
    .SYNOPSIS
        Get-TextWithoutMarkdownCode is remove markdown code from a text string.

    .DESCRIPTION
        Get-TextWithoutMarkdownCode is remove markdown code from a text string.

    .PARAMETER Text
        The text string to process.

    .PARAMETER MarkdownCodeRegularExpression
        An array of regular expressions that should be used to parse the parameter
        descriptions in the schema MOF. Each regular expression must be written
        so that the capture group 0 is the full match and the capture group 1 is
        the text that should be kept.


    .EXAMPLE
        $myText = Get-TextWithoutMarkdownCode -Text 'My code call `Get-Process`' -MarkdownCodeRegularExpression @('\`(.+?)\`')

        This example process the string an remove the inline code-block.
#>
function Get-TextWithoutMarkdownCode
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Text,

        [Parameter()]
        [System.String[]]
        $MarkdownCodeRegularExpression = @()
    )

    if ($MarkdownCodeRegularExpression.Count -gt 0)
    {
        foreach ($parseRegularExpression in $MarkdownCodeRegularExpression)
        {
            $allMatches = $Text | Select-String -Pattern $parseRegularExpression -AllMatches

            foreach ($regularExpressionMatch in $allMatches.Matches)
            {
                <#
                    Always assume the group 0 is the full match and
                    the group 1 contain what we should replace with.
                #>
                $Text = $Text -replace @(
                    [RegEx]::Escape($regularExpressionMatch.Groups[0].Value),
                    $regularExpressionMatch.Groups[1].Value
                )
            }
        }
    }

    return $Text
}

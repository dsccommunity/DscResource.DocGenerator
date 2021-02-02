<#
    .SYNOPSIS
        Get-RegularExpressionParsedText removes text that matches a regular expression.

    .DESCRIPTION
        Get-RegularExpressionParsedText removes text that matches a regular expression
        from the passed text string. A regular expression must conform to a specific
        grouping, see parameter 'RegularExpression' for more information.

    .PARAMETER Text
        The text string to process.

    .PARAMETER RegularExpression
        An array of regular expressions that should be used to parse the text. Each
        regular expression must be written so that the capture group 0 is the full
        match and the capture group 1 is the text that should be kept.

    .EXAMPLE
        $myText = Get-RegularExpressionParsedText -Text 'My code call `Get-Process`' -RegularExpression @('\`(.+?)\`')

        This example process the string an remove the inline code-block.
#>
function Get-RegularExpressionParsedText
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
        $RegularExpression = @()
    )

    if ($RegularExpression.Count -gt 0)
    {
        foreach ($parseRegularExpression in $RegularExpression)
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

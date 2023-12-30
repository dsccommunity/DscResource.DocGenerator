<#
    .SYNOPSIS
        Removes a escaped markdown code from a Markdown file.

    .DESCRIPTION
        The Remove-EscapedMarkdownCode function removes escaped markdown code
        from a Markdown file. It searches for the escaped sequences and removes
        it from the file.

    .PARAMETER FilePath
        Specifies the path to the Markdown file.

    .EXAMPLE
        Remove-ParameterFromMarkdown -FilePath 'C:\Path\To\File.md'

        Removes found escaped sequences from the Markdown file located at "C:\Path\To\File.md".

    .INPUTS
        [System.IO.FileInfo]
        Accepts a FileInfo object representing the Markdown file.

    .OUTPUTS
        None. The function modifies the content of the Markdown file directly.
#>
function Remove-EscapedMarkdownCode
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'This function is a private helper function and is not exported publicly.')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
        [System.IO.FileInfo]
        $FilePath
    )

    process
    {
        $content = Get-Content -Path $FilePath.FullName -Raw

        $escapedPatterns = @(
            @{
                RegularExpression = '\\\`(.+?)\\\`' # Remove escaped inline code-blocks
                Replacement = '`$1`'
            }
            @{
                RegularExpression = '\\\[(.+?)\\\]' # Remove escaped links
                Replacement = '[$1]'
            }

            @{
                RegularExpression = '(?m)^\\\>' # Remove quoted blocks
                Replacement = '>'
            }
        )

        foreach ($pattern in $escapedPatterns)
        {
            $content = $content -replace $pattern.RegularExpression, $pattern.Replacement
        }

        # Write the updated content back to the file.
        Set-Content -Path $FilePath.FullName -Value $content
    }
}

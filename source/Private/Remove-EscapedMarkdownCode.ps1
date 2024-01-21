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
        Remove-EscapedMarkdownCode -FilePath 'C:\Path\To\File.md'

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
                # Remove escaped inline code-blocks, ingores escaped code-blocks.
                RegularExpression = '\\\`(?!\\\`)(?!\`)(.+?)\\\`'
                Replacement = '`$1`'
            }
            @{
                # Remove escaped links.
                RegularExpression = '\\\[(.+?)\\\]'
                Replacement = '[$1]'
            }
            @{
                 # Remove quoted blocks, if they start on each line.
                RegularExpression = '(?m)^\\\>'
                Replacement = '>'
            }
            @{
                # Remove escaped code blocks.
                RegularExpression = '\\\`\\\`\\\`'
                Replacement = '```'
            }
            @{
                # Remove escaped less than character.
                RegularExpression = '\\\<'
                Replacement = '<'
            }
            @{
                # Remove escaped greater than character.
                RegularExpression = '\\\>'
                Replacement = '>'
            }
            @{
                # Remove escaped path separator.
                RegularExpression = '\\\\'
                Replacement = '\'
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

<#
    .SYNOPSIS
        Removes metadata from a Markdown file.

    .DESCRIPTION
        The Remove-MarkdownMetadataBlock function removes metadata from a Markdown file.
        It searches for a metadata marker ('---') and removes the content between
        the marker and the next occurrence of the marker.

    .PARAMETER FilePath
        Specifies the path to the Markdown file from which the metadata should be removed.

    .EXAMPLE
        Remove-MarkdownMetadataBlock -FilePath 'C:\Path\To\File.md'

        Removes the metadata from the specified Markdown file.
#>

function Remove-MarkdownMetadataBlock
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

        $metadataPattern = '(?s)---.*?---[\r|\n]*'

        if ($content -match $metadataPattern)
        {
            $content = $content -replace $metadataPattern

            Set-Content -Path $FilePath.FullName -Value $content
        }
    }
}

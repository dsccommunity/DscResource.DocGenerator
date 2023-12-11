<#
    .SYNOPSIS
        Removes metadata from a Markdown file.

    .DESCRIPTION
        The Remove-MarkdownMetadata function removes metadata from a Markdown file.
        It searches for a metadata marker ('---') and removes the content between
        the marker and the next occurrence of the marker.

    .PARAMETER FilePath
        Specifies the path to the Markdown file from which the metadata should be removed.

    .EXAMPLE
        Remove-MarkdownMetadata -FilePath "C:\Path\To\File.md"

        Removes the metadata from the specified Markdown file.
#>

function Remove-MarkdownMetadata
{
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

        $metadataMarker = '---'

        $startIndex = $content.IndexOf($metadataMarker)
        $endIndex = $content.IndexOf($metadataMarker, $startIndex + $metadataMarker.Length) + $metadataMarker.Length

        if ($startIndex -ge 0 -and $endIndex -gt $startIndex)
        {
            $content = $content.Remove($startIndex, $endIndex - $startIndex)

            Set-Content -Path $FilePath.FullName -Value $content
        }
    }
}

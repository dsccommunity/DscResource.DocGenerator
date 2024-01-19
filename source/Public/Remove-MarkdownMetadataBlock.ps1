<#
    .SYNOPSIS
        Removes metadata from a Markdown file.

    .DESCRIPTION
        The Remove-MarkdownMetadataBlock function removes metadata from a Markdown file.
        It searches for a metadata marker ('---') and removes the content between
        the marker and the next occurrence of the marker.

    .PARAMETER FilePath
        Specifies the path to the Markdown file from which the metadata should be removed.

    .PARAMETER Force
        Specifies that the sidebar should be created without any confirmation.

    .EXAMPLE
        Remove-MarkdownMetadataBlock -FilePath 'C:\Path\To\File.md'

        Removes the metadata from the specified Markdown file.
#>
function Remove-MarkdownMetadataBlock
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
        [System.IO.FileInfo]
        $FilePath,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    process
    {
        if ($Force.IsPresent -and -not $Confirm)
        {
            $ConfirmPreference = 'None'
        }

        $content = Get-Content -Path $FilePath.FullName -Raw

        $metadataPattern = '^(?s)---.*?---[\r|\n]*'

        if ($content -match $metadataPattern)
        {
            $verboseDescriptionMessage = $script:localizedData.RemoveMarkdownMetadataBlock_ShouldProcessVerboseDescription -f $FilePath.FullName
            $verboseWarningMessage = $script:localizedData.RemoveMarkdownMetadataBlock_ShouldProcessVerboseWarning -f $FilePath.FullName
            $captionMessage = $script:localizedData.RemoveMarkdownMetadataBlock_ShouldProcessCaption

            if ($PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
            {
                $content = $content -replace $metadataPattern

                Set-Content -Path $FilePath.FullName -Value $content
            }
        }
    }
}

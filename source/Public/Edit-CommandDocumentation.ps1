
<#
    .SYNOPSIS
        Edits the documentation for a command by parsing the comment-based help from
        the source file.

    .DESCRIPTION
        Edits the documentation for a command by parsing the comment-based help from
        the source file.

    .PARAMETER FilePath
        Specifies the FileInfo object of the markdown file containing the documentation
        being edited. This parameter is mandatory.

    .EXAMPLE
        $filePath = Get-Item -Path 'C:\Docs\MyCommand.md'
        Edit-CommandDocumentation -FilePath $filePath -SourcePath 'C:\Scripts\MyCommand.ps1'

        Edits the documentation for the command specified in the markdown file "C:\Docs\MyCommand.md"
        using the source file "C:\Scripts\MyCommand.ps1".
#>
function Edit-CommandDocumentation
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
        $getMarkdownMetadataScript = @"
Get-MarkdownMetadata -Path $($FilePath.FullName) -ErrorAction 'Stop'
"@

        Write-Debug -Message $getMarkdownMetadataScript

        $getMarkdownMetadataScriptBlock = [ScriptBlock]::Create($getMarkdownMetadataScript)

        $pwshPath = (Get-Process -Id $PID).Path

        <#
            The scriptblock is run in a separate process to avoid conflicts with
            other modules that are loaded in the current process.
        #>
        $markdownMetadata = & $pwshPath -Command $getMarkdownMetadataScriptBlock -ExecutionPolicy 'ByPass' -NoProfile

        if ($markdownMetadata.Type -ne 'Command')
        {
            Write-Information -MessageData "The documentation '$($FilePath.BaseName)' was not a command documentation, skipping." -InformationAction 'Continue'

            continue
        }

        switch ($markdownMetadata.Schema)
        {
            '2.0.0'
            {
                Write-Information -MessageData "Cleaning documentation of '$($FilePath.BaseName)'." -InformationAction 'Continue'

                Remove-MarkdownMetadataBlock -FilePath $FilePath

                <#
                    Remove ProgressAction parameter from the documentation. The
                    parameter ProgressAction was introduced in PS 7.4 and is not
                    supported by PlatyPS <v2.0.0.

                    See issue https://github.com/PowerShell/platyPS/issues/595.
                #>
                Remove-ParameterFromMarkdown -FilePath $FilePath -ParameterName 'ProgressAction'
            }

            default
            {
                throw "The markdown file '$($FilePath.FullName)' has an unsupported schema version '$($markdownMetadata.Schema)'."
            }
        }
    }
}

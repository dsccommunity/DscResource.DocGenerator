<#
    .SYNOPSIS
        Removes a parameter from a Markdown file.

    .DESCRIPTION
        The Remove-ParameterFromMarkdown function removes a specified parameter
        from a Markdown file. It searches for the parameter block identified by
        the given parameter name and removes it from the file.

    .PARAMETER FilePath
        Specifies the path to the Markdown file.

    .PARAMETER ParameterName
        Specifies the name of the parameter to be removed.

    .EXAMPLE
        Remove-ParameterFromMarkdown -FilePath 'C:\Path\To\File.md' -ParameterName 'MyParameter'

        Removes the parameter named "MyParameter" from the Markdown file located at "C:\Path\To\File.md".

    .INPUTS
        [System.IO.FileInfo]
        Accepts a FileInfo object representing the Markdown file.

    .OUTPUTS
        None. The function modifies the content of the Markdown file directly.
#>
function Remove-ParameterFromMarkdown
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'This function is a private helper function and is not exported publicly.')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
        [System.IO.FileInfo]
        $FilePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ParameterName
    )

    process
    {
        $content = Get-Content -Path $FilePath.FullName -Raw

        if (-not($ParameterName.StartsWith('-')))
        {
            $ParameterName = ('-{0}' -f $ParameterName)
        }

        $pattern = "### $ParameterName\r?\n[\S\s\r\n]*?(?=#{2,3}?)"
        $regex = [regex]::new($pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
        $parameters = $regex.Matches($content)

        if ($parameters.Count -gt 0)
        {
            # process the parameter
            Write-Verbose ('Removing parameter {0} from {1}' -f $ParameterName, $FilePath.BaseName)

            $content = $content -replace $pattern

            Set-Content -Path $FilePath.FullName -Value $content
        }
        else
        {
            Write-Verbose ('No parameter nodes matching {0} found in {1}' -f $ParameterName, $FilePath.BaseName)
        }
    }
}

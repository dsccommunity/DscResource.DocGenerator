<#
    .SYNOPSIS
        Get-ResourceExampleAsText gathers all examples for a resource and returns
        them as a string in a format that is used for conceptual help.

    .DESCRIPTION
        Get-ResourceExampleAsText gathers all examples for a resource and returns
        them as a string in a format that is used for conceptual help.

    .PARAMETER Path
        The path to the source folder, the path will be recursively searched for *.ps1
        files. All found files will be assumed that they are examples and that
        documentation should be generated for them.

    .EXAMPLE
        $examplesText = Get-ResourceExampleAsText -Path 'c:\MyProject\source\Examples\Resources\MyResourceName'

        This example fetches all examples from the folder 'c:\MyProject\source\Examples\Resources\MyResourceName'
        and returns them as a single string in a format that is used for conceptual help.
#>
function Get-ResourceExampleAsText
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    $filePath = Join-Path -Path $Path -ChildPath '*.ps1'

    $exampleFiles = @(Get-ChildItem -Path $filePath -File -Recurse -ErrorAction 'SilentlyContinue')

    if ($exampleFiles.Count -gt 0)
    {
        $exampleCount = 1

        Write-Verbose -Message ($script:localizedData.FoundResourceExamplesMessage -f $exampleFiles.Count)

        foreach ($exampleFile in $exampleFiles)
        {
            $exampleContent = Get-DscResourceHelpExampleContent `
                -ExamplePath $exampleFile.FullName `
                -ExampleNumber ($exampleCount++)

            $exampleContent = $exampleContent -replace '\r?\n', "`r`n"

            $text += $exampleContent
            $text += "`r`n"
        }
    }
    else
    {
        Write-Warning -Message ($script:localizedData.NoExampleFileFoundWarning)
    }

    return $text
}

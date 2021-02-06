<#
    .SYNOPSIS
        Get-ResourceExampleAsMarkdown gathers all examples for a resource and returns
        them as string build object in markdown format.

    .DESCRIPTION
        Get-ResourceExampleAsMarkdown gathers all examples for a resource and returns
        them as string build object in markdown format.

    .PARAMETER Path
        The path to the source folder where the examples for the resource exist.

    .EXAMPLE
        $examplesMarkdown = Get-ResourceExampleAsMarkdown -Path 'c:\MyProject\source\Examples\Resources\MyResourceName'

        This example fetches all examples from the folder 'c:\MyProject\source\Examples\Resources\MyResourceName'
        and returns them as a single string in markdown format.
#>
function Get-ResourceExampleAsMarkdown
{
    [CmdletBinding()]
    [OutputType([System.Text.StringBuilder])]
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
        $outputExampleMarkDown = New-Object -TypeName 'System.Text.StringBuilder'

        Write-Verbose -Message ($script:localizedData.FoundResourceExamplesMessage -f $exampleFiles.Count)

        $null = $outputExampleMarkDown.AppendLine('## Examples')

        $exampleCount = 1

        foreach ($exampleFile in $exampleFiles)
        {
            $exampleContent = Get-DscResourceWikiExampleContent `
                -ExamplePath $exampleFile.FullName `
                -ExampleNumber ($exampleCount++)

            $null = $outputExampleMarkDown.AppendLine()
            $null = $outputExampleMarkDown.AppendLine($exampleContent)
        }
    }
    else
    {
        Write-Warning -Message ($script:localizedData.NoExampleFileFoundWarning)
    }

    return $outputExampleMarkDown
}

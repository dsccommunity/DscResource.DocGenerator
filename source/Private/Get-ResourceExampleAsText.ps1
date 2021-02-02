<#
    .SYNOPSIS
        Get-ResourceExampleAsText gathers all examples for a resource and returns
        them as a string in a format that is used for conceptual help.

    .DESCRIPTION
        Get-ResourceExampleAsText gathers all examples for a resource and returns
        them as a string in a format that is used for conceptual help.

    .PARAMETER ResourceName
        The name of the resource for which examples should be retrieved.

    .PARAMETER Path
        THe path to the source folder where the folder Examples exist.

    .EXAMPLE
        $examplesText = Get-ResourceExampleAsText -ResourceName 'MyClassResource' -Path 'c:\MyProject'

        This example fetches all examples from the folder 'c:\MyProject\Examples\Resources\MyClassResource'
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

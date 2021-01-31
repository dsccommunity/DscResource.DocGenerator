<#
    .SYNOPSIS
        Get-ResourceExamplesAsText gathers all examples for a resource and returns
        them as a string in a format that is used for conceptual help.

    .DESCRIPTION
        Get-ResourceExamplesAsText gathers all examples for a resource and returns
        them as a string in a format that is used for conceptual help.

    .PARAMETER ResourceName
        The name of the resource for which examples should be retrieved.

    .PARAMETER SourcePath
        THe path to the source folder where the folder Examples exist.

    .EXAMPLE
        $examplesText = Get-ResourceExamplesAsText -ResourceName 'AzDevOpsProject' -SourcePath 'c:\MyProject'

        This example fetches all examples from the folder 'c:\MyProject\Examples\Resources\$AzDevOpsProject'
        and returns them as a single string in a format that is used for conceptual help.
#>
function Get-ResourceExamplesAsText
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ResourceName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SourcePath
    )

    $exampleSearchPath = "\Examples\Resources\$ResourceName\*.ps1"
    $examplesPath = (Join-Path -Path $SourcePath -ChildPath $exampleSearchPath)
    $exampleFiles = @(Get-ChildItem -Path $examplesPath -ErrorAction 'SilentlyContinue')

    if ($exampleFiles.Count -gt 0)
    {
        $exampleCount = 1

        Write-Verbose -Message ($script:localizedData.FoundResourceExamplesMessage -f $exampleFiles.count, $ResourceName)

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
        Write-Warning -Message ($script:localizedData.NoExampleFileFoundWarning -f $ResourceName)
    }

    return $text
}

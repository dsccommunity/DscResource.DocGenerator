<#
    .SYNOPSIS
        New-DscCompositeResourceWikiPage generates wiki pages for composite resources
        that can be uploaded to GitHub to use as public documentation for a module.

    .DESCRIPTION
        The New-DscCompositeResourceWikiPage cmdlet will review all of the composite and
        in a specified module directory and will output the Markdown files to the
        specified directory. These help files include details on the property types
        for each resource, as well as a text description and examples where they exist.

    .PARAMETER OutputPath
        Where should the files be saved to.

    .PARAMETER SourcePath
        The path to the root of the DSC resource module (where the PSD1 file is found,
        not the folder for and individual DSC resource).

    .PARAMETER BuiltModulePath
        The path to the root of the built DSC resource module, e.g.
        'output/MyResource/1.0.0'.

    .PARAMETER Force
        Overwrites any existing file when outputting the generated content.

    .EXAMPLE
        New-DscCompositeResourceWikiPage `
            -SourcePath C:\repos\MyResource\source `
            -BuiltModulePath C:\repos\MyResource\output\MyResource\1.0.0 `
            -OutputPath C:\repos\MyResource\output\WikiContent

        This example shows how to generate wiki documentation for a specific module.
#>
function New-DscCompositeResourceWikiPage
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $OutputPath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SourcePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $BuiltModulePath,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    $compositeSearchPath = Join-Path -Path $SourcePath -ChildPath '\**\*.schema.psm1'
    $compositeSchemaFiles = @(Get-ChildItem -Path $compositeSearchPath -Recurse)

    Write-Verbose -Message ($script:localizedData.FoundMofFilesMessage -f $compositeSchemaFiles.Count, $SourcePath)

    # Loop through all the Schema files found in the modules folder
    foreach ($compositeSchemaFile in $compositeSchemaFiles)
    {
        $compositeSchemaObject = Get-CompositeSchemaObject -FileName $compositeSchemaFile.FullName

        [System.Array] $readmeFile = Get-ChildItem -Path $compositeSchemaFile.DirectoryName |
            Where-Object -FilterScript {
                $_.Name -like 'readme.md'
            }

        if ($readmeFile.Count -eq 1)
        {
            Write-Verbose -Message ($script:localizedData.GenerateWikiPageMessage -f $compositeSchemaObject.Name)

            $output = New-Object -TypeName System.Text.StringBuilder

            $null = $output.AppendLine("# $($compositeSchemaObject.Name)")
            $null = $output.AppendLine('')
            $null = $output.AppendLine('## Parameters')
            $null = $output.AppendLine('')

            $propertyContent = Get-DscResourceSchemaPropertyContent -Property $compositeSchemaObject.Parameters -UseMarkdown

            foreach ($line in $propertyContent)
            {
                $null = $output.AppendLine($line)
            }

            $descriptionContent = Get-Content -Path $readmeFile.FullName -Raw

            # Change the description H1 header to an H2
            $descriptionContent = $descriptionContent -replace '# Description', '## Description'
            $null = $output.AppendLine()
            $null = $output.AppendLine($descriptionContent)

            $examplesPath = Join-Path -Path $SourcePath -ChildPath ('Examples\Resources\{0}' -f $compositeSchemaObject.Name)

            $examplesOutput = Get-ResourceExampleAsMarkdown -Path $examplesPath

            if ($examplesOutput.Length -gt 0)
            {
                $null = $output.Append($examplesOutput)
            }

            $outputFileName = "$($compositeSchemaObject.Name).md"
            $savePath = Join-Path -Path $OutputPath -ChildPath $outputFileName

            Write-Verbose -Message ($script:localizedData.OutputWikiPageMessage -f $savePath)

            $null = Out-File `
                -InputObject ($output.ToString() -replace '\r?\n', "`r`n") `
                -FilePath $savePath `
                -Encoding utf8 `
                -Force:$Force
        }
        elseif ($readmeFile.Count -gt 1)
        {
            Write-Warning -Message ($script:localizedData.MultipleDescriptionFileFoundWarning -f $compositeSchemaObject.Name, $readmeFile.Count)
        }
        else
        {
            Write-Warning -Message ($script:localizedData.NoDescriptionFileFoundWarning -f $compositeSchemaObject.Name)
        }
    }
}

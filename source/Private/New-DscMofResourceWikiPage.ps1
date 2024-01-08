<#
    .SYNOPSIS
        New-DscMofResourceWikiPage generates wiki pages for MOF-based resources
        that can be uploaded to GitHub to use as public documentation for a module.

    .DESCRIPTION
        The New-DscMofResourceWikiPage cmdlet will review all of the MOF-based and
        in a specified module directory and will output the Markdown files to the
        specified directory. These help files include details on the property types
        for each resource, as well as a text description and examples where they exist.

    .PARAMETER OutputPath
        Where should the files be saved to.

    .PARAMETER SourcePath
        The path to the root of the DSC resource module (where the PSD1 file is found,
        not the folder for and individual DSC resource).

    .PARAMETER Metadata
        Specifies metadata that is added to the markdown file.

    .PARAMETER Force
        Overwrites any existing file when outputting the generated content.

    .EXAMPLE
        New-DscMofResourceWikiPage `
            -SourcePath C:\repos\MyResource\source `
            -OutputPath C:\repos\MyResource\output\WikiContent

        This example shows how to generate wiki documentation for a specific module.

    .EXAMPLE
        New-DscMofResourceWikiPage `
            -SourcePath C:\repos\MyResource\source `
            -OutputPath C:\repos\MyResource\output\WikiContent `
            -Metadata @{
                Type = 'MofResource'
                Category = 'MOF-based resources'
            }

        This example shows how to generate wiki documentation for a specific module
        and passing in metadata for the markdown files.
#>
function New-DscMofResourceWikiPage
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

        [Parameter()]
        [System.Collections.Hashtable]
        $Metadata,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    $mofSearchPath = Join-Path -Path $SourcePath -ChildPath '\**\*.schema.mof'
    $mofSchemaFiles = @(Get-ChildItem -Path $mofSearchPath -Recurse)

    Write-Verbose -Message ($script:localizedData.FoundMofFilesMessage -f $mofSchemaFiles.Count, $SourcePath)

    # Loop through all the Schema files found in the modules folder
    foreach ($mofSchemaFile in $mofSchemaFiles)
    {
        $mofSchemas = Get-MofSchemaObject -FileName $mofSchemaFile.FullName

        $dscResourceName = $mofSchemaFile.Name.Replace('.schema.mof', '')

        <#
            In a resource with one or more embedded instances (CIM classes) this
            will get the main resource CIM class.
        #>
        $resourceSchema = $mofSchemas |
            Where-Object -FilterScript {
                ($_.ClassName -eq $dscResourceName) -and ($null -ne $_.FriendlyName)
            }

        [System.Array] $readmeFile = Get-ChildItem -Path $mofSchemaFile.DirectoryName |
            Where-Object -FilterScript {
                $_.Name -like 'readme.md'
            }

        if ($readmeFile.Count -eq 1)
        {
            Write-Verbose -Message ($script:localizedData.GenerateWikiPageMessage -f $resourceSchema.FriendlyName)

            $output = New-Object -TypeName System.Text.StringBuilder

            # Add metadata to the top of the file.
            if ($Metadata)
            {
                $null = $output.AppendLine('---')

                foreach ($key in ($Metadata.Keys | Sort-Object))
                {
                    $null = $output.AppendLine("$($key): $($Metadata.$key)")
                }

                $null = $output.AppendLine('---')
                $null = $output.AppendLine()
            }

            # Add the documentation for the resource.
            $null = $output.AppendLine("# $($resourceSchema.FriendlyName)")
            $null = $output.AppendLine('')
            $null = $output.AppendLine('## Parameters')
            $null = $output.AppendLine('')

            $propertyContent = Get-DscResourceSchemaPropertyContent -Property $resourceSchema.Attributes -UseMarkdown

            foreach ($line in $propertyContent)
            {
                $null = $output.AppendLine($line)
            }

            <#
                In a resource with one or more embedded instances (CIM classes) this
                will get the embedded instances (CIM classes).
            #>
            $embeddedSchemas = $mofSchemas |
                Where-Object -FilterScript {
                    ($_.ClassName -ne $dscResourceName)
                }

            foreach ($embeddedSchema in $embeddedSchemas)
            {
                $null = $output.AppendLine()
                $null = $output.AppendLine("### $($embeddedSchema.ClassName)")
                $null = $output.AppendLine('')
                $null = $output.AppendLine('#### Parameters')
                $null = $output.AppendLine('')

                $propertyContent = Get-DscResourceSchemaPropertyContent -Property $embeddedSchema.Attributes -UseMarkdown

                foreach ($line in $propertyContent)
                {
                    $null = $output.AppendLine($line)
                }
            }

            $descriptionContent = Get-Content -Path $readmeFile.FullName -Raw

            # Change the description H1 header to an H2
            $descriptionContent = $descriptionContent -replace '# Description', '## Description'
            $null = $output.AppendLine()
            $null = $output.AppendLine($descriptionContent)

            $examplesPath = Join-Path -Path $SourcePath -ChildPath ('Examples\Resources\{0}' -f $resourceSchema.FriendlyName)

            $examplesOutput = Get-ResourceExampleAsMarkdown -Path $examplesPath

            if ($examplesOutput.Length -gt 0)
            {
                $null = $output.Append($examplesOutput)
            }

            $outputFileName = "$($resourceSchema.FriendlyName).md"
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
            Write-Warning -Message ($script:localizedData.MultipleDescriptionFileFoundWarning -f $resourceSchema.FriendlyName, $readmeFile.Count)
        }
        else
        {
            Write-Warning -Message ($script:localizedData.NoDescriptionFileFoundWarning -f $resourceSchema.FriendlyName)
        }
    }
}

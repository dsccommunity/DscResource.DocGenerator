<#
    .SYNOPSIS
        New-DscResourceWikiPage generates wiki pages that can be uploaded to GitHub
        to use as public documentation for a module.

    .DESCRIPTION
        The New-DscResourceWikiPage cmdlet will review all of the MOF based resources
        in a specified module directory and will output the Markdown files to the
        specified directory. These help files include details on the property types
        for each resource, as well as a text description and examples where they exist.

    .PARAMETER OutputPath
        Where should the files be saved to

    .PARAMETER ModulePath
        The path to the root of the DSC resource module (where the PSD1 file is found,
        not the folder for and individual DSC resource)

    .EXAMPLE
        New-DscResourceWikiPage `
            -ModulePath C:\repos\SharePointDsc\source `
            -OutputPath C:\repos\SharePointDsc\output\WikiContent

        This example shows how to generate help for a specific module
#>
function New-DscResourceWikiPage
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $OutputPath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ModulePath
    )

    $mofSearchPath = Join-Path -Path $ModulePath -ChildPath '\**\*.schema.mof'
    $mofSchemaFiles = @(Get-ChildItem -Path $mofSearchPath -Recurse)

    Write-Verbose -Message ($script:localizedData.FoundMofFilesMessage -f $mofSchemaFiles.Count, $ModulePath)

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

            $null = $output.AppendLine("# $($resourceSchema.FriendlyName)")
            $null = $output.AppendLine('')
            $null = $output.AppendLine('## Parameters')
            $null = $output.AppendLine('')

            $propertyContent = Get-DscResourceSchemaPropertyContent -Property $resourceSchema.Attributes

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

                $propertyContent = Get-DscResourceSchemaPropertyContent -Property $embeddedSchema.Attributes

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

            $exampleSearchPath = "\Examples\Resources\$($resourceSchema.FriendlyName)\*.ps1"
            $examplesPath = (Join-Path -Path $ModulePath -ChildPath $exampleSearchPath)
            $exampleFiles = @(Get-ChildItem -Path $examplesPath -ErrorAction SilentlyContinue)

            if ($exampleFiles.Count -gt 0)
            {
                $null = $output.AppendLine('## Examples')
                $exampleCount = 1

                foreach ($exampleFile in $exampleFiles)
                {
                    Write-Verbose -Message "Adding Example file '$($exampleFile.Name)' to wiki page for $($resourceSchema.FriendlyName)"

                    $exampleContent = Get-DscResourceWikiExampleContent `
                        -ExamplePath $exampleFile.FullName `
                        -ExampleNumber ($exampleCount++)

                    $null = $output.AppendLine()
                    $null = $output.AppendLine($exampleContent)
                }
            }
            else
            {
                Write-Warning -Message ($script:localizedData.NoExampleFileFoundWarning -f $resourceSchema.FriendlyName)
            }

            $outputFileName = "$($resourceSchema.FriendlyName).md"
            $savePath = Join-Path -Path $OutputPath -ChildPath $outputFileName

            Write-Verbose -Message ($script:localizedData.OutputWikiPageMessage -f $savePath)

            $null = Out-File `
                -InputObject ($output.ToString() -replace '\r?\n', "`r`n") `
                -FilePath $savePath `
                -Encoding utf8 `
                -Force
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

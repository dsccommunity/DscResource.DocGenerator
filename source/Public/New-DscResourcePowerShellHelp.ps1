<#
    .SYNOPSIS
        New-DscResourcePowerShellHelp generates PowerShell compatible help files
        for a DSC resource module

    .DESCRIPTION
        The New-DscResourcePowerShellHelp cmdlet will review all of the MOF based
        resources in a specified module directory and will inject PowerShell help
        files for each resource. These help files include details on the property
        types for each resource, as well as a text description and examples where
        they exist.

        The help files are output to the OutputPath directory if specified. If not,
        they are output to the relevant resource's 'en-US' directory either in the
        path set by 'ModulePath' or to 'DestinationModulePath' if set.

        A README.md with a text description must exist in the resource's subdirectory
        for the help file to be generated. To get examples added to the conceptual
        help the examples must be present in an individual resource example folder,
        e.g. 'Examples/Resources/<ResourceName>/1-Example.ps1'. Prefixing the value
        with a number will sort the examples in that order.

        These help files can then be read by passing the name of the resource as a
        parameter to Get-Help.

    .PARAMETER ModulePath
        The path to the root of the DSC resource module (where the PSD1 file is
        found). In this path the folder DSCResources must be present.

    .PARAMETER DestinationModulePath
        The destination module path can be used to set the path where module is
        built before being deployed. This must be set to the root of the built
        module, e.g 'c:\repos\ModuleName\output\ModuleName\1.0.0'.
        If OutputPath is also used at the same time that will override this path.

    .PARAMETER OutputPath
        The output path can be used to set the path where all the generated files
        will be saved (all files to the same path).

    .PARAMETER MarkdownCodeRegularExpression
        An array of regular expressions that should be used to parse the parameter
        descriptions in the schema MOF. Each regular expression must be written
        so that the capture group 0 is the full match and the capture group 1 is
        the text that should be kept.

    .EXAMPLE
        New-DscResourcePowerShellHelp -ModulePath C:\repos\SharePointDsc

        This example shows how to generate help for a specific module

    .EXAMPLE
        New-DscResourcePowerShellHelp -ModulePath C:\repos\SharePointDsc -DestinationModulePath C:\repos\SharePointDsc\output\SharePointDsc\1.0.0

        This example shows how to generate help for a specific module and output
        the result to a built module.

    .EXAMPLE
        New-DscResourcePowerShellHelp -ModulePath C:\repos\SharePointDsc -OutputPath C:\repos\SharePointDsc\en-US

        This example shows how to generate help for a specific module and output
        all the generated files to the same output path.

    .NOTES
        Line endings are hard-coded to CRLF to handle different platforms similar.
#>
function New-DscResourcePowerShellHelp
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ModulePath,

        [Parameter()]
        [System.String]
        $DestinationModulePath,

        [Parameter()]
        [System.String]
        $OutputPath,

        [Parameter()]
        [System.String[]]
        $MarkdownCodeRegularExpression = @()
    )

    $mofSearchPath = (Join-Path -Path $ModulePath -ChildPath '\**\*.schema.mof')
    $mofSchemas = @(Get-ChildItem -Path $mofSearchPath -Recurse)

    Write-Verbose -Message ($script:localizedData.FoundMofFilesMessage -f $mofSchemas.Count, $ModulePath)

    foreach ($mofSchema in $mofSchemas)
    {
        $result = (Get-MofSchemaObject -FileName $mofSchema.FullName) | Where-Object -FilterScript {
            ($_.ClassName -eq $mofSchema.Name.Replace('.schema.mof', '')) `
                -and ($null -ne $_.FriendlyName)
        }

        $descriptionPath = Join-Path -Path $mofSchema.DirectoryName -ChildPath 'readme.md'

        if (Test-Path -Path $descriptionPath)
        {
            Write-Verbose -Message ($script:localizedData.GenerateHelpDocumentMessage -f $result.FriendlyName)

            $output = ".NAME`r`n"
            $output += "    $($result.FriendlyName)"
            $output += "`r`n`r`n"

            $descriptionContent = Get-Content -Path $descriptionPath -Raw
            $descriptionContent = $descriptionContent -replace '\r?\n', "`r`n"

            $descriptionContent = $descriptionContent -replace '\r\n', "`r`n    "
            $descriptionContent = $descriptionContent -replace '# Description\r\n    ', ".DESCRIPTION"
            $descriptionContent = $descriptionContent -replace '\r\n\s{4}\r\n', "`r`n`r`n"
            $descriptionContent = $descriptionContent -replace '\s{4}$', ''

            $output += $descriptionContent
            $output += "`r`n"

            foreach ($property in $result.Attributes)
            {
                $output += ".PARAMETER $($property.Name)`r`n"
                $output += "    $($property.State) - $($property.DataType)"
                $output += "`r`n"

                if ([string]::IsNullOrEmpty($property.ValueMap) -ne $true)
                {
                    $output += "    Allowed values: "

                    $property.ValueMap | ForEach-Object {
                        $output += $_ + ", "
                    }

                    $output = $output.TrimEnd(" ")
                    $output = $output.TrimEnd(",")
                    $output += "`r`n"
                }

                $propertyDescription = $property.Description

                if ($MarkdownCodeRegularExpression.Count -gt 0)
                {
                    foreach ($parseRegularExpression in $MarkdownCodeRegularExpression)
                    {
                        $allMatches = $propertyDescription | Select-String -Pattern $parseRegularExpression -AllMatches

                        foreach ($regularExpressionMatch in $allMatches.Matches)
                        {
                            <#
                                Always assume the group 0 is the full match and
                                the group 1 contain what we should replace with.
                            #>
                            $propertyDescription = $propertyDescription -replace @(
                                [RegEx]::Escape($regularExpressionMatch.Groups[0].Value),
                                $regularExpressionMatch.Groups[1].Value
                            )
                        }
                    }
                }

                $output += "    " + $propertyDescription
                $output += "`r`n`r`n"
            }

            $exampleSearchPath = "\Examples\Resources\$($result.FriendlyName)\*.ps1"
            $examplesPath = (Join-Path -Path $ModulePath -ChildPath $exampleSearchPath)
            $exampleFiles = @(Get-ChildItem -Path $examplesPath -ErrorAction SilentlyContinue)

            if ($exampleFiles.Count -gt 0)
            {
                $exampleCount = 1

                Write-Verbose -Message "Found $($exampleFiles.count) Examples for resource $($result.FriendlyName)"

                foreach ($exampleFile in $exampleFiles)
                {
                    $exampleContent = Get-DscResourceHelpExampleContent `
                        -ExamplePath $exampleFile.FullName `
                        -ExampleNumber ($exampleCount++)

                    $exampleContent = $exampleContent -replace '\r?\n', "`r`n"

                    $output += $exampleContent
                    $output += "`r`n"
                }
            }
            else
            {
                Write-Warning -Message ($script:localizedData.NoExampleFileFoundWarning -f $result.FriendlyName)
            }

            $outputFileName = "about_$($result.FriendlyName).help.txt"

            if ($PSBoundParameters.ContainsKey('OutputPath'))
            {
                # Output to $OutputPath if specified.
                $savePath = Join-Path -Path $OutputPath -ChildPath $outputFileName
            }
            elseif ($PSBoundParameters.ContainsKey('DestinationModulePath'))
            {
                # Output to the resource 'en-US' directory in the DestinationModulePath.
                $null = $mofSchema.DirectoryName -match '(.+)(DSCResources|DSCClassResources)(.+)'
                $resourceRelativePath = $matches[3]
                $dscRootFolderName = $matches[2]

                $savePath = Join-Path -Path $DestinationModulePath -ChildPath $dscRootFolderName |
                    Join-Path -ChildPath $resourceRelativePath |
                    Join-Path -ChildPath 'en-US' |
                    Join-Path -ChildPath $outputFileName
            }
            else
            {
                # Output to the resource 'en-US' directory in the ModulePath.
                $savePath = Join-Path -Path $mofSchema.DirectoryName -ChildPath 'en-US' |
                    Join-Path -ChildPath $outputFileName
            }

            Write-Verbose -Message ($script:localizedData.OutputHelpDocumentMessage -f $savePath)

            $output | Out-File -FilePath $savePath -Encoding 'ascii' -Force
        }
        else
        {
            Write-Warning -Message ($script:localizedData.NoDescriptionFileFoundWarning -f $result.FriendlyName)
        }
    }
}

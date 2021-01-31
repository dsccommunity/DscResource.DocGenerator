<#
    .SYNOPSIS
        New-DscResourcePowerShellHelp generates PowerShell compatible help files
        for a DSC resource module.

    .DESCRIPTION
        The New-DscResourcePowerShellHelp generates PowerShell compatible help files
        for a DSC resource module.

        The command will review all of the MOF- and class based resources in a
        specified module directory and will inject PowerShell help files for each
        resource. These help files include details on the property types for each
        resource,  as well as a text description and examples where they exist.

        The help files are output to the OutputPath directory if specified. If not,
        they are output to the relevant resource's 'en-US' directory either in the
        path set by 'ModulePath' or to 'DestinationModulePath' if set.

        For MOF-based resources a README.md with a text description must exist in
        the resource's subdirectory for the help file to be generated. For class-based
        resources each DscResource should have their own file in the Classes folder
        (using the template of the Sampler project).

        To get examples added to the conceptual help the examples must be present
        in an individual resource example folder, e.g.
        'Examples/Resources/<ResourceName>/1-Example.ps1'. Prefixing the value
        with a number will sort the examples in that order.

        These help files can then be read by passing the name of the resource as a
        parameter to Get-Help.

    .PARAMETER ModulePath
        The path to the root of the DSC resource module where the PSD1 file is
        found, for example the folder 'source'. If there are MOF-based resource
        there should be a 'DSCResources' child folder in this path. If using
        class-based resources there should be a 'Classes' child folder in this path.

    .PARAMETER DestinationModulePath
        The destination module path can be used to set the path where module is
        built before being deployed. This must be set to the root of the built
        module, e.g 'c:\repos\ModuleName\output\ModuleName\1.0.0'.

        The conceptual help file will be saved in this path. For MOF-based resources
        it will be saved to the en-US folder that is inside in either the DSCResources
        or DSCClassResources folder (if using that pattern for class-based resources).

        When using the pattern with having all powershell classes in the same
        module script file (.psm1) and all class-based resource are found in that
        file (not using DSCClassResources). This path will be used to find the
        built module when generating conceptual help for class-based resource.
        It will also be used to save the conceptual help to the built modules
        en-US folder.

        If OutputPath is assigned that will be used for saving the output instead.

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

    #region MOF-based resource
    $mofSearchPath = (Join-Path -Path $ModulePath -ChildPath '\**\*.schema.mof')
    $mofSchemas = @(Get-ChildItem -Path $mofSearchPath -Recurse)

    Write-Verbose -Message ($script:localizedData.FoundMofFilesMessage -f $mofSchemas.Count, $ModulePath)

    foreach ($mofSchema in $mofSchemas)
    {
        $result = (Get-MofSchemaObject -FileName $mofSchema.FullName) | Where-Object -FilterScript {
            ($_.ClassName -eq $mofSchema.Name.Replace('.schema.mof', '')) `
                -and ($null -ne $_.FriendlyName)
        }

        # This is a workaround for issue #42.
        $readMeFile = Get-ChildItem -Path $mofSchema.DirectoryName -ErrorAction 'SilentlyContinue' |
            Where-Object -FilterScript {
                $_.Name -like 'readme.md'
            }

        if ($readMeFile)
        {
            $descriptionPath = $readMeFile.FullName

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

                if (-not [System.String]::IsNullOrEmpty($property.Description))
                {
                    $propertyDescription = Get-TextWithoutMarkdownCode -Text $property.Description -MarkdownCodeRegularExpression $MarkdownCodeRegularExpression
                }

                $output += "    " + $propertyDescription
                $output += "`r`n`r`n"
            }

            $exampleContent = Get-ResourceExamplesAsText -SourcePath $ModulePath -ResourceName $result.FriendlyName

            $output += $exampleContent

            # Trim excessive blank lines and indents at the end.
            $output = $output -replace '[\r|\n|\s]+$', "`r`n"

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
    #endregion MOF-based resource

    #region Class-based resource
    if (-not [System.String]::IsNullOrEmpty($DestinationModulePath) -and (Test-Path -Path $DestinationModulePath))
    {
        $getChildItemParameters = @{
            Path = Join-Path -Path $DestinationModulePath -ChildPath '*'
            Include = '*.psm1'
            ErrorAction = 'Stop'
        }

        $builtModuleScriptFiles = Get-ChildItem @getChildItemParameters

        # Looping through each module file (normally just one).
        foreach ($builtModuleScriptFile in $builtModuleScriptFiles)
        {
            $tokens, $parseErrors = $null

            $ast = [System.Management.Automation.Language.Parser]::ParseFile($builtModuleScriptFile.FullName, [ref] $tokens, [ref] $parseErrors)

            if ($parseErrors)
            {
                throw $parseErrors
            }

            $astFilter = {
                $args[0] -is [System.Management.Automation.Language.TypeDefinitionAst] `
                -and $args[0].IsClass -eq $true `
                -and $args[0].Attributes.Extent.Text -ieq '[DscResource()]'
            }

            $dscResourceAsts = $ast.FindAll($astFilter, $true)

            Write-Verbose -Message ($script:localizedData.FoundClassBasedMessage -f $dscResourceAsts.Count, $builtModuleScriptFile.FullName)

            # Looping through each class-based resource.
            foreach ($dscResourceAst in $dscResourceAsts)
            {
                Write-Verbose -Message ($script:localizedData.GenerateHelpDocumentMessage -f $dscResourceAst.Name)

                <#
                    PowerShell classes does not support comment-based help. There is
                    no GetHelpContent() on the TypeDefinitionAst.

                    We use the ScriptBlockAst to filter out our class-based resource
                    script block from the source file and use that to get the
                    comment-based help.
                #>
                $sourceFilePath = Join-Path -Path $ModulePath -ChildPath ('Classes/*{0}.ps1' -f $dscResourceAst.Name)
                $sourceFilePath = Resolve-Path -Path $sourceFilePath

                Write-Verbose -Message ($script:localizedData.ClassBasedCommentBasedHelpMessage -f $sourceFilePath)

                $ast = [System.Management.Automation.Language.Parser]::ParseFile($sourceFilePath, [ref] $tokens, [ref] $parseErrors)

                $dscResourceCommentBasedHelp = $ast.GetHelpContent()

                $synopsis = $dscResourceCommentBasedHelp.Synopsis
                $synopsis = $synopsis -replace '[\r|\n]+$' # Removes all blank rows at the end
                $synopsis = $synopsis -replace '\r?\n', "`r`n" # Normalize to CRLF
                $synopsis = $synopsis -replace '\r\n', "`r`n    " # Indent all rows

                $description = $dscResourceCommentBasedHelp.Description
                $description = $description -replace '[\r|\n]+$' # Removes all blank rows at the end
                $description = $description -replace '\r?\n', "`r`n" # Normalize to CRLF
                $description = $description -replace '\r\n', "`r`n    " # Indent all rows

                $output = ".NAME`r`n"
                $output += '    {0}' -f $dscResourceAst.Name
                $output += "`r`n`r`n"
                $output += ".SYNOPSIS`r`n"
                $output += '    {0}' -f $synopsis
                $output += "`r`n`r`n"
                $output += ".DESCRIPTION`r`n"
                $output += '    {0}' -f $description
                $output += "`r`n`r`n"

                $astFilter = {
                    $args[0] -is [System.Management.Automation.Language.PropertyMemberAst]
                }

                $propertyMemberAsts = $dscResourceAst.FindAll($astFilter, $true)

                # Looping through each resource property.
                foreach ($propertyMemberAst in $propertyMemberAsts)
                {
                    Write-Verbose -Message ($script:localizedData.FoundClassResourcePropertyMessage -f $propertyMemberAst.Name, $dscResourceAst.Name)

                    $astFilter = {
                        $args[0] -is [System.Management.Automation.Language.NamedAttributeArgumentAst]
                    }

                    $propertyNamedAttributeArgumentAsts = $propertyMemberAst.FindAll($astFilter, $true)

                    $isKeyProperty = 'Key' -in $propertyNamedAttributeArgumentAsts.ArgumentName
                    $isMandatoryProperty = 'Mandatory' -in $propertyNamedAttributeArgumentAsts.ArgumentName
                    $isReadProperty = 'NotConfigurable' -in $propertyNamedAttributeArgumentAsts.ArgumentName

                    if ($isKeyProperty)
                    {
                        $propertyState = 'Key'
                    }
                    elseif ($isMandatoryProperty)
                    {
                        $propertyState = 'Required'
                    }
                    elseif ($isReadProperty)
                    {
                        $propertyState = 'Read'
                    }
                    else
                    {
                        $propertyState = 'Write'
                    }

                    $output += ".PARAMETER {0}`r`n" -f $propertyMemberAst.Name
                    $output += '    {0} - {1}' -f $propertyState, $propertyMemberAst.PropertyType.TypeName.FullName
                    $output += "`r`n"

                    $astFilter = {
                        $args[0] -is [System.Management.Automation.Language.AttributeAst] `
                        -and $args[0].TypeName.Name -eq 'ValidateSet'
                    }

                    $propertyAttributeAsts = $propertyMemberAst.FindAll($astFilter, $true)

                    if ($propertyAttributeAsts)
                    {
                        $output += "    Allowed values: {0}" -f ($propertyAttributeAsts.PositionalArguments.Value -join ', ')
                        $output += "`r`n"
                    }

                    # The key name must be upper-case for it to match the right item in the list of parameters.
                    $propertyDescription = ($dscResourceCommentBasedHelp.Parameters[$propertyMemberAst.Name.ToUpper()] -replace '[\r|\n]+$')

                    $propertyDescription = $propertyDescription -replace '[\r|\n]+$' # Removes all blank rows at the end
                    $propertyDescription = $propertyDescription -replace '\r?\n', "`r`n" # Normalize to CRLF
                    $propertyDescription = $propertyDescription -replace '\r\n', "`r`n    " # Indent all rows

                    if (-not [System.String]::IsNullOrEmpty($propertyDescription))
                    {
                        $propertyDescription = Get-TextWithoutMarkdownCode -Text $propertyDescription -MarkdownCodeRegularExpression $MarkdownCodeRegularExpression

                        $output += "    {0}" -f $propertyDescription
                        $output += "``r`n"
                    }

                    $output += "`r`n"
                }

                $exampleContent = Get-ResourceExamplesAsText -SourcePath $ModulePath -ResourceName $dscResourceAst.Name

                $output += $exampleContent

                # Trim excessive blank lines and indents at the end.
                $output = $output -replace '[\r|\n|\s]+$', "`r`n"

                $outputFileName = 'about_{0}.help.txt' -f $dscResourceAst.Name

                if ($PSBoundParameters.ContainsKey('OutputPath'))
                {
                    # Output to $OutputPath if specified.
                    $savePath = Join-Path -Path $OutputPath -ChildPath $outputFileName
                }
                elseif ($PSBoundParameters.ContainsKey('DestinationModulePath'))
                {
                    # Output to the built modules en-US folder.
                    $savePath = Join-Path -Path $DestinationModulePath -ChildPath 'en-US' |
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
        }
    }
    #endregion Class-based resource
}

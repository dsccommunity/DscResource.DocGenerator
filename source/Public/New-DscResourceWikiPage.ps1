<#
    .SYNOPSIS
        New-DscResourceWikiPage generates wiki pages that can be uploaded to GitHub
        to use as public documentation for a module.

    .DESCRIPTION
        The New-DscResourceWikiPage cmdlet will review all of the MOF-based and
        class-based resources in a specified module directory and will output the
        Markdown files to the specified directory. These help files include details
        on the property types for each resource, as well as a text description and
        examples where they exist.

    .PARAMETER OutputPath
        Where should the files be saved to.

    .PARAMETER SourcePath
        The path to the root of the DSC resource module (where the PSD1 file is found,
        not the folder for and individual DSC resource).

    .PARAMETER BuiltModulePath
        The path to the root of the built DSC resource module, e.g.
        'output/MyResource/1.0.0'.

    .EXAMPLE
        New-DscResourceWikiPage `
            -SourcePath C:\repos\MyResource\source `
            -BuiltModulePath C:\repos\MyResource\output\MyResource\1.0.0 `
            -OutputPath C:\repos\MyResource\output\WikiContent

        This example shows how to generate wiki documentation for a specific module.
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
        $SourcePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $BuiltModulePath,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    #region MOF-based resource
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

            $examplesPath = Join-Path -Path $SourcePath -ChildPath ('Examples\Resources\{0}' -f $resourceSchema.FriendlyName)

            $examplesOutput = Get-ResourceExampleAsMarkdown -Path $examplesPath

            if($examplesOutput.Length -gt 0)
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
    #endregion MOF-based resource

    #region Class-based resource
    if (Test-Path -Path $BuiltModulePath)
    {
        <#
            This must not use Recurse. Then it could potentially find resources
            that are part of common modules in the Modules folder.
        #>
        $getChildItemParameters = @{
            Path        = Join-Path -Path $BuiltModulePath -ChildPath '*'
            Include     = '*.psm1'
            ErrorAction = 'Stop'
            File        = $true
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
                    -and $args[0].Attributes.Extent.Text -imatch '\[DscResource\(.*\)\]'
            }

            $dscResourceAsts = $ast.FindAll($astFilter, $true)

            Write-Verbose -Message ($script:localizedData.FoundClassBasedMessage -f $dscResourceAsts.Count, $builtModuleScriptFile.FullName)

            # Looping through each class-based resource.
            foreach ($dscResourceAst in $dscResourceAsts)
            {
                Write-Verbose -Message ($script:localizedData.GenerateWikiPageMessage -f $dscResourceAst.Name)

                $output = New-Object -TypeName 'System.Text.StringBuilder'

                $null = $output.AppendLine("# $($dscResourceAst.Name)")
                $null = $output.AppendLine()
                $null = $output.AppendLine('## Parameters')
                $null = $output.AppendLine()

                $sourceFilePath = Join-Path -Path $SourcePath -ChildPath ('Classes/*{0}.ps1' -f $dscResourceAst.Name)

                $dscResourceCommentBasedHelp = Get-ClassResourceCommentBasedHelp -Path $sourceFilePath

                $astFilter = {
                    $args[0] -is [System.Management.Automation.Language.PropertyMemberAst]
                }

                $propertyMemberAsts = $dscResourceAst.FindAll($astFilter, $true)

                $resourceProperty = @()

                <#
                    Looping through each resource property to build the hashtable
                    that should be passed to Get-DscResourceSchemaPropertyContent.
                    Hashtable should be in the format:

                    @{
                        Name             = <System.String>
                        State            = 'Key' | 'Required' |'Write' | 'Read'
                        Description      = <System.String>
                        EmbeddedInstance = 'MSFT_Credential' | $null
                        DataType         = 'System.String' | 'System.String[] | etc.
                        IsArray          = $true | $false
                        ValueMap         = @(<System.String> | ...)
                    }
                #>
                foreach ($propertyMemberAst in $propertyMemberAsts)
                {
                    Write-Verbose -Message ($script:localizedData.FoundClassResourcePropertyMessage -f $propertyMemberAst.Name, $dscResourceAst.Name)

                    $propertyAttribute = @{
                        Name             = $propertyMemberAst.Name
                        DataType         = $propertyMemberAst.PropertyType.TypeName.FullName

                        # Always set to null, correct type name is set in DataType.
                        EmbeddedInstance = $null

                        # Always set to $false - correct type name is set in DataType.
                        IsArray          = $false
                    }

                    $propertyAttribute['State'] = Get-ClassResourcePropertyState -Ast $propertyMemberAst

                    $astFilter = {
                        $args[0] -is [System.Management.Automation.Language.AttributeAst] `
                            -and $args[0].TypeName.Name -eq 'ValidateSet'
                    }

                    $propertyAttributeAsts = $propertyMemberAst.FindAll($astFilter, $true)

                    if ($propertyAttributeAsts)
                    {
                        $propertyAttribute['ValueMap'] = $propertyAttributeAsts.PositionalArguments.Value
                    }

                    # The key name must be upper-case for it to match the right item in the list of parameters.
                    $propertyDescription = ($dscResourceCommentBasedHelp.Parameters[$propertyMemberAst.Name.ToUpper()] -replace '[\r|\n]+$')

                    $propertyDescription = $propertyDescription -replace '[\r|\n]+$' # Removes all blank rows at the end
                    $propertyDescription = $propertyDescription -replace '[ ]+\r\n', "`r`n" # Remove indentation from blank rows
                    $propertyDescription = $propertyDescription -replace '\r?\n', " " # Replace CRLF with one white space
                    $propertyDescription = $propertyDescription -replace '\|', " " # Replace vertical bar with white space
                    $propertyDescription = $propertyDescription -replace '  +', " " # Replace multiple whitespace with one single white space
                    $propertyDescription = $propertyDescription -replace ' +$' # Remove white space from end of row

                    $propertyAttribute['Description'] = $propertyDescription

                    $resourceProperty += $propertyAttribute
                }

                $propertyContent = Get-DscResourceSchemaPropertyContent -Property $resourceProperty

                foreach ($line in $propertyContent)
                {
                    $null = $output.AppendLine($line)
                }

                $null = $output.AppendLine()

                $description = $dscResourceCommentBasedHelp.Description
                $description = $description -replace '[\r|\n]+$' # Removes all blank rows and whitespace at the end

                $null = $output.AppendLine('## Description')
                $null = $output.AppendLine()
                $null = $output.AppendLine($description)
                $null = $output.AppendLine()

                $examplesPath = Join-Path -Path $SourcePath -ChildPath ('Examples\Resources\{0}' -f $dscResourceAst.Name)

                $examplesOutput = Get-ResourceExampleAsMarkdown -Path $examplesPath

                if($examplesOutput.Length -gt 0)
                {
                    $null = $output.Append($examplesOutput)
                }

                $outputFileName = '{0}.md' -f $dscResourceAst.Name

                $savePath = Join-Path -Path $OutputPath -ChildPath $outputFileName

                Write-Verbose -Message ($script:localizedData.OutputWikiPageMessage -f $savePath)

                $outputToWrite = $output.ToString()
                $outputToWrite = $outputToWrite -replace '[\r|\n]+$' # Removes all blank rows and whitespace at the end
                $outputToWrite = $outputToWrite -replace '\r?\n', "`r`n" # Normalize to CRLF
                $outputToWrite = $outputToWrite -replace '[ ]+\r\n', "`r`n" # Remove indentation from blank rows

                $null = Out-File `
                    -InputObject $outputToWrite `
                    -FilePath $savePath `
                    -Encoding utf8 `
                    -Force:$Force
            }
        }
    }
    #endregion Class-based resource
}

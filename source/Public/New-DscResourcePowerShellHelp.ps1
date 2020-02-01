<#
    .SYNOPSIS
        New-DscResourcePowerShellHelp generates PowerShell compatible help files for a DSC
        resource module

    .DESCRIPTION
        The New-DscResourcePowerShellHelp cmdlet will review all of the MOF based resources
        in a specified module directory and will inject PowerShell help files for each resource.
        These help files include details on the property types for each resource, as well as a text
        description and examples where they exist.

        The help files are output to the OutputPath directory if specified, or if not, they are
        output to the releveant resource's 'en-US' directory.

        A README.md with a text description must exist in the resource's subdirectory for the
        help file to be generated.

        These help files can then be read by passing the name of the resource as a parameter to Get-Help.

    .PARAMETER ModulePath
        The path to the root of the DSC resource module (where the PSD1 file is found, not the folder for
        each individual DSC resource)

    .EXAMPLE
        This example shows how to generate help for a specific module

        New-DscResourcePowerShellHelp -ModulePath C:\repos\SharePointDsc

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
        $OutputPath
    )

    $mofSearchPath = (Join-Path -Path $ModulePath -ChildPath '\**\*.schema.mof')
    $mofSchemas = @(Get-ChildItem -Path $mofSearchPath -Recurse)

    Write-Verbose -Message ($script:localizedData.FoundMofFilesMessage -f $mofSchemas.Count, $ModulePath)

    $mofSchemas | ForEach-Object {
        $mofFileObject = $_

        $result = (Get-MofSchemaObject -FileName $_.FullName) | Where-Object -FilterScript {
            ($_.ClassName -eq $mofFileObject.Name.Replace('.schema.mof', '')) `
                -and ($null -ne $_.FriendlyName)
        }

        $descriptionPath = Join-Path -Path $mofFileObject.DirectoryName -ChildPath 'readme.md'

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
                $output += "    " + $property.Description
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

            # Output to $OutputPath if specified or the resource 'en-US' directory if not.
            $outputFileName = "about_$($result.FriendlyName).help.txt"
            if ($OutputPath)
            {
                $savePath = Join-Path -Path $OutputPath -ChildPath $outputFileName
            }
            else
            {
                $savePath = Join-Path -Path $mofFileObject.DirectoryName -ChildPath 'en-US' | Join-Path -ChildPath $outputFileName
            }

            Write-Verbose -Message ($script:localizedData.OutputHelpDocumentMessage -f $savePath)

            $output | Out-File -FilePath $savePath -Encoding ascii -Force
        }
        else
        {
            Write-Warning -Message ($script:localizedData.NoDescriptionFileFoundWarning -f $result.FriendlyName)
        }
    }
}


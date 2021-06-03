<#
    .SYNOPSIS
        Returns DSC class resource properties from the provided class or classes.

    .PARAMETER SourcePath
        The path to the source folder (in which the child folder 'Classes' exist).

    .PARAMETER BuiltModuleScriptFilePath
        The path to the built module script file that contains the class.

    .PARAMETER ClassName
        One or more class names to return properties for.

    .EXAMPLE
        Get-ClassResourceProperty -ClassName @('myParentClass', 'myClass') -BuiltModuleScriptFilePath '.\output\MyModule\1.0.0\MyModule.psm1' -SourcePath '.\source'

        Returns all DSC class resource properties.
#>
function Get-ClassResourceProperty
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $SourcePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $BuiltModuleScriptFilePath,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $ClassName
    )

    $resourceProperty = [System.Collections.Hashtable[]] @()

    foreach ($currentClassName in $ClassName)
    {
        $dscResourceAst = Get-ClassAst -ClassName $currentClassName -ScriptFile $BuiltModuleScriptFilePath

        $sourceFilePath = Join-Path -Path $SourcePath -ChildPath ('Classes/*{0}.ps1' -f $currentClassName)

        $dscResourceCommentBasedHelp = Get-ClassResourceCommentBasedHelp -Path $sourceFilePath

        $astFilter = {
            $args[0] -is [System.Management.Automation.Language.PropertyMemberAst] `
            -and $args[0].Attributes.TypeName.Name -eq 'DscProperty'
        }

        $propertyMemberAsts = $dscResourceAst.FindAll($astFilter, $true)

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

            if ($dscResourceCommentBasedHelp -and $dscResourceCommentBasedHelp.Parameters.Count -gt 0)
            {
                # The key name must be upper-case for it to match the right item in the list of parameters.
                $propertyDescription = ($dscResourceCommentBasedHelp.Parameters[$propertyMemberAst.Name.ToUpper()] -replace '[\r|\n]+$')

                $propertyDescription = $propertyDescription -replace '[\r|\n]+$' # Removes all blank rows at the end
                $propertyDescription = $propertyDescription -replace '[ ]+\r\n', "`r`n" # Remove indentation from blank rows
                $propertyDescription = $propertyDescription -replace '\r?\n', " " # Replace CRLF with one white space
                $propertyDescription = $propertyDescription -replace '\|', " " # Replace vertical bar with white space
                $propertyDescription = $propertyDescription -replace '  +', " " # Replace multiple whitespace with one single white space
                $propertyDescription = $propertyDescription -replace ' +$' # Remove white space from end of row
            }
            else
            {
                $propertyDescription = ''
            }

            $propertyAttribute['Description'] = $propertyDescription

            $resourceProperty += $propertyAttribute
        }
    }

    return $resourceProperty
}

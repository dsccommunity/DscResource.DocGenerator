<#
    .SYNOPSIS
        Returns DSC class resource properties from the provided PropertyInfo properties.

    .DESCRIPTION
        Returns DSC class resource properties from the provided PropertyInfo properties.

    .PARAMETER SourcePath
        The path to the source folder (in which the child folder 'Classes' exist).

    .PARAMETER Properties
        One or more PropertyInfo objects return properties for.

    .OUTPUTS
        System.Collections.Hashtable[]

    .EXAMPLE
        Get-ClassResourceProperty -Properties $PropertyInfos -SourcePath '.\source'

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
        [System.Reflection.PropertyInfo[]]
        $Properties
    )

    $resourceProperty = [System.Collections.Hashtable[]] @()

    $className = ($dscProperties | Select-Object -Unique DeclaringType).DeclaringType.Name

    foreach ($currentClassName in $className)
    {
        $classExists = $false
        $sourceFilePath = ''
        $childPaths = @(
            ('Classes/???.{0}.ps1' -f $currentClassName)
            ('Classes/{0}.ps1' -f $currentClassName)
        )

        foreach ($childPath in $childPaths)
        {
            $sourceFilePath = Join-Path -Path $SourcePath -ChildPath $childPath

            if ((Test-Path -Path $sourceFilePath))
            {
                $classExists = $true
                break
            }
        }

        <#
            Skip if the class's source file does not exist. This can happen if the
            class uses a parent class from a different module.
        #>
        if (-not $classExists)
        {
            continue
        }

        $dscResourceCommentBasedHelp = Get-CommentBasedHelp -Path $sourceFilePath

        $propertyMembers = $Properties | Where-Object { $_.DeclaringType.Name -eq $currentClassName }

        <#
            Looping through each resource property to build the resulting
            hashtable. Hashtable will be in the format:

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
        foreach ($propertyMember in $propertyMembers)
        {
            Write-Verbose -Message ($script:localizedData.FoundClassResourcePropertyMessage -f $propertyMember.Name, $currentClassName)

            $propertyAttribute = @{
                Name             = $propertyMember.Name
                DataType         = Get-DscPropertyType -PropertyType $propertyMember.PropertyType

                # Always set to null, correct type name is set in DataType.
                EmbeddedInstance = $null

                # Always set to $false - correct type name is set in DataType.
                IsArray          = $false
            }

            $propertyAttribute.State = Get-ClassResourcePropertyState2 -PropertyInfo $propertyMember

            $valueMapValues = $null
            if ($propertyMember.PropertyType.IsEnum)
            {
                $valueMapValues = $propertyMember.PropertyType.GetEnumNames()
            }

            $validateSet = Get-ClassPropertyCustomAttribute -Attributes $propertyMember.CustomAttributes -AttributeType 'ValidateSetAttribute'
            if ($validateSet)
            {
                $valueMapValues = $validateSet.ConstructorArguments.Value.Value
            }

            if ($valueMapValues)
            {
                $propertyAttribute.ValueMap = $valueMapValues
            }

            if ($dscResourceCommentBasedHelp -and $dscResourceCommentBasedHelp.Parameters.Count -gt 0)
            {
                # The key name must be upper-case for it to match the right item in the list of parameters.
                $propertyDescription = $dscResourceCommentBasedHelp.Parameters[$propertyMember.Name.ToUpper()]

                if ($propertyDescription)
                {
                    $propertyDescription = Format-Text -Text $propertyDescription -Format @(
                        'Remove_Blank_Rows_At_End_Of_String',
                        'Remove_Indentation_From_Blank_Rows',
                        'Replace_NewLine_With_One_Whitespace',
                        'Replace_Vertical_Bar_With_One_Whitespace',
                        'Replace_Multiple_Whitespace_With_One',
                        'Remove_Whitespace_From_End_Of_String'
                    )
                }
            }
            else
            {
                $propertyDescription = ''
            }

            $propertyAttribute.Description = $propertyDescription

            $resourceProperty += $propertyAttribute
        }
    }

    return $resourceProperty
}

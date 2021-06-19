<#
    .SYNOPSIS
        Get-CompositeSchemaObject is used to read a .schema.psm1 file for a
        composite DSC resource.

    .DESCRIPTION
        The Get-CompositeSchemaObject method is used to read the text content of the
        .schema.psm1 file that all composite DSC resources have. It also reads the .psd1
        file to pull the module version. The object that is returned contains all of the
        data in the schema and manifest so it can be processed in other scripts.

    .PARAMETER FileName
        The full path to the .schema.psm1 file to process.

    .EXAMPLE
        $mof = Get-CompositeSchemaObject -FileName C:\repos\xPSDesiredStateConfiguration\DSCRescoures\xGroupSet\xGroupSet.schema.psm1

        This example parses a composite schema file and composite manifest file.
#>
function Get-CompositeSchemaObject
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $FileName
    )

    $manifestFileName = $FileName -replace '.schema.psm1','psd1'
    $compositeName = [System.IO.Path]::GetFileName($FileName) -replace '.schema.psm1',''
    $moduleVersion = Get-MetaData -Path $manifestFileName -PropertyName ModuleVersion
    $description = Get-MetaData -Path $manifestFileName -PropertyName Description
    $compositeResource = Get-ConfigurationAst

    if ($compositeResource.Count -gt 1)
    {
        throw ($script:localizedData.CompositeResourceMultiConfigError -f $FileName, $compositeResources.Count)
    }

    $commentBasedHelp = Get-CommentBasedHelp -Path $FileName

    $attributes = foreach ($property in $compsiteResource.Body.ScriptBlock.ParamBlock.Parameters)
    {
        $propertyDescription = ''

        @{
            Name             = $property.Name
            State            = (Get-CompositeResourcePropertyState -Ast $property)
            DataType         = $property.StaticType.FullName
            ValueMap         = $property.Qualifiers.Where( { $_.Name -eq 'ValueMap' }).Value
            Description      = $propertyDescription
        }
    }

    @{

        Name          = $compositeName
        Attributes    = $attributes
        ModuleVersion = $moduleVersion
        Description   = $description
    }
}

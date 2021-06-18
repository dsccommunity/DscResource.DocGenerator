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

    $temporaryPath = Get-TemporaryPath

    foreach ($compositeResource in $compositeCompositeFile)
    {
        $attributes = foreach ($property in $compsiteResourceProperties)
        {
            @{
                Name             = $property.Name
                State            = $state
                DataType         = $property.CimType
                ValueMap         = $property.Qualifiers.Where( { $_.Name -eq 'ValueMap' }).Value
                IsArray          = $property.CimType -gt 16
                Description      = $property.Qualifiers.Where( { $_.Name -eq 'Description' }).Value
                EmbeddedInstance = $property.Qualifiers.Where( { $_.Name -eq 'EmbeddedInstance' }).Value
            }
        }

        @{
            ClassName    = $currentCimClass.CimClassName
            Attributes   = $attributes
            ClassVersion = '1.0.0'
            FriendlyName = $currentCimClass.CimClassQualifiers.Where( { $_.Name -eq 'FriendlyName' }).Value
        }
    }
}

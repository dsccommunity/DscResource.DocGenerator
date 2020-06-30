<#
    .SYNOPSIS
        Get-DscResourceSchemaPropertyContent is used to generate the parameter content
        for the wiki page.

    .DESCRIPTION
        Get-DscResourceSchemaPropertyContent is used to generate the parameter content
        for the wiki page.

    .PARAMETER Attribute
        A hash table with properties that is returned by Get-MofSchemaObject in
        the property Attributes.

    .EXAMPLE
        $content = Get-DscResourceSchemaPropertyContent -Property @(
                @{
                    Name             = 'StringProperty'
                    DataType         = 'String'
                    IsArray          = $false
                    State            = 'Key'
                    Description      = 'Any description'
                    EmbeddedInstance = $null
                    ValueMap         = $null
                }
            )

        This example parses a MOF schema file.
#>
function Get-DscResourceSchemaPropertyContent
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable[]]
        $Property
    )

    $stringArray = [System.String[]] @()

    $stringArray += '| Parameter | Attribute | DataType | Description | Allowed Values |'
    $stringArray += '| --- | --- | --- | --- | --- |'

    foreach ($currentProperty in $Property)
    {
        if ($currentProperty.EmbeddedInstance -eq 'MSFT_Credential')
        {
            $dataType = 'PSCredential'
        }
        elseif (-not [System.String]::IsNullOrEmpty($currentProperty.EmbeddedInstance))
        {
            $dataType = $currentProperty.EmbeddedInstance
        }
        else
        {
            $dataType = $currentProperty.DataType
        }

        # If the attribute is an array, add [] to the DataType string.
        if ($currentProperty.IsArray)
        {
            $dataType = $dataType.ToString() + '[]'
        }

        $propertyLine = "| **$($currentProperty.Name)** " + `
                "| $($currentProperty.State) " + `
                "| $dataType " + `
                "| $($currentProperty.Description) |"

        if (-not [System.String]::IsNullOrEmpty($currentProperty.ValueMap))
        {
            $propertyLine += ' ' + ($currentProperty.ValueMap -join ', ')
        }

        $propertyLine += ' |'

        $stringArray += $propertyLine
    }

    return (, $stringArray)
}

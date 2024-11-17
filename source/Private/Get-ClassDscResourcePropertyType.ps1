<#
    .SYNOPSIS
        This function returns the property type of a class-based DSC
        resource property.

    .DESCRIPTION
        This function returns the property type value of a DSC class-based
        resource property.

    .PARAMETER PropertyInfo
        The PropertyInfo object of a class-based DSC resource property.

    .EXAMPLE
        Get-ClassResourcePropertyType -PropertyInfo $properties

        Returns the property state for the property 'KeyName'.
#>
function Get-ClassResourcePropertyType
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Reflection.PropertyInfo]
        $PropertyInfo
    )

    <#
        Check for Key first since it it possible to use both Key and Mandatory
        on a property and in that case we want to return just 'Key'.
    #>

    $attributeParams = @{
        PropertyAttributes = $PropertyInfo.CustomAttributes
    }

    if ((Test-ClassPropertyDscAttributeArgument -IsKey @attributeParams))
    {
        $propertyType = 'Key'
    }
    elseif ((Test-ClassPropertyDscAttributeArgument -IsMandatory @attributeParams))
    {
        $propertyType = 'Required'
    }
    elseif ((Test-ClassPropertyDscAttributeArgument -IsRead @attributeParams))
    {
        $propertyType = 'Read'
    }
    elseif ((Test-ClassPropertyDscAttributeArgument -IsWrite @attributeParams))
    {
        $propertyType = 'Write'
    }

    return $propertyType
}

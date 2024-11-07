<#
    .SYNOPSIS
        This function returns the property state value of an class-based DSC
        resource property.

    .DESCRIPTION
        This function returns the property state value of an DSC class-based
        resource property.

    .PARAMETER PropertyInfo
        The PropertyInfo of a class-based DSC resource property.

    .EXAMPLE
        Get-ClassResourcePropertyState2 -PropertyInfo $properties

        Returns the property state for the property 'KeyName'.
#>
function Get-ClassResourcePropertyState2
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
        $propertyState = 'Key'
    }
    elseif ((Test-ClassPropertyDscAttributeArgument -IsMandatory @attributeParams))
    {
        $propertyState = 'Required'
    }
    elseif ((Test-ClassPropertyDscAttributeArgument -IsRead @attributeParams))
    {
        $propertyState = 'Read'
    }
    elseif ((Test-ClassPropertyDscAttributeArgument -IsWrite @attributeParams))
    {
        $propertyState = 'Write'
    }

    return $propertyState
}

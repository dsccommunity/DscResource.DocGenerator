<#
    .SYNOPSIS
        Retrieves the property type from a System.Type PropertyType object.

    .DESCRIPTION
        This function returns the property type as a string. This unwaps any string that has the Nullable property attribute.

    .PARAMETER PropertyType
        The property to retrieve the property name from.

    .OUTPUTS
        System.String

    .EXAMPLE
        Get-DscPropertyType -PropertyType $VariableOfProperty.

        Returns the property type as a string.
#>

function Get-DscPropertyType
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [System.Type]
        $PropertyType
    )

    switch ($PropertyType.Name)
    {
        'Nullable`1'
        {
            return $PropertyType.GenericTypeArguments.FullName
        }
        default
        {
            return $PropertyType.FullName
        }
    }
}

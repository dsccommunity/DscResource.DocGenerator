<#
    .SYNOPSIS
        This function returns a filtered list of CustomAttributes from a given AttributeType.

    .DESCRIPTION
        The function will filter the provided CustomAttributes provided and returns only the matching attributes or null.

    .PARAMETER Attributes
        The array of attributes that need to be filtered.

    .PARAMETER AttributeType
        The attribute type name to filter the attributes on.

    .OUTPUTS
        System.Reflection.CustomAttributeData[]

    .EXAMPLE
        Get-ClassPropertyCustomAttribute -Attributes $CommonAttributes -AttributeType 'ValidateSetAttribute'
#>

function Get-ClassPropertyCustomAttribute
{
    [CmdletBinding()]
    [OutputType([System.Reflection.CustomAttributeData[]])]
    param (
        [Parameter(Mandatory = $true)]
        [System.Reflection.CustomAttributeData[]]
        $Attributes,

        [Parameter(Mandatory = $true)]
        [System.String]
        $AttributeType
    )

    process
    {
        return $Attributes | Where-Object { $_.AttributeType.Name -eq $AttributeType }
    }
}

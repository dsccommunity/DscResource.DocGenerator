<#
    .SYNOPSIS
        This function returns the property state value of an class-based DSC
        resource property.

    .DESCRIPTION
        This function returns the property state value of an DSC class-based
        resource property.

    .PARAMETER PropertyAttributes
        The PropertyAttributes for class-based DSC resource property.
        The passed value must be of the type 'System.Reflection.CustomAttributeData'.

    .PARAMETER IsKey
        Specifies if the parameter is expected to have the type qualifier Key.

    .PARAMETER IsMandatory
        Specifies if the parameter is expected to have the type qualifier Mandatory.

    .PARAMETER IsWrite
        Specifies if the parameter is expected to have the type qualifier Write.

    .PARAMETER IsRead
        Specifies if the parameter is expected to have the type qualifier Read.

    .EXAMPLE
        Test-ClassPropertyDscAttributeArgument -IsKey -PropertyAttributes $properties

        Returns $true that the property 'KeyName' is Key.
#>

function Test-ClassPropertyDscAttributeArgument
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Reflection.CustomAttributeData[]]
        $PropertyAttributes,

        [Parameter(Mandatory = $true, ParameterSetName = 'IsKey')]
        [System.Management.Automation.SwitchParameter]
        $IsKey,

        [Parameter(Mandatory = $true, ParameterSetName = 'IsMandatory')]
        [System.Management.Automation.SwitchParameter]
        $IsMandatory,

        [Parameter(Mandatory = $true, ParameterSetName = 'IsWrite')]
        [System.Management.Automation.SwitchParameter]
        $IsWrite,

        [Parameter(Mandatory = $true, ParameterSetName = 'IsRead')]
        [System.Management.Automation.SwitchParameter]
        $IsRead
    )

    $attributes = Get-ClassPropertyCustomAttribute -Attributes $PropertyAttributes -AttributeType 'DscPropertyAttribute'

    if ($IsKey.IsPresent -and 'Key' -in $attributes.NamedArguments.MemberName)
    {
        return $true
    }

    # Having Key on a property makes it implicitly Mandatory.
    if ($IsMandatory.IsPresent -and $attributes.NamedArguments.MemberName -in @('Mandatory', 'Key'))
    {
        return $true
    }

    if ($IsRead.IsPresent -and 'NotConfigurable' -in $attributes.NamedArguments.MemberName)
    {
        return $true
    }

    if ($IsWrite.IsPresent -and $attributes.NamedArguments.MemberName -notin @('Key', 'Mandatory', 'NotConfigurable'))
    {
        return $true
    }

    return $false
}

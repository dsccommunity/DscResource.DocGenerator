<#
    .SYNOPSIS
        This function returns the property state value of an class-based DSC
        resource property.

    .DESCRIPTION
        This function returns the property state value of an DSC class-based
        resource property.

    .PARAMETER Ast
        The Abstract Syntax Tree (AST) for class-based DSC resource property.
        The passed value must be an AST of the type 'PropertyMemberAst'.

    .EXAMPLE
        Test-PropertyMemberAst -IsKey -Ast {
            [DscResource()]
            class NameOfResource {
                [DscProperty(Key)]
                [string] $KeyName

                [NameOfResource] Get() {
                    return $this
                }

                [void] Set() {}

                [bool] Test() {
                    return $true
                }
            }
        }.Ast.Find({$args[0] -is [System.Management.Automation.Language.PropertyMemberAst]}, $false)

        Returns $true that the property 'KeyName' is Key.
#>
function Test-PropertyMemberAst
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.PropertyMemberAst]
        $Ast,

        [Parameter(Mandatory = $true, ParameterSetName='IsKey')]
        [System.Management.Automation.SwitchParameter]
        $IsKey,

        [Parameter(Mandatory = $true, ParameterSetName='IsMandatory')]
        [System.Management.Automation.SwitchParameter]
        $IsMandatory,

        [Parameter(Mandatory = $true, ParameterSetName='IsWrite')]
        [System.Management.Automation.SwitchParameter]
        $IsWrite,

        [Parameter(Mandatory = $true, ParameterSetName='IsRead')]
        [System.Management.Automation.SwitchParameter]
        $IsRead
    )

    $astFilter = {
        $args[0] -is [System.Management.Automation.Language.NamedAttributeArgumentAst]
    }

    $propertyNamedAttributeArgumentAsts = $Ast.FindAll($astFilter, $true)

    if ($IsKey.IsPresent -and 'Key' -in $propertyNamedAttributeArgumentAsts.ArgumentName)
    {
        return $true
    }

    # Having Key on a property makes it implicitly Mandatory.
    if ($IsMandatory.IsPresent -and $propertyNamedAttributeArgumentAsts.ArgumentName -in @('Mandatory', 'Key'))
    {
        return $true
    }

    if ($IsRead.IsPresent -and 'NotConfigurable' -in $propertyNamedAttributeArgumentAsts.ArgumentName)
    {
        return $true
    }

    if ($IsWrite.IsPresent -and $propertyNamedAttributeArgumentAsts.ArgumentName -notin @('Key', 'Mandatory', 'NotConfigurable'))
    {
        return $true
    }

    return $false
}

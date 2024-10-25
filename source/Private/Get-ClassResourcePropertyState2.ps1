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
        Get-ClassResourcePropertyState -Ast {
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
    # Data lives in $PropertyInfo.CustomProperties.NamedArguments
    # Need to check attribute type is correct
    # TODO: Need to deal with Attribute = False??

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

<#
    .SYNOPSIS
        This function returns the property state value of an class-based DSC
        resource property.

    .DESCRIPTION
        This function returns the property state value of an DSC class-based
        resource property.

    .PARAMETER Ast
        The AST for class-based DSC resource property. The passed value must
        be an AST of the type 'PropertyMemberAst'.

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
function Get-ClassResourcePropertyState
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.PropertyMemberAst]
        $Ast
    )

    <#
        Check for Key first since it it possible to use both Key and Mandatory
        on a property and in that case we want to return just 'Key'.
    #>
    if ((Test-PropertyMemberAst -IsKey -Ast $Ast))
    {
        $propertyState = 'Key'
    }
    elseif ((Test-PropertyMemberAst -IsMandatory -Ast $Ast))
    {
        $propertyState = 'Required'
    }
    elseif ((Test-PropertyMemberAst -IsRead -Ast $Ast))
    {
        $propertyState = 'Read'
    }
    elseif ((Test-PropertyMemberAst -IsWrite -Ast $Ast))
    {
        $propertyState = 'Write'
    }

    return $propertyState
}

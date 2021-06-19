<#
    .SYNOPSIS
        This function returns the parameter validate set of a composite
        resource parameter.

    .DESCRIPTION
        This function returns the parameter validate set of a composite
        resource parameter. It will return an array of value found in
        the 'ValidateSet' attribute for the parameter.

    .PARAMETER Ast
        The Abstract Syntax Tree (AST) for composite composite resource
        parameter. The passed value must be an AST of the type 'ParameterAst'.

    .EXAMPLE
        Get-CompositeResourceParameterValidateSet -Ast {
            configuration CompositeHelperTest
            {
                [CmdletBinding()]
                param
                (
                    [Parameter()]
                    [ValidateSet('Present', 'Absent')]
                    [System.String]
                    $Ensure
                )
            }
        }.Ast.Find({$args[0] -is [System.Management.Automation.Language.ParameterAst]}, $false)

        Returns the parameter validate set for the parameter 'Enure' which will be 'Present', 'Absent'.
#>
function Get-CompositeResourceParameterValidateSet
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.ParameterAst]
        $Ast
    )

    $astFilterForValidateSetAttribute = {
        $args[0] -is [System.Management.Automation.Language.AttributeAst] `
            -and $args[0].TypeName.Name -eq 'ValidateSet'
    }

    $validateSetAttribute = $Ast.FindAll($astFilterForValidateSetAttribute, $false)

    if ($validateSetAttribute)
    {
        return $validateSetAttribute.PositionalArguments.Value
    }
}

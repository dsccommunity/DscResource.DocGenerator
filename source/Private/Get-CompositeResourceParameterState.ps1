<#
    .SYNOPSIS
        This function returns the parameter state of a composite
        resource parameter.

    .DESCRIPTION
        This function returns the parameter state of a composite
        resource parameter. It will return 'Required' if the parameter
        has the 'Mandatory = $true' attribute set.

    .PARAMETER Ast
        The Abstract Syntax Tree (AST) for composite composite resource
        parameter. The passed value must be an AST of the type 'ParameterAst'.

    .EXAMPLE
        Get-CompositeResourceParameterState -Ast {
            configuration CompositeHelperTest
            {
                [CmdletBinding()]
                param
                (
                    [Parameter(Mandatory = $true)]
                    [ValidateNotNullOrEmpty()]
                    [System.String[]]
                    $Name
                )
            }
        }.Ast.Find({$args[0] -is [System.Management.Automation.Language.ParameterAst]}, $false)

        Returns the parameter state for the parameter 'Name' which will be 'Required'.
#>
function Get-CompositeResourceParameterState
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.ParameterAst]
        $Ast
    )

    $astFilterForMandatoryAttribute = {
        $args[0] -is [System.Management.Automation.Language.AttributeAst] `
            -and $args[0].TypeName.Name -eq 'Parameter' `
            -and $args[0].NamedArguments.ArgumentName -eq 'Mandatory' `
            -and $args[0].NamedArguments.Argument.Extent.Text -eq '$true'
    }

    if ($Ast.FindAll($astFilterForMandatoryAttribute, $false))
    {
        $parameterState = 'Required'
    }
    else
    {
        $parameterState = 'Write'
    }

    return $parameterState
}

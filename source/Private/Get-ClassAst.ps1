<#
    .SYNOPSIS
        Returns the AST for a single or all classes.

    .PARAMETER ScriptFile
        The path to the source file that contain the class.

    .PARAMETER ClassName
        The specific class to return the AST for. Optional.

    .EXAMPLE
        Get-ClassAst -ScriptFile '.\output\MyModule\1.0.0\MyModule.psm1'

        Returns AST for all the classes in the script file.

    .EXAMPLE
        Get-ClassAst -ClassName 'myClass' -ScriptFile '.\output\MyModule\1.0.0\MyModule.psm1'

        Returns AST for the class 'myClass' from the script file.
#>
function Get-ClassAst
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ScriptFile,

        [Parameter()]
        [System.String]
        $ClassName
    )

    $tokens, $parseErrors = $null

    $ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptFile, [ref] $tokens, [ref] $parseErrors)

    if ($parseErrors)
    {
        throw $parseErrors
    }

    if ($PSBoundParameters.ContainsKey('ClassName') -and $ClassName)
    {
        # Get only the specific class resource.
        $astFilter = {
            $args[0] -is [System.Management.Automation.Language.TypeDefinitionAst] `
                -and $args[0].IsClass `
                -and $args[0].Name -eq $ClassName
        }
    }
    else
    {
        # Get all class resources.
        $astFilter = {
            $args[0] -is [System.Management.Automation.Language.TypeDefinitionAst] `
                -and $args[0].IsClass
        }
    }

    $classAst = $ast.FindAll($astFilter, $true)

    return $classAst
}

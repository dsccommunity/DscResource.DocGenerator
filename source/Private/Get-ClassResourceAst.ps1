<#
    .SYNOPSIS
        Returns the AST for a single or all DSC class resources.

    .PARAMETER ScriptFile
        The path to the source file that contain the DSC class resource.

    .PARAMETER ClassName
        The specific DSC class resource to return the AST for. Optional.

    .EXAMPLE
        Get-ClassResourceAst -ClassName 'myClass' -ScriptFile '.\output\MyModule\1.0.0\MyModule.psm1'

        Returns AST for all DSC class resources in the script file.

    .EXAMPLE
        Get-ClassResourceAst -ClassName 'myClass' -ScriptFile '.\output\MyModule\1.0.0\MyModule.psm1'

        Returns AST for the DSC class resource 'myClass' from the script file.
#>
function Get-ClassResourceAst
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
                -and $args[0].IsClass -eq $true `
                -and $args[0].Name -eq $ClassName `
                -and $args[0].Attributes.Extent.Text -imatch '\[DscResource\(.*\)\]'
        }
    }
    else
    {
        # Get all class resources.
        $astFilter = {
            $args[0] -is [System.Management.Automation.Language.TypeDefinitionAst] `
                -and $args[0].IsClass -eq $true `
                -and $args[0].Attributes.Extent.Text -imatch '\[DscResource\(.*\)\]'
        }
    }

    $dscClassResourceAst = $ast.FindAll($astFilter, $true)

    return $dscClassResourceAst
}

<#
    .SYNOPSIS
        Returns the AST for a single or all configurations.

    .PARAMETER ScriptFile
        The path to the source file that contain the configuration.

    .PARAMETER ConfigurationName
        The specific configuration to return the AST for. Optional.

    .EXAMPLE
        Get-ConfigurationAst -ScriptFile '.\output\myModule\1.0.0\DSCResources\myComposite\myComposite.schema.psm1'

        Returns AST for all the DSC configurations in the script file.

    .EXAMPLE
        Get-ConfigurationAst -ConfigurationName 'myComposite' -ScriptFile '.\output\myModule\1.0.0\DSCResources\myComposite\myComposite.schema.psm1'

        Returns AST for the DSC configuration 'myComposite' from the script file.

    .NOTES
        MacOS is not currently supported because DSC can not be installed on it.
        DSC is required to process the AST for the configuration statement.
#>
function Get-ConfigurationAst
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ScriptFile,

        [Parameter()]
        [System.String]
        $ConfigurationName
    )

    if ($IsMacOS)
    {
        throw $script:localizedData:MacOSNotSupportedError
    }

    $tokens, $parseErrors = $null

    $ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptFile, [ref] $tokens, [ref] $parseErrors)

    if ($parseErrors)
    {
        throw $parseErrors
    }

    if ($PSBoundParameters.ContainsKey('ConfigurationName') -and $ConfigurationName)
    {
        # Get only the specific class resource.
        $astFilter = {
            $args[0] -is [System.Management.Automation.Language.ConfigurationDefinitionAst] `
                -and $args[0].ConfigurationType -eq [System.Management.Automation.Language.ConfigurationType]::Resource `
                -and $args[0].InstanceName.Value -eq $ConfigurationName
        }
    }
    else
    {
        # Get all class resources.
        $astFilter = {
            $args[0] -is [System.Management.Automation.Language.ConfigurationDefinitionAst] `
            -and $args[0].ConfigurationType -eq [System.Management.Automation.Language.ConfigurationType]::Resource `
        }
    }

    $configurationAst = $ast.FindAll($astFilter, $true)

    return $configurationAst
}

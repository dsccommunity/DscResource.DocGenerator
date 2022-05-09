<#
    .SYNOPSIS
        Get-CompositeSchemaObject is used to read a .schema.psm1 file for a
        composite DSC resource.

    .DESCRIPTION
        The Get-CompositeSchemaObject method is used to read the text content of the
        .schema.psm1 file that all composite DSC resources have. It also reads the .psd1
        file to pull the module version. The object that is returned contains all of the
        data in the schema and manifest so it can be processed in other scripts.

    .PARAMETER FileName
        The full path to the .schema.psm1 file to process.

    .EXAMPLE
        $mof = Get-CompositeSchemaObject -FileName C:\repos\xPSDesiredStateConfiguration\DSCRescoures\xGroupSet\xGroupSet.schema.psm1

        This example parses a composite schema file and composite manifest file.

    .NOTES
        MacOS is not currently supported because DSC can not be installed on it.
        DSC is required to process the AST for the configuration statement.
#>
function Get-CompositeSchemaObject
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $FileName
    )

    if ($IsMacOS)
    {
        throw $script:localizedData.MacOSNotSupportedError
    }

    $manifestFileName = $FileName -replace '.schema.psm1', '.psd1'
    $compositeName = [System.IO.Path]::GetFileName($FileName) -replace '.schema.psm1', ''
    $manifestData = Import-LocalizedData `
        -BaseDirectory ([System.IO.Path]::GetDirectoryName($manifestFileName)) `
        -FileName ([System.IO.Path]::GetFileName($manifestFileName))
    $moduleVersion = $manifestData.ModuleVersion
    $description = $manifestData.Description
    $compositeResource = Get-ConfigurationAst -ScriptFile $FileName

    if ($compositeResource.Count -gt 1)
    {
        throw ($script:localizedData.CompositeResourceMultiConfigError -f $FileName, $compositeResources.Count)
    }

    $commentBasedHelp = Get-CommentBasedHelp -Path $FileName

    $parameters = foreach ($parameter in $compositeResource.Body.ScriptBlock.ParamBlock.Parameters)
    {
        $parameterName = $parameter.Name.VariablePath.ToString()

        if ($commentBasedHelp)
        {
            # The parameter name in comment-based help is returned as upper so need to match correctly.
            $parameterDescription = $commentBasedHelp.Parameters[$parameterName.ToUpper()] -replace '\r?\n+$'
        }
        else
        {
            $parameterDescription = ''
        }

        @{
            Name        = $parameterName
            State       = (Get-CompositeResourceParameterState -Ast $parameter)
            Type        = $parameter.StaticType.FullName
            ValidateSet = (Get-CompositeResourceParameterValidateSet -Ast $parameter)
            Description = $parameterDescription
        }
    }

    return @{
        Name          = $compositeName
        Parameters    = $parameters
        ModuleVersion = $moduleVersion
        Description   = $description
    }
}

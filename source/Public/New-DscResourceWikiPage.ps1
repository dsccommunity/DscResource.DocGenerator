
<#
    .SYNOPSIS
        New-DscResourceWikiPage generates wiki pages that can be uploaded to GitHub
        to use as public documentation for a module.

    .DESCRIPTION
        The New-DscResourceWikiPage cmdlet will review all of the MOF-based,
        class-based and composite resources in a specified module directory and will
        output the Markdown files to the specified directory. These help files include
        details on the property types for each resource, as well as a text description
        and examples where they exist.

        Generate documentation that can be manually uploaded to the GitHub repository
        Wiki.

        It is possible to use markdown code in the schema MOF parameter descriptions.
        If markdown code is used and conceptual help is also to be generated, configure
        the task [`Generate_Conceptual_Help`](#generate_conceptual_help) to parse the
        markdown code. See the cmdlet `New-DscResourcePowerShellHelp` and the task
        [`Generate_Conceptual_Help`](#generate_conceptual_help) for more information.

    .PARAMETER OutputPath
        Where should the files be saved to.

    .PARAMETER SourcePath
        The path to the root of the DSC resource module (where the PSD1 file is found,
        not the folder for and individual DSC resource).

    .PARAMETER BuiltModulePath
        The path to the root of the built DSC resource module, e.g.
        'output/MyResource/1.0.0'.

    .PARAMETER Force
        Overwrites any existing file when outputting the generated content.

    .EXAMPLE
        New-DscResourceWikiPage `
            -SourcePath C:\repos\MyResource\source `
            -BuiltModulePath C:\repos\MyResource\output\MyResource\1.0.0 `
            -OutputPath C:\repos\MyResource\output\WikiContent

        This example shows how to generate wiki documentation for a specific module.
#>
function New-DscResourceWikiPage
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $OutputPath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SourcePath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $BuiltModulePath,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    $newDscMofResourceWikiPageParameters = @{
        OutputPath = $OutputPath
        SourcePath = $SourcePath
        Force      = $Force
    }

    New-DscMofResourceWikiPage @newDscMofResourceWikiPageParameters

    New-DscClassResourceWikiPage @PSBoundParameters

    New-DscCompositeResourceWikiPage @PSBoundParameters
}

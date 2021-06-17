<#
    .SYNOPSIS
        New-DscResourceWikiPage generates wiki pages that can be uploaded to GitHub
        to use as public documentation for a module.

    .DESCRIPTION
        The New-DscResourceWikiPage cmdlet will review all of the MOF-based and
        class-based resources in a specified module directory and will output the
        Markdown files to the specified directory. These help files include details
        on the property types for each resource, as well as a text description and
        examples where they exist.

    .PARAMETER OutputPath
        Where should the files be saved to.

    .PARAMETER SourcePath
        The path to the root of the DSC resource module (where the PSD1 file is found,
        not the folder for and individual DSC resource).

    .PARAMETER BuiltModulePath
        The path to the root of the built DSC resource module, e.g.
        'output/MyResource/1.0.0'.

    .EXAMPLE
        New-DscResourceWikiPage `
            -SourcePath C:\repos\MyResource\source `
            -BuiltModulePath C:\repos\MyResource\output\MyResource\1.0.0 `
            -OutputPath C:\repos\MyResource\output\WikiContent

        This example shows how to generate wiki documentation for a specific module.
#>
function New-DscResourceWikiPage
{
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

    New-DscMofResourceWikiPage @PSBoundParameters

    New-DscClassResourceWikiPage @PSBoundParameters
}

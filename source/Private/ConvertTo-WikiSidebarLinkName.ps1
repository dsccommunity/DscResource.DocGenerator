<#
    .SYNOPSIS
        Converts a name to a format suitable for use as a Wiki sidebar link.

    .DESCRIPTION
        The ConvertTo-WikiSidebarLinkName function takes a string input and converts
        it to a format that is suitable for use as a link name in a Wiki sidebar. It
        replaces hyphens with spaces and converts Unicode hyphens to standard hyphens.

    .PARAMETER Name
        The string to be converted. This parameter is mandatory and can be passed via
        the pipeline.

    .EXAMPLE
        PS C:\> ConvertTo-WikiSidebarLinkName -Name "My-Page-Name"

        Returns: "My Page Name"

    .EXAMPLE
        PS C:\> "Unicode‐Hyphen" | ConvertTo-WikiSidebarLinkName

        Returns: "Unicode-Hyphen"

    .INPUTS
        System.String

    .OUTPUTS
        System.String

    .NOTES
        This function is used internally by the New-GitHubWikiSidebar function to
        format link names in the generated sidebar.
#>
function ConvertTo-WikiSidebarLinkName
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [System.String]
        $Name
    )

    process
    {
        # Replace hyphens with spaces
        $convertedName = $Name -replace '-', ' '

        # Replace Unicode hyphen (U+2010) with a standard hyphen
        $convertedName = $convertedName -replace [System.Char]::ConvertFromUtf32(0x2010), '-'

        return $convertedName
    }
}

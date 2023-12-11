
<#
    .SYNOPSIS
        Sets the module version in a markdown file.

    .DESCRIPTION
        Sets the module version in a markdown file. Parses the markdown file for
        #.#.# which is replaced by the specified module version.

    .PARAMETER Path
        The path to a markdown file to set the module version in.

    .PARAMETER ModuleVersion
        The base name of the Wiki Sidebar file. Defaults to '_Sidebar.md'.

    .EXAMPLE
        Set-WikiModuleVersion -Path '.\output\WikiContent\Home.md' -ModuleVersion '14.0.0'

        Replaces '#.#.#' with the module version '14.0.0' in the markdown file 'Home.md'.
#>
function Set-WikiModuleVersion
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ModuleVersion
    )

    $markdownContent = Get-Content -Path $path -Raw

    $markdownContent = $markdownContent -replace '#\.#\.#', $ModuleVersion

    Out-File -InputObject $markdownContent -FilePath $Path -Encoding 'ascii' -NoNewline
}

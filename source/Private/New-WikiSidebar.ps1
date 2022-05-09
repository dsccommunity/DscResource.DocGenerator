<#
    .SYNOPSIS
        Creates the Wiki side bar file from the list of markdown files in the path.

    .DESCRIPTION
        Creates the Wiki side bar file from the list of markdown files in the path.

    .PARAMETER ModuleName
        The name of the module to generate a new Wiki Sidebar file for.

    .PARAMETER OutputPath
        The path in which to create the Wiki Sidebar file, e.g. '.\output\WikiContent'.


    .PARAMETER WikiSourcePath
        The path where to find the markdown files that was generated
        by New-DscResourceWikiPage, e.g. '.\output\WikiContent'.

    .PARAMETER BaseName
        The base name of the Wiki Sidebar file. Defaults to '_Sidebar.md'.

    .EXAMPLE
        New-WikiSidebar -ModuleName 'ActiveDirectoryDsc -Path '.\output\WikiContent'

        Creates the Wiki side bar from the list of markdown files in the path.
#>
function New-WikiSidebar
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ModuleName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $OutputPath,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WikiSourcePath,

        [Parameter()]
        [System.String]
        $BaseName = '_Sidebar.md'
    )

    $wikiSideBarOutputPath = Join-Path -Path $OutputPath -ChildPath $BaseName
    $wikiSideBarWikiSourcePath = Join-Path -Path $WikiSourcePath -ChildPath $BaseName

    if (-not (Test-Path -Path $wikiSideBarWikiSourcePath))
    {
        Write-Verbose -Message ($script:localizedData.GenerateWikiSidebarMessage -f $BaseName)

        $WikiSidebarContent = @(
            "# $ModuleName Module"
            ' '
        )

        $wikiFiles = Get-ChildItem -Path (Join-Path -Path $OutputPath -ChildPath '*.md') -Exclude '_*.md'

        foreach ($file in $wikiFiles)
        {
            Write-Verbose -Message ("`t{0}" -f ($script:localizedData.AddFileToSideBar -f $file.Name))

            $WikiSidebarContent += "- [$($file.BaseName)]($($file.BaseName))"
        }

        Out-File -InputObject $WikiSidebarContent -FilePath $wikiSideBarOutputPath -Encoding 'ascii'
    }
}

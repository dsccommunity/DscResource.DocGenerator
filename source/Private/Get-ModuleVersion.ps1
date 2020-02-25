<#
    .SYNOPSIS
        This function evaluates the version from a module manifest if the
        passed ModuleVersion is not already set.

    .PARAMETER OutputDirectory
        The path to the output folder where the module is built, e.g.
        'c:\MyModule\output'.

    .PARAMETER ProjectName
        The name of the project, normally the name of the module that is being
        built.

    .EXAMPLE
        Get-ModuleVersion -OutputDirectory 'c:\MyModule\output' -ProjectName 'MyModule' -ModuleVersion $null

        Will evaluate the module version from the module manifest in the path
        c:\MyModule\output\MyModule\*\MyModule.psd1.

    .EXAMPLE
        Get-ModuleVersion -ModuleVersion '1.0.0-preview1'.

        Will return the module version as '1.0.0-preview1'.

    .NOTES
        This is the same function that exits in the module Sampler, so if the
        function there is moved or exposed it should be reused from there instead.
#>
function Get-ModuleVersion
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.String]
        $OutputDirectory,

        [Parameter()]
        [System.String]
        $ProjectName,

        [Parameter()]
        [System.String]
        $ModuleVersion
    )

    if ([System.String]::IsNullOrEmpty($ModuleVersion))
    {
        $moduleInfo = Import-PowerShellDataFile "$OutputDirectory/$ProjectName/*/$ProjectName.psd1" -ErrorAction 'Stop'

        if ($preReleaseTag = $moduleInfo.PrivateData.PSData.Prerelease)
        {
            $moduleVersion = $moduleInfo.ModuleVersion + "-" + $preReleaseTag
        }
        else
        {
            $moduleVersion = $moduleInfo.ModuleVersion
        }
    }
    else
    {
        <#
            This handles a previous version of the module that suggested to pass
            a version string with metadata in the CI pipeline that can look like
            this: 1.15.0-pr0224-0022+Sha.47ae45eb2cfed02b249f239a7c55e5c71b26ab76.Date.2020-01-07
        #>
        $moduleVersion = ($moduleVersion -split '\+', 2)[0]
    }

    return $moduleVersion
}

<#
    .SYNOPSIS
        This function returns the version from a built module's module manifest.

    .PARAMETER OutputDirectory
        The path to the output folder where the module is built, e.g.
        'c:\MyModule\output'.

    .PARAMETER ProjectName
        The name of the project, normally the name of the module that is being
        built.

    .EXAMPLE
        Get-BuiltModuleVersion -OutputDirectory 'c:\MyModule\output' -ProjectName 'MyModule'

        Will evaluate the module version from the module manifest in the path
        c:\MyModule\output\MyModule\*\MyModule.psd1.

    .NOTES
        This is the same function that exits in the module Sampler, so if the
        function there is moved or exposed it should be reused from there instead.
#>
function Get-BuiltModuleVersion
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
        $ProjectName
    )

    $ModuleManifestPath = "$OutputDirectory/$ProjectName/*/$ProjectName.psd1"

    Write-Verbose -Message (
        "Get the module version from module manifest in path '{0}'." -f $ModuleManifestPath
    )

    $moduleInfo = Import-PowerShellDataFile $ModuleManifestPath -ErrorAction 'Stop'

    $ModuleVersion = $moduleInfo.ModuleVersion

    if ($moduleInfo.PrivateData.PSData.Prerelease)
    {
        $ModuleVersion = $ModuleVersion + '-' + $moduleInfo.PrivateData.PSData.Prerelease
    }

    $moduleVersionParts = Split-ModuleVersion -ModuleVersion $ModuleVersion

    Write-Verbose -Message (
        "Current module version is '{0}'." -f $moduleVersionParts.ModuleVersion
    )

    return $moduleVersionParts.ModuleVersion
}

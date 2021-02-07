<#
    .SYNOPSIS
        This function parses a module version string as returns a PSCustomObject
        which each of the module version's parts.

    .PARAMETER ModuleVersion
        The module to parse.

    .EXAMPLE
        Split-ModuleVersion -ModuleVersion '1.15.0-pr0224-0022+Sha.47ae45eb'

        Splits the module version an returns a PSCustomObject with the parts
        of the module version.

        Version PreReleaseString ModuleVersion
        ------- ---------------- -------------
        1.15.0  pr0224           1.15.0-pr0224

    .NOTES
        This is required by the function Get-BuiltModuleVersion and the build task
        Generate_Wiki_Content.
#>
function Split-ModuleVersion
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param
    (
        [Parameter()]
        [System.String]
        $ModuleVersion
    )

    <#
        This handles a previous version of the module that suggested to pass
        a version string with metadata in the CI pipeline that can look like
        this: 1.15.0-pr0224-0022+Sha.47ae45eb2cfed02b249f239a7c55e5c71b26ab76.Date.2020-01-07
    #>
    $ModuleVersion = ($ModuleVersion -split '\+', 2)[0]

    $moduleVersion, $preReleaseString = $ModuleVersion -split '-', 2

    <#
        The cmldet Publish-Module does not yet support semver compliant
        pre-release strings. If the prerelease string contains a dash ('-')
        then the dash and everything behind is removed. For example
        'pr54-0012' is parsed to 'ps54'.
    #>
    $validPreReleaseString, $preReleaseStringSuffix = $preReleaseString -split '-'

    if ($validPreReleaseString)
    {
        $fullModuleVersion =  $moduleVersion + '-' + $validPreReleaseString
    }
    else
    {
        $fullModuleVersion =  $moduleVersion
    }

    $moduleVersionParts = [PSCustomObject] @{
        Version = $moduleVersion
        PreReleaseString = $validPreReleaseString
        ModuleVersion = $fullModuleVersion
    }

    return $moduleVersionParts
}

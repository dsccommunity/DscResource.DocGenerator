<#
    .SYNOPSIS
        This is a build task that generates conceptual help.

    .PARAMETER ProjectPath
        The root path to the project. Defaults to $BuildRoot.

    .PARAMETER OutputDirectory
        The base directory of all output. Defaults to folder 'output' relative to
        the $BuildRoot.

    .PARAMETER ProjectName
        The project name. Defaults to the BaseName of the module manifest it finds
        in either the folder 'source', 'src, or a folder with the same name as
        the module.

    .PARAMETER SourcePath
        The path to the source folder name. Defaults to the same path where the
        module manifest is found.

    .PARAMETER ModuleVersionFolder
        The module version folder name of the build module, e.g. 'MyModule/99.1.1'.
        Defaults to the property MajorMinorPatch returned by GitVersion. If
        GitVersion is not present, the parameter defaults to version '0.0.1'.

    .PARAMETER BuildInfo
        The build info object from ModuleBuilder. Defaults to an empty hashtable.

    .NOTES
        This is a build task that is primarily meant to be run by Invoke-Build but
        wrapped by the Sampler project's build.ps1 (https://github.com/gaelcolas/Sampler).
#>
param
(
    [Parameter()]
    [System.String]
    $ProjectPath = (property ProjectPath $BuildRoot),

    [Parameter()]
    [System.String]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [Parameter()]
    [System.String]
    $ProjectName = (property ProjectName $(
            # Find the module manifest to deduce the Project Name
            (Get-ChildItem $BuildRoot\*\*.psd1 -Exclude @('build.psd1', 'analyzersettings.psd1') | Where-Object -FilterScript {
                    ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
                    $(
                        try
                        {
                            Test-ModuleManifest $_.FullName -ErrorAction Stop
                        }
                        catch
                        {
                            Write-Warning -Message $_
                            $false
                        }
                    )
                }).BaseName
        )
    ),

    [Parameter()]
    [System.String]
    $SourcePath = (property SourcePath $(
            (Get-ChildItem $BuildRoot\*\*.psd1 -Exclude @('build.psd1', 'analyzersettings.psd1') | Where-Object -FilterScript {
                    ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
                    $(
                        try
                        {
                            Test-ModuleManifest $_.FullName -ErrorAction Stop
                        }
                        catch
                        {
                            Write-Warning -Message $_
                            $false
                        }
                    )
                }).Directory.FullName
        )
    ),

    [Parameter()]
    [string]
    $ModuleVersion = (property ModuleVersion $(
            try
            {
                (gitversion | ConvertFrom-Json -ErrorAction Stop).NuGetVersionV2
            }
            catch
            {
                Write-Verbose -Message "Error attempting to use GitVersion $($_), falling back to default of '0.0.1'."
                '0.0.1'
            }
        )),

    [Parameter()]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: This task generates conceptual help for DSC resources.
task Generate_Conceptual_Help {
    if (-not (Split-Path -IsAbsolute $OutputDirectory))
    {
        $OutputDirectory = Join-Path -Path $ProjectPath -ChildPath $OutputDirectory
    }

    $ModuleVersionFolder, $PreReleaseString = $ModuleVersion -split '\-', 2

    $builtModulePath = Join-Path -Path (Join-Path -Path $OutputDirectory -ChildPath $ProjectName) -ChildPath $ModuleVersionFolder

    "`tProject Path            = $ProjectPath"
    "`tProject Name            = $ProjectName"
    "`tModule Version          = $ModuleVersion"
    "`tModule Version Folder   = $ModuleVersionFolder"
    "`tPrerelease String       = $PreReleaseString"
    "`tSource Path             = $SourcePath"
    "`tBuilt Module Path       = $builtModulePath"

    Write-Build Magenta "Generating conceptual help for all DSC resources based on source."

    New-DscResourcePowerShellHelp -ModulePath $SourcePath -DestinationModulePath $builtModulePath
}

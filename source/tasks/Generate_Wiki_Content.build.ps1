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
                            Test-ModuleManifest -Path $_.FullName -ErrorAction 'Stop'
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
                            Test-ModuleManifest -Path $_.FullName -ErrorAction 'Stop'
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
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: This task generates wiki documentation for the DSC resources.
task Generate_Wiki_Content {
    if (-not (Split-Path -IsAbsolute $OutputDirectory))
    {
        $OutputDirectory = Join-Path -Path $ProjectPath -ChildPath $OutputDirectory
    }

    $wikiOutputPath = Join-Path -Path $OutputDirectory -ChildPath "WikiContent"
    if ((Test-Path -Path $wikiOutputPath) -eq $false)
    {
        $null = New-Item -Path $wikiOutputPath -ItemType Directory
    }

    "`tProject Path            = $ProjectPath"
    "`tProject Name            = $ProjectName"
    "`tSource Path             = $SourcePath"
    "`tWiki Output Path        = $wikiOutputPath"

    Write-Build Magenta "Generating Wiki content for all DSC resources based on source."

    New-DscResourceWikiPage -ModulePath $SourcePath -OutputPath $wikiOutputPath
}

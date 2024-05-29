<#
    .SYNOPSIS
        This is a build task that generates conceptual help.

    .PARAMETER OutputDirectory
        The base directory of all output. Defaults to folder 'output' relative to
        the $BuildRoot.

    .PARAMETER ProjectName
        The project name. Defaults to the Project Name.

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
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [Parameter()]
    [System.String]
    $ProjectName = (property ProjectName $(Get-SamplerProjectName -BuildRoot $BuildRoot)),

    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: Package wiki documentation for the DSC resources.
task Package_Wiki_Content {
    # Get the values for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable

    "`tProject Name             = {0}" -f $ProjectName
    "`tOutput Directory         = {0}" -f $OutputDirectory

    $wikiOutputPath = Join-Path -Path $OutputDirectory -ChildPath 'WikiContent'
    $wikiArchiveSourcePath = Join-Path -Path $wikiOutputPath -ChildPath '*'
    $wikiPackagePath = Join-Path -Path $OutputDirectory -ChildPath 'WikiContent.zip'

    "`tWiki Output Path         = $wikiOutputPath"
    "`tWiki Archive Source Path = $wikiArchiveSourcePath"
    "`tWiki Package Path        = $wikiPackagePath"

    if (-not (Test-Path -Path $wikiOutputPath))
    {
        throw 'The Wiki Output Path does not exist. Please run the task Generate_Wiki_Content prior to running this task.'
    }

    Write-Build Magenta 'Packaging Wiki content.'

    # Overwrites any existing archive.
    Compress-Archive -Path $wikiArchiveSourcePath -DestinationPath $wikiPackagePath -CompressionLevel 'Optimal' -Force -ErrorAction 'Stop'
}

<#
    .SYNOPSIS
        This is a build task that generates conceptual help.

    .PARAMETER ProjectPath
        The root path to the project. Defaults to $BuildRoot.

    .PARAMETER OutputDirectory
        The base directory of all output. Defaults to folder 'output' relative to
        the $BuildRoot.

    .PARAMETER BuiltModuleSubdirectory
        Sub folder where you want to build the Module to (instead of $OutputDirectory/$ModuleName).
        This is especially useful when you want to build DSC Resources, but you don't want the
        `Get-DscResource` command to find several instances of the same DSC Resources because
        of the overlapping $Env:PSmodulePath (`$buildRoot/output` for the built module and `$buildRoot/output/RequiredModules`).

        In most cases I would recommend against setting $BuiltModuleSubdirectory.

    .PARAMETER VersionedOutputDirectory
        Whether the Module is built with its versioned Subdirectory, as you would see it on a System.
        For instance, if VersionedOutputDirectory is $true, the built module's ModuleBase would be: `output/MyModuleName/2.0.1/`

    .PARAMETER ProjectName
        The project name. Defaults to the empty string.

    .PARAMETER SourcePath
        The path to the source folder name. Defaults to the empty string.

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
    $BuiltModuleSubdirectory = (property BuiltModuleSubdirectory ''),

    [Parameter()]
    [System.Management.Automation.SwitchParameter]
    $VersionedOutputDirectory = (property VersionedOutputDirectory $true),

    [Parameter()]
    [System.String]
    $ProjectName = (property ProjectName ''),

    [Parameter()]
    [System.String]
    $SourcePath = (property SourcePath ''),

    [Parameter()]
    [System.String]
    $DocOutputFolder = (property DocOutputFolder 'WikiContent'),

    [Parameter()]
    [System.Management.Automation.SwitchParameter]
    $DebugTask = (property DebugTask $false),

    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: Generate wiki sidebar based on existing markdown files.
task Generate_Wiki_Sidebar {
    if (-not $PSBoundParameters.ContainsKey('DebugTask'))
    {
        $debugTask = [System.Boolean] $BuildInfo.'DscResource.DocGenerator'.Generate_Wiki_Sidebar.Debug
    }

    <#
        Only show debug information if Debug was set to 'true' in build configuration
        or if it was passed as a parameter.
    #>
    if ($debugTask)
    {
        $local:VerbosePreference = 'Continue'
        $local:DebugPreference = 'Continue'
        Write-Verbose -Message 'Running task with debug information.' -Verbose
    }

    $alwaysOverwrite = [System.Boolean] $BuildInfo.'DscResource.DocGenerator'.Generate_Wiki_Sidebar.AlwaysOverwrite

    # Get the values for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable

    $DocOutputFolder = Get-SamplerAbsolutePath -Path $DocOutputFolder -RelativeTo $OutputDirectory

    "`tDocs output folder path = '$DocOutputFolder'"
    ""

    $newGitHubWikiSidebarParameters = @{
        DocumentationPath = $DocOutputFolder
        ReplaceExisting   = $alwaysOverwrite
        Force             = $true
    }

    if ($debugTask)
    {
        $newGitHubWikiSidebarParameters.Verbose = $true
        $newGitHubWikiSidebarParameters.Debug = $true
    }

    New-GitHubWikiSidebar @newGitHubWikiSidebarParameters
}

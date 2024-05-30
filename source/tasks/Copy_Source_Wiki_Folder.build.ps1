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

    .PARAMETER WikiSourceFolderName
        The name of the folder that contains the source markdown files (e.g. 'Home.md')
        to publish to the wiki. The name should be relative to the SourcePath.
        Defaults to 'WikiSource'.

    .PARAMETER BuildInfo
        The build info object from ModuleBuilder. Defaults to an empty hashtable.

    .NOTES
        This is a build task that is primarily meant to be run by Invoke-Build but
        wrapped by the Sampler project's build.ps1 (https://github.com/gaelcolas/Sampler).

        The function Set-WikiModuleVersion needed to be made a public function
        for the build task to find it. Set-WikiModuleVersion function does not
        need to be public so if there is a way found in the future that makes it
        possible to have it as a private function then this code should refactored
        to make that happen.
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
    $WikiSourceFolderName = (property WikiSourceFolderName 'WikiSource'),

    [Parameter()]
    [System.String]
    $WikiOutputPath = (property WikiOutputPath ''),

    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: Generate wiki documentation for the DSC resources.
Task Copy_Source_Wiki_Folder {
    # Get the values for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable

    $wikiSourcePath = Join-Path -Path $SourcePath -ChildPath $WikiSourceFolderName
    $wikiOutputPath = Join-Path -Path $OutputDirectory -ChildPath 'WikiContent'

    $wikiSourceExist = Test-Path -Path $wikiSourcePath

    if ($wikiSourceExist)
    {
        "`tWiki Source Path        = $wikiSourcePath"
    }

    if ($wikiSourceExist)
    {
        Write-Build -Color 'Magenta' -Text 'Copying Wiki content from the Wiki source folder.'

        Copy-Item -Path (Join-Path $wikiSourcePath -ChildPath '*') -Destination $wikiOutputPath -Recurse -Force

        $homeMarkdownFilePath = Join-Path -Path $wikiOutputPath -ChildPath 'Home.md'

        if (Test-Path -Path $homeMarkdownFilePath)
        {
            Write-Build -Color 'Magenta' -Text 'Updating module version in Home.md if there are any placeholders found.'

            Set-WikiModuleVersion -Path $homeMarkdownFilePath -ModuleVersion $moduleVersion
        }
    }
}

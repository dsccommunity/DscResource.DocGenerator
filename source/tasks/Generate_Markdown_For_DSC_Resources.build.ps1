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
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: Generate wiki documentation for the DSC resources.
Task Generate_Markdown_For_DSC_Resources {
    # Get the values for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable

    $wikiOutputPath = Join-Path -Path $OutputDirectory -ChildPath 'WikiContent'

    Write-Build -Color 'Magenta' -Text 'Generating Wiki content for all DSC resources based on source and built module.'

    if ($BuildInfo.'DscResource.DocGenerator'.Generate_Wiki_Content)
    {
        Write-Warning -Message 'Build configuration is using the old configuration key ''Generate_Wiki_Content''. Update the build configuration to use the new configuration key ''Generate_Markdown_For_DSC_Resources'''

        $dscResourceMarkdownMetadata = $BuildInfo.'DscResource.DocGenerator'.Generate_Wiki_Content
    }
    else
    {
        $dscResourceMarkdownMetadata = $BuildInfo.'DscResource.DocGenerator'.Generate_Markdown_For_DSC_Resources
    }

    New-DscResourceWikiPage -SourcePath $SourcePath -BuiltModulePath $builtModuleBase -OutputPath $wikiOutputPath -Metadata $dscResourceMarkdownMetadata -Force
}

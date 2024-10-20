<#
    .SYNOPSIS
        This is a build task that modifies the markdown filenames to enhance the content
        for use in GitHub repository Wikis.

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
        The task does not use this parameter, see the notes below.

    .PARAMETER DocOutputFolder
        The path to the where the markdown documentation is written. Defaults to the
        folder `./output/WikiContent`.

    .PARAMETER ReplaceHyphen
        Specifies if hyphens in the markdown filenames should be replaced with
        non-breaking hyphens. Defaults to `$true`.

    .PARAMETER BuildInfo
        The build info object from ModuleBuilder. Defaults to an empty hashtable.

    .NOTES
        This is a build task that is primarily meant to be run by Invoke-Build but
        wrapped by the Sampler project's build.ps1 (https://github.com/gaelcolas/Sampler).

        Parameter SourcePath is intentionally added to the task even if it is not used,
        otherwise the tests fails. Most likely because the script Set-SamplerTaskVariable
        expects the variable to always be available.
#>
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('DscResource.AnalyzerRules/Measure-ParameterBlockParameterAttribute', '', Justification = 'For boolean values when using (property $true $false) fails in conversion between string and boolean when environment variable is used if set as advanced parameter ([Parameter()])')]
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
    $ReplaceHyphen = (property ReplaceHyphen $true),

    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: Modifies the markdown filenames to enhance the content for use in GitHub repository Wikis.
Task Prepare_Markdown_FileNames_For_GitHub_Publish {
    if ($PSVersionTable.PSVersion -lt '6.0')
    {
        Write-Warning -Message 'This task is not supported in Windows PowerShell.'

        return
    }

    # Get the values for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable

    $DocOutputFolder = Get-SamplerAbsolutePath -Path $DocOutputFolder -RelativeTo $OutputDirectory

    "`tDocs output folder path = '$DocOutputFolder'"
    "`tReplace Hyphen          = '$ReplaceHyphen'"
    ''

    if ($ReplaceHyphen)
    {
        $markdownFiles = Get-ChildItem -Path $DocOutputFolder -Filter '*.md'

        Write-Build -Color 'Magenta' -Text 'Replacing hyphens with non-breaking hyphens in markdown filenames.'

        # Replace the hyphen in the filename with the unicode non-breaking hyphen.
        $markdownFiles |
            Where-Object -Property 'Name' -Match '-' |
            ForEach-Object -Process {
                $newName = $_.Name -replace '-', [System.Char]::ConvertFromUtf32(0x2011)

                Write-Build -Color DarkGray -Text ('Renaming: {0} -> {1}' -f $_.Name, $newName)

                Rename-Item -Path $_.FullName -NewName $newName -Force
            }
    }
    else
    {
        Write-Build -Color 'Yellow' -Text 'Skipping renaming hyphens in markdown filenames.'
    }
}

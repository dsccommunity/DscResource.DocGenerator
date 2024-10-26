<#
    .SYNOPSIS
        This is a build task that modifies the wiki content to enhance the content
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
    $RemoveTopLevelHeader = (property RemoveTopLevelHeader $true),

    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: Modifies the wiki content to enhance the content for use in GitHub repository Wikis.
Task Clean_WikiContent_For_GitHub_Publish {
    if ($PSVersionTable.PSVersion -lt '6.0')
    {
        Write-Warning -Message 'This task is not supported in Windows PowerShell.'

        return
    }

    # Get the values for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable

    $DocOutputFolder = Get-SamplerAbsolutePath -Path $DocOutputFolder -RelativeTo $OutputDirectory

    "`tDocs output folder path = '$DocOutputFolder'"
    ''

    if ($RemoveTopLevelHeader)
    {
        $markdownFiles = Get-ChildItem -Path $DocOutputFolder -Filter '*.md'

        Write-Build -Color 'Magenta' -Text 'Removing top level header from markdown files if it is the same as the filename.'

        $markdownFiles |
            ForEach-Object -Process {
                $content = Get-Content -Path $_.FullName -Raw

                $hasTopHeader = $content -match '(?m)^#\s+([^\r\n]+)'

                $convertedBaseName = $_.BaseName -replace '-', ' '
                $convertedBaseName = $convertedBaseName -replace [System.Char]::ConvertFromUtf32(0x2011), '-'

                if ($hasTopHeader -and $Matches[1] -eq $convertedBaseName)
                {
                    Write-Build -Color DarkGray -Text ('Top level header is the same as the filename. Removing top level header from: {0}' -f $_.Name)

                    <#
                        Remove only the top level header (# Header) and any empty lines
                        following it. The regex should only target the first header found,
                        without affecting later top level headers.
                    #>
                    $content = $content -replace '(?m)^#\s+(.*)\s*', ''

                    # Save the updated content back to the file
                    Set-Content -Path $_.FullName -Value $content
                }
                elseif ($hasTopHeader)
                {
                    Write-Build -Color DarkGray -Text ('Top level header is different from the filename. Skipping: {0}' -f $_.Name)
                }
                else
                {
                    Write-Build -Color DarkGray -Text ('No top level header found in: {0}' -f $_.Name)
                }
            }
    }
}

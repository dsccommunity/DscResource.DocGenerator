<#
    .SYNOPSIS
        This is a build task that generates markdown for a modules public commands.

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

    .PARAMETER HelpCultureInfo
        Specifies the culture that documentation is generated for. Defaults to 'en-US'.

    .PARAMETER DependentTypePath
        Specifies an array of paths to .cs files that will be loaded with `Add-Type`
        prior to generating the markdown (to be able to load types that is used by
        command parameters). Defaults to an empty array.

    .PARAMETER DependentModule
        Specifies an array of module names that will be imported (to be able to
        load types that is used by command parameters). Defaults to an empty array.

    .PARAMETER WithModulePage
        Specifies if a module page is created in the output folder. Defaults to
        `$false`.

    .PARAMETER AlphabeticParamOrder
        Specifies if parameters are ordered alphabetically. See the PlatyPS command
        help for exceptions. Defaults to `$true`.

    .PARAMETER ExcludeDontShow
        Specifies that parameters with `[Parameter(DontShow)]` will be ignored.
        Defaults to `$true`.

    .PARAMETER BuildInfo
        The build info object from ModuleBuilder. Defaults to an empty hashtable.

    .NOTES
        This is a build task that is primarily meant to be run by Invoke-Build but
        wrapped by the Sampler project's build.ps1 (https://github.com/gaelcolas/Sampler).

        Parameter SourcePath is intentionally added to the task even if it is not used,
        otherwise the tests fails. Most likely because the script Set-SamplerTaskVariable
        expects the variable to always be available.
#>
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('DscResource.AnalyzerRules/Measure-ParameterBlockParameterAttribute', '', Justification='For boolean values when using (property $true $false) fails in conversion between string and boolean when environment variable is used if set as advanced parameter ([Parameter()])')]
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
    [System.Globalization.CultureInfo]
    $HelpCultureInfo = (property HelpCultureInfo 'en-US'),

    [Parameter()]
    [System.String[]]
    $DependentTypePath = (property DependentType @()),

    [Parameter()]
    [System.String[]]
    $DependentModule = (property DependentModule @()),

    $WithModulePage = (property WithModulePage $false),
    $AlphabeticParamOrder = (property AlphabeticParamOrder $true),
    $ExcludeDontShow = (property ExcludeDontShow $true), # cSpell:ignore Dont

    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: Generate markdown documentation for the public commands from the built module.
Task Generate_Markdown_For_Public_Commands {
    if (-not (Get-Module -Name 'PlatyPS' -ListAvailable))
    {
        Write-Warning -Message 'PlatyPS is not installed. Skipping. If public command documentation should be created please make sure PlatyPS is available in a path that is listed in $PSModulePath. It can be added to the configuration file RequiredModules.psd1 in the project.'

        return
    }

    # Get the values for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable

    $DocOutputFolder = Get-SamplerAbsolutePath -Path $DocOutputFolder -RelativeTo $OutputDirectory

    $helpVersion = (Split-ModuleVersion -ModuleVersion $ModuleVersion).Version

    "`tDocs output folder path             = '$DocOutputFolder'"
    "`tAlphabetic Parameter Order          = '$AlphabeticParamOrder'"
    "`tExclude Parameters With [Dont Show] = '$ExcludeDontShow'"
    "`tWith Module Page                    = '$WithModulePage'"
    "`tDependent types                     = '{0}'" -f ($DependentType -join "', '")
    "`tDependent Modules                   = '{0}'" -f ($DependentModule -join "', '")
    "`tLocale                              = '$HelpCultureInfo'"
    "`tHelp Version                        = '$helpVersion'"
    ""

    Write-Build -Color 'Magenta' -Text 'Creating markdown templates for command documentation.'

    $generateMarkdownScript = @"
`$env:PSModulePath = '$env:PSModulePath'
"@

    if ($DependentTypePath)
    {
        $generateMarkdownScript += @"
`n# Loading dependent types
Add-Type -Path '$DependentTypePath'
"@
    }

    if ($DependentModule)
    {
        $generateMarkdownScript += @"
`n# Import dependent modules
Import-Module -name '$DependentModule'
"@
    }

    $generateMarkdownScript += @"
`n# Import the module that help is generate for
`$importModule = Import-Module -Name '$ProjectName' -PassThru -ErrorAction 'Stop'

if (-not `$importModule)
{
    throw 'Failed to import the module ''$ProjectName''.'
}
elseif (`$importModule.ExportedCommands.Count -eq 0)
{
    Write-Warning -Message 'No public commands found in the module ''$ProjectName''. Skipping'

    return
}

`$newMarkdownHelpParams = @{
    Module                = '$ProjectName'
    OutputFolder          = '$DocOutputFolder'
    AlphabeticParamsOrder = `$$AlphabeticParamOrder
    WithModulePage        = `$$WithModulePage
    ExcludeDontShow       = `$$ExcludeDontShow
    Locale                = '$HelpCultureInfo'
    HelpVersion           = '$helpVersion'
    MetaData              = @{
        Type     = 'Command'
        Category = 'Commands'
    }
    Force                 = `$true
    ErrorAction           = 'Stop'
}

# Generate the markdown help
New-MarkdownHelp @newMarkdownHelpParams
"@

    Write-Build -Color DarkGray -Text $generateMarkdownScript

    $generateMarkdownScriptBlock = [ScriptBlock]::Create($generateMarkdownScript)

    $pwshPath = (Get-Process -Id $PID).Path

    <#
        The scriptblock is run in a separate process to avoid conflicts with
        other modules that are loaded in the current process.
    #>
    $markdownFiles = & $pwshPath -Command $generateMarkdownScriptBlock -ExecutionPolicy 'ByPass' -NoProfile

    Write-Build -Color DarkGray -Text "Generated markdown files:"

    $markdownFiles | ForEach-Object -Process {
        Write-Build -Color DarkGray -Text ("`t{0}" -f $_.FullName)
    }

    if (-not $?)
    {
        throw "Failed to generate markdown documentation for the public commands for module '$ProjectName'."
    }
    else
    {
        Write-Build -Color Green -Text 'Markdown for command documentation created for module '$ProjectName'.'
    }
}

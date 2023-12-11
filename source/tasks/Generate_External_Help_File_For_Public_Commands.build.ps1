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

        There are also parameters that are intentionally added to the task, that is so
        that other tasks that are run prior can change the values for the parameters
        through for example environment variables.
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
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: Generate help file for the public commands from the built module.
Task Generate_External_Help_File_For_Public_Commands {
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('DscResource.AnalyzerRules/Measure-ParameterBlockParameterAttribute', '', Justification='For boolean values when using (property $true $false) fails in conversion between string and boolean when environment variable is used if set as advanced parameter ([Parameter()])')]
    param
    (
        [Parameter()]
        [System.String]
        $DocOutputFolder = (property DocOutputFolder 'WikiContent'),

        [Parameter()]
        [System.Globalization.CultureInfo]
        $HelpCultureInfo = 'en-US'
    )

    if (-not (Get-Module -Name 'PlatyPS' -ListAvailable))
    {
        throw 'PlatyPS is not installed. Please make sure it is available in a path that is listed in $PSModulePath. It can be added to the configuration file RequiredModules.psd1 in the project.'
    }

    # Get the vales for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable

    $DocOutputFolder = Get-SamplerAbsolutePath -Path $DocOutputFolder -RelativeTo $OutputDirectory

    $buildModuleLocalePath = $BuiltModuleBase | Join-Path -ChildPath $HelpCultureInfo

    "`tDocs output folder path             = '$DocOutputFolder'"
    "`tAlphabetic Parameter Order          = '$AlphabeticParamOrder'"
    "`tWith Module Page                    = '$WithModulePage'"
    "`tDependent types                     = '{0}'" -f ($DependentType -join "', '")
    "`tDependent Modules                   = '{0}'" -f ($DependentModule -join "', '")
    "`tBuilt Module Locale Path            = '$buildModuleLocalePath'"

    $generateMarkdownScript = @"
`$env:PSModulePath = '$env:PSModulePath'
# Generate the help file
New-ExternalHelp -Path '$DocOutputFolder' -OutputPath '$buildModuleLocalePath' -Force
"@

    Write-Build -Color DarkGray -Text "$generateMarkdownScript"

    $generateMarkdownScriptBlock = [ScriptBlock]::Create($generateMarkdownScript)

    $pwshPath = (Get-Process -Id $PID).Path

    <#
        The scriptblock is run in a separate process to avoid conflicts with
        other modules that are loaded in the current process.
    #>
    & $pwshPath -Command $generateMarkdownScriptBlock -ExecutionPolicy 'ByPass'
}

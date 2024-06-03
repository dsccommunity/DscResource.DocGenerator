<#
    .SYNOPSIS
        This is a build task that generates an external help file for a module.

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

    .PARAMETER DocOutputFolder
        The path to the where the markdown documentation is found. Defaults to the
        folder `./output/WikiContent`.

    .PARAMETER HelpCultureInfo
        Specifies the culture that documentation is generated for. Defaults to 'en-US'.

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
    [System.Globalization.CultureInfo]
    $HelpCultureInfo = (property HelpCultureInfo 'en-US'),

    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: Generate external help file for the public commands from the built module.
Task Generate_External_Help_File_For_Public_Commands {
    if (-not (Get-Module -Name 'PlatyPS' -ListAvailable))
    {
        Write-Warning -Message 'PlatyPS is not installed. Skipping. If public command documentation should be created please make sure PlatyPS is available in a path that is listed in $PSModulePath. It can be added to the configuration file RequiredModules.psd1 in the project.'

        return
    }

    # Get the values for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable

    $DocOutputFolder = Get-SamplerAbsolutePath -Path $DocOutputFolder -RelativeTo $OutputDirectory

    $builtModuleLocalePath = $BuiltModuleBase | Join-Path -ChildPath $HelpCultureInfo.Name

    "`tDocs output folder path             = '$DocOutputFolder'"
    "`tBuilt Module Locale Path            = '$builtModuleLocalePath'"
    ""

    $generateMarkdownScript = @"
`$env:PSModulePath = '$env:PSModulePath'
# Generate the help file
New-ExternalHelp -Path '$DocOutputFolder' -OutputPath '$builtModuleLocalePath' -Force
"@

    Write-Build -Color DarkGray -Text $generateMarkdownScript

    $generateMarkdownScriptBlock = [ScriptBlock]::Create($generateMarkdownScript)

    $pwshPath = (Get-Process -Id $PID).Path

    <#
        The scriptblock is run in a separate process to avoid conflicts with
        other modules that are loaded in the current process.
    #>
    & $pwshPath -Command $generateMarkdownScriptBlock -ExecutionPolicy 'ByPass' -NoProfile

    if (-not $?)
    {
        throw "Failed to generate external help file for the module '$ProjectName'."
    }

    $externalHelpFile = Get-Item -Path (Join-Path -Path $builtModuleLocalePath -ChildPath "$ProjectName-help.xml") -ErrorAction 'Ignore'

    if ($externalHelpFile)
    {
        # Add a newline to the end of the help file to pass HQRM tests.
        Add-NewLine -FileInfo $externalHelpFile -AtEndOfFile

        Write-Build -Color 'Green' -Text "External help file generated for the module '$ProjectName'."
    }
    else
    {
        Write-Warning -Message "External help file not found at '$builtModuleLocalePath/$ProjectName-help.xml'. This is normal if there were no exported commands in the module."
    }
}

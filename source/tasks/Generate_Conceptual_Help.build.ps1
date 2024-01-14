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

    .PARAMETER MarkdownCodeRegularExpression
        An array with regular expressions that will be used to remove markdown code
        from the schema mof property descriptions. The regular expressions must be
        written so that capture group 0 returns the full match and the capture group
        1 returns the text that should be kept. For example the regular expression
        \`(.+?)\` will find `$true` which will be replaced to $true since that is
        what will be returned by capture group 1.

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
    $MarkdownCodeRegularExpression = (property MarkdownCodeRegularExpression @()),

    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: Generate conceptual help for DSC resources.
task Generate_Conceptual_Help {
    # Get the values for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable

    $configParameterName = 'MarkdownCodeRegularExpression'

    if (-not (Get-Variable -Name $configParameterName -ValueOnly -ErrorAction 'SilentlyContinue'))
    {
        # Variable is not set in context, try to use value from $BuildInfo.
        $configParameterValue = $BuildInfo.'DscResource.DocGenerator'.Generate_Conceptual_Help.$configParameterName

        <#
            Always set the value. It will be set to $null if the parameter does
            not exist in the variable $BuildInfo.

            Always setting this variable is a workaround because the the parameter
            MarkdownCodeRegularExpression's default value that uses 'property'
            will wrongly return a collection of 1 where item 1 has a blank value.
        #>
        Set-Variable -Name $configParameterName -Value $configParameterValue
    }

    if ($MarkdownCodeRegularExpression)
    {
        "`tMarkdownCodeRegularExpression = RegEx: {0}" -f ($MarkdownCodeRegularExpression -join ' | RegEx: ')
    }

    Write-Build Magenta 'Generating conceptual help for all DSC resources based on source.'

    $newDscResourcePowerShellHelpParameters = @{
        ModulePath                    = $SourcePath
        DestinationModulePath         = $builtModuleBase
        MarkdownCodeRegularExpression = $MarkdownCodeRegularExpression
        Force                         = $true
    }

    New-DscResourcePowerShellHelp @newDscResourcePowerShellHelpParameters
}

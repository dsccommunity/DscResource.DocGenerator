<#
    .SYNOPSIS
        This is a build task that generates conceptual help.

    .PARAMETER ProjectPath
        The root path to the project. Defaults to $BuildRoot.

    .PARAMETER OutputDirectory
        The base directory of all output. Defaults to folder 'output' relative to
        the $BuildRoot.

    .PARAMETER ProjectName
        The project name. Defaults to the BaseName of the module manifest it finds
        in either the folder 'source', 'src, or a folder with the same name as
        the module.

    .PARAMETER SourcePath
        The path to the source folder name. Defaults to the same path where the
        module manifest is found.

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
    $ProjectName = (property ProjectName $(Get-SamplerProjectName -BuildRoot $BuildRoot)),

    [Parameter()]
    [System.String]
    $SourcePath = (property SourcePath $(Get-SamplerSourcePath -BuildRoot $BuildRoot)),

    [Parameter()]
    [System.String]
    $MarkdownCodeRegularExpression = (property MarkdownCodeRegularExpression @()),

    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: This task generates conceptual help for DSC resources.
task Generate_Conceptual_Help {
    if (-not (Split-Path -IsAbsolute $OutputDirectory))
    {
        $OutputDirectory = Join-Path -Path $ProjectPath -ChildPath $OutputDirectory
    }

    $getBuiltModuleVersionParameters = @{
        OutputDirectory = $OutputDirectory
        ProjectName     = $ProjectName
    }

    $moduleVersion = Get-BuiltModuleVersion @getBuiltModuleVersionParameters
    $ModuleVersionFolder, $PreReleaseString = $moduleVersion -split '\-', 2

    $builtModulePath = Join-Path -Path (Join-Path -Path $OutputDirectory -ChildPath $ProjectName) -ChildPath $ModuleVersionFolder

    "`tProject Path                  = $ProjectPath"
    "`tProject Name                  = $ProjectName"
    "`tModule Version                = $moduleVersion"
    "`tModule Version Folder         = $ModuleVersionFolder"
    "`tPrerelease String             = $PreReleaseString"
    "`tSource Path                   = $SourcePath"
    "`tBuilt Module Path             = $builtModulePath"

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

    Write-Build Magenta "Generating conceptual help for all DSC resources based on source."

    $newDscResourcePowerShellHelpParameters = @{
        ModulePath                    = $SourcePath
        DestinationModulePath         = $builtModulePath
        MarkdownCodeRegularExpression = $MarkdownCodeRegularExpression
        Force                         = $true
    }

    New-DscResourcePowerShellHelp @newDscResourcePowerShellHelpParameters
}

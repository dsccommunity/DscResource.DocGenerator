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
        The project name. Defaults to the BaseName of the module manifest it finds
        in either the folder 'source', 'src, or a folder with the same name as
        the module.

    .PARAMETER SourcePath
        The path to the source folder name. Defaults to the same path where the
        module manifest is found.

    .PARAMETER WikiContentFolderName
        The name of the folder that contain the content to publish to the wiki.
        The name should be relative to the OutputDirectory. Defaults to 'WikiContent'.

    .PARAMETER GitHubToken
        The token to use to push a commit and tag to the wiki repository. Defaults
        to an empty string.

    .PARAMETER GitHubConfigUserEmail
        The e-mail address to use for the commit. Defaults to an empty string.

    .PARAMETER GitHubConfigUserName
        The username to use for the commit. Defaults to an empty string.

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
    $ProjectName = (property ProjectName $(Get-SamplerProjectName -BuildRoot $BuildRoot)),

    [Parameter()]
    [System.String]
    $SourcePath = (property SourcePath $(Get-SamplerSourcePath -BuildRoot $BuildRoot)),

    [Parameter()]
    [System.String]
    $WikiContentFolderName = (property WikiContentFolderName 'WikiContent'),

    [Parameter()]
    [System.String]
    $GitHubToken = (property GitHubToken ''),

    [Parameter()]
    [System.String]
    $GitHubConfigUserEmail = (property GitHubConfigUserEmail ''),

    [Parameter()]
    [System.String]
    $GitHubConfigUserName = (property GitHubConfigUserName ''),

    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

# Synopsis: This task publishes documentation to a GitHub Wiki repository.
task Publish_GitHub_Wiki_Content {

    if ([System.String]::IsNullOrEmpty($GitHubToken))
    {
        Write-Build Yellow 'Skipping task. Variable $GitHubToken not set via parent scope, as an environment variable, or passed to the build task.'
    }
    else
    {
        $OutputDirectory = Get-SamplerAbsolutePath -Path $OutputDirectory -RelativeTo $BuildRoot
        "`tOutputDirectory       = '$OutputDirectory'"
        $BuiltModuleSubdirectory = Get-SamplerAbsolutePath -Path $BuiltModuleSubdirectory -RelativeTo $OutputDirectory

        if ($VersionedOutputDirectory)
        {
            <#
                VersionedOutputDirectory is not [bool]'' nor $false nor [bool]$null
                Assume true, wherever it was set
            #>
            $VersionedOutputDirectory = $true
        }
        else
        {
            <#
                VersionedOutputDirectory may be [bool]'' but we can't tell where it's
                coming from, so assume the build info (Build.yaml) is right
            #>
            $VersionedOutputDirectory = $BuildInfo['VersionedOutputDirectory']
        }

        $GetBuiltModuleManifestParams = @{
            OutputDirectory          = $OutputDirectory
            BuiltModuleSubdirectory  = $BuiltModuleSubDirectory
            ModuleName               = $ProjectName
            VersionedOutputDirectory = $VersionedOutputDirectory
            ErrorAction              = 'Stop'
        }

        $builtModuleManifest = Get-SamplerBuiltModuleManifest @GetBuiltModuleManifestParams
        $builtModuleManifest = [string](Get-Item -Path $builtModuleManifest).FullName
        "`tBuilt Module Manifest         = '$builtModuleManifest'"

        $builtModuleBase = Get-SamplerBuiltModuleBase @GetBuiltModuleManifestParams
        $builtModuleBase = [string](Get-Item -Path $builtModuleBase).FullName
        "`tBuilt Module Base             = '$builtModuleBase'"

        $moduleVersion = Get-BuiltModuleVersion @GetBuiltModuleManifestParams
        $moduleVersionObject = Split-ModuleVersion -ModuleVersion $moduleVersion
        $moduleVersionFolder = $moduleVersionObject.Version
        $preReleaseTag = $moduleVersionObject.PreReleaseString

        "`tModule Version                = '$ModuleVersion'"
        "`tModule Version Folder         = '$moduleVersionFolder'"
        "`tPre-release Tag               = '$preReleaseTag'"

        "`tProject Path                  = $ProjectPath"
        "`tProject Name                  = $ProjectName"
        "`tSource Path                   = $SourcePath"
        "`tBuilt Module Base             = $builtModuleBase"

        # If variables are not set then update variables from the property values in the build.yaml.
        foreach ($gitHubConfigKey in @('GitHubConfigUserName', 'GitHubConfigUserEmail'))
        {
            if (-not (Get-Variable -Name $gitHubConfigKey -ValueOnly -ErrorAction 'SilentlyContinue'))
            {
                # Variable is not set in context, use $BuildInfo.GitHubConfig.<varName>
                $gitHubConfigKeyValue = $BuildInfo.GitHubConfig.($gitHubConfigKey)

                Set-Variable -Name $gitHubConfigKey -Value $gitHubConfigKeyValue
                Write-Build DarkGray "Set $gitHubConfigKey to $gitHubConfigKeyValue"
            }
        }

        $gitRemoteResult = Invoke-Git -WorkingDirectory $BuildRoot `
                                -Arguments @( 'remote', 'get-url', 'origin' )

        if ($gitRemoteResult.ExitCode -eq 0)
        {
            $remoteURL = $gitRemoteResult.StandardOutput
        }

        # Parse the URL for owner name and repository name.
        if ($remoteURL -match 'github')
        {
            $GHRepo = Get-GHOwnerRepoFromRemoteUrl -RemoteUrl $remoteURL
        }
        else
        {
            throw "Could not parse owner and repository from the git remote origin URL: '$remoteUrl'."
        }

        $wikiOutputPath = Join-Path -Path $OutputDirectory -ChildPath $WikiContentFolderName
        "`tWiki Output Path              = $wikiOutputPath"

        $publishWikiContentParameters = @{
            Path              = $wikiOutputPath
            OwnerName         = $GHRepo.Owner
            RepositoryName    = $GHRepo.Repository
            ModuleName        = $ProjectName
            ModuleVersion     = $moduleVersion
            GitHubAccessToken = $GitHubToken
            GitUserEmail      = $GitHubConfigUserEmail
            GitUserName       = $GitHubConfigUserName
        }

        Write-Build Magenta "Publishing Wiki content."

        Publish-WikiContent @publishWikiContentParameters
    }
}

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
    $ProjectName = (property ProjectName ''),

    [Parameter()]
    [System.String]
    $SourcePath = (property SourcePath ''),

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

# Synopsis: Publish documentation to a GitHub Wiki repository.
task Publish_GitHub_Wiki_Content {
    if ([System.String]::IsNullOrEmpty($GitHubToken))
    {
        Write-Build Yellow 'Skipping task. Variable $GitHubToken not set via parent scope, as an environment variable, or passed to the build task.'
    }
    else
    {
        $debugTask = $BuildInfo.'DscResource.DocGenerator'.Publish_GitHub_Wiki_Content.Debug

        # Only show debug information if Debug was set to 'true' in build configuration.
        if ($debugTask)
        {
            'Running task with debug information.'

            $local:VerbosePreference = 'Continue'
            $local:DebugPreference = 'Continue'
        }

        # Get the values for task variables, see https://github.com/gaelcolas/Sampler#task-variables.
        . Set-SamplerTaskVariable

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

        $invokeGitParameters = @{
            WorkingDirectory = $ProjectPath
            Arguments        = @('remote', 'get-url', 'origin')
            PassThru         = $true
        }

        if ($debugTask)
        {
            $invokeGitParameters.Verbose = $true
            $invokeGitParameters.Debug = $true
        }

        $gitRemoteResult = Invoke-Git @invokeGitParameters

        if ($gitRemoteResult.ExitCode -eq 0)
        {
            $remoteURL = $gitRemoteResult.StandardOutput -replace '\r?\n'
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

        if ($debugTask)
        {
            $publishWikiContentParameters.Verbose = $true
            $publishWikiContentParameters.Debug = $true
        }

        Write-Build Magenta 'Publishing Wiki content.'

        Publish-WikiContent @publishWikiContentParameters
    }
}

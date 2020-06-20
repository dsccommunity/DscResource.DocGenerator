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

    .PARAMETER WikiContentFolderName
        The name of the folder that contain the content to publish to the wiki.
        The name should be relative to the OutputDirectory. Defaults to 'WikiContent'.

    .PARAMETER WikiSourceFolderName
        The name of the folder that contain the source markdown files to publish to
        the wiki, e.g. 'Home.md'. The name should be relative to the SourcePath.
        Defaults to 'WikiSource'.

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
    $ProjectName = (property ProjectName $(
            # Find the module manifest to deduce the Project Name
            (Get-ChildItem $BuildRoot\*\*.psd1 -Exclude @('build.psd1', 'analyzersettings.psd1') | Where-Object -FilterScript {
                    ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
                    $(
                        try
                        {
                            Test-ModuleManifest -Path $_.FullName -ErrorAction 'Stop'
                        }
                        catch
                        {
                            Write-Warning -Message $_
                            $false
                        }
                    )
                }).BaseName
        )
    ),

    [Parameter()]
    [System.String]
    $SourcePath = (property SourcePath $(
            (Get-ChildItem $BuildRoot\*\*.psd1 -Exclude @('build.psd1', 'analyzersettings.psd1') | Where-Object -FilterScript {
                    ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
                    $(
                        try
                        {
                            Test-ModuleManifest -Path $_.FullName -ErrorAction 'Stop'
                        }
                        catch
                        {
                            Write-Warning -Message $_
                            $false
                        }
                    )
                }).Directory.FullName
        )
    ),

    [Parameter()]
    [System.String]
    $WikiContentFolderName = (property WikiContentFolderName 'WikiContent'),

    [Parameter()]
    [System.String]
    $WikiSourceFolderName = (property WikiSourceFolderName 'WikiSource'),

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
task Publish_GitHub_Wiki_Content -if ($GitHubToken) {
    if (-not (Split-Path -IsAbsolute $OutputDirectory))
    {
        $OutputDirectory = Join-Path -Path $ProjectPath -ChildPath $OutputDirectory
    }

    $getBuiltModuleVersionParameters = @{
        OutputDirectory = $OutputDirectory
        ProjectName     = $ProjectName
    }

    $moduleVersion = Get-BuiltModuleVersion @getBuiltModuleVersionParameters

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

    $remoteURL = git remote get-url origin

    # Parse the URL for owner name and repository name.
    if ($remoteURL -match '(http[s]?:\/\/)([^:\/\s]+)\/(\w+)\/(.+)')
    {
        $ownerName = $Matches[3]
        $repositoryName = $Matches[4]
    }
    else
    {
        throw 'Could not parse owner and repository from the git remote origin URL.'
    }

    "`tProject Path            = $ProjectPath"
    "`tProject Name            = $ProjectName"
    "`tModule Version          = $moduleVersion"
    "`tSource Path             = $SourcePath"
    "`tRepository Owner Name   = $ownerName"
    "`tRepository Name         = $repositoryName"
    "`tWiki Output Path        = $wikiOutputPath"

    $publishWikiContentParameters = @{
        Path = Join-Path -Path $OutputDirectory -ChildPath $WikiContentFolderName
        OwnerName = $ownerName
        RepositoryName = $repositoryName
        ModuleName = $ProjectName
        ModuleVersion = $moduleVersion
        GitHubAccessToken = $GitHubToken
        GitUserEmail = $GitHubConfigUserEmail
        GitUserName = $GitHubConfigUserName
    }

    $wikiSourcePath = Join-Path -Path $SourcePath -ChildPath $WikiSourceFolderName

    if (Test-Path -Path $wikiSourcePath)
    {
        $publishWikiContentParameters['WikiSourcePath'] = $wikiSourcePath

        "`tWiki Source Path        = $wikiSourcePath"
    }

    Write-Build Magenta "Publishing Wiki content."

    Publish-WikiContent @publishWikiContentParameters
}

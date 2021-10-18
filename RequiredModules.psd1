@{
    PSDependOptions             = @{
        AddToPath  = $true
        Target     = 'output\RequiredModules'
        Parameters = @{
            Repository = ''
        }
    }

    InvokeBuild                 = 'latest'
    PSScriptAnalyzer            = 'latest'
    Pester                      = '4.10.1'
    Plaster                     = 'latest'
    ModuleBuilder               = 'latest'

    Sampler                     = @{
        version = 'latest'
        Parameters = @{
            AllowPrerelease = $true
        }
    }

    'Sampler.GitHubTasks'       = 'latest'
    MarkdownLinkCheck           = 'latest'
    ChangelogManagement         = 'latest'
    'DscResource.Test'          = 'latest'
    'DscResource.AnalyzerRules' = 'latest'
    xDscResourceDesigner        = 'latest'
    # Build dependent modules
    'DscResource.Common'        = 'latest'
}

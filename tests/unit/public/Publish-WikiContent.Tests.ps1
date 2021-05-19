#region HEADER
$script:projectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$script:projectName = (Get-ChildItem -Path "$script:projectPath\*\*.psd1" | Where-Object -FilterScript {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try
            {
                Test-ModuleManifest -Path $_.FullName -ErrorAction Stop
            }
            catch
            {
                $false
            })
    }).BaseName

$script:moduleName = Get-Module -Name $script:projectName -ListAvailable | Select-Object -First 1
Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

Import-Module $script:moduleName -Force -ErrorAction 'Stop'
#endregion HEADER

InModuleScope $script:moduleName {
    Describe 'Publish-WikiContent' {
        Context 'When publishing Wiki content' {
            BeforeAll {
                Mock -CommandName Push-Location
                Mock -CommandName Pop-Location
                Mock -CommandName Set-Location
                Mock -CommandName Copy-WikiFolder
                Mock -CommandName New-WikiSidebar
                Mock -CommandName New-WikiFooter
                Mock -CommandName Remove-Item

                Mock -CommandName Invoke-Git -MockWith {
                    return 0
                }
            }

            It 'Should not throw an exception and call the expected mocks' {
                $mockPublishWikiContentParameters = @{
                    Path               = $TestDrive
                    OwnerName          = 'owner'
                    RepositoryName     = 'repo'
                    ModuleName         = 'TestModule'
                    ModuleVersion      = '1.0.0'
                    GitHubAccessToken  = 'token'
                    GitUserEmail       = 'user@host.com'
                    GitUserName        = 'User'
                    GlobalCoreAutoCrLf = 'true'
                }

                { Publish-WikiContent @mockPublishWikiContentParameters } | Should -Not -Throw

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[1] -eq 'config' -and
                    $Arguments[2] -eq '--global' -and
                    $Arguments[3] -eq 'core.autocrlf' -and
                    $Arguments[4] -eq 'true'
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[1] -eq 'clone' -and
                    $Arguments[2] -eq "https://github.com/$($mockPublishWikiContentParameters.OwnerName)/$($mockPublishWikiContentParameters.RepositoryName).wiki.git"
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Copy-WikiFolder -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName New-WikiSidebar -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName New-WikiFooter -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[1] -eq 'config' -and
                    $Arguments[2] -eq '--local' -and
                    $Arguments[3] -eq 'user.email' -and
                    $Arguments[4] -eq $mockPublishWikiContentParameters.GitUserEmail
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[1] -eq 'config' -and
                    $Arguments[2] -eq '--local' -and
                    $Arguments[3] -eq 'user.name' -and
                    $Arguments[4] -eq $mockPublishWikiContentParameters.GitUserName
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[1] -eq 'remote' -and
                    $Arguments[2] -eq 'set-url' -and
                    $Arguments[3] -eq 'origin' -and
                    $Arguments[4] -eq "https://$($mockPublishWikiContentParameters.GitUserName):$($mockPublishWikiContentParameters.GithubAccessToken)@github.com/$($mockPublishWikiContentParameters.OwnerName)/$($mockPublishWikiContentParameters.RepositoryName).wiki.git"
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[1] -eq 'add' -and
                    $Arguments[2] -eq '*'
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[1] -eq 'commit' -and
                    $Arguments[2] -eq '--message' -and
                    $Arguments[3] -eq ($localizedData.UpdateWikiCommitMessage -f $mockPublishWikiContentParameters.ModuleVersion) -and
                    $Arguments[4] -eq '--quiet'
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[1] -eq 'tag' -and
                    $Arguments[2] -eq '--annotate' -and
                    $Arguments[3] -eq $mockPublishWikiContentParameters.ModuleVersion -and
                    $Arguments[4] -eq '--message' -and
                    $Arguments[5] -eq $mockPublishWikiContentParameters.ModuleVersion
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[1] -eq 'push' -and
                    $Arguments[2] -eq 'origin' -and
                    $Arguments[3] -eq '--quiet'
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[1] -eq 'push' -and
                    $Arguments[2] -eq 'origin' -and
                    $Arguments[3] -eq $mockPublishWikiContentParameters.ModuleVersion -and
                    $Arguments[4] -eq '--quiet'
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Remove-Item -Exactly -Times 1 -Scope It
            }
        }

        Context 'When there is no new content to publishing to Wiki' {
            BeforeAll {
                Mock -CommandName Push-Location
                Mock -CommandName Pop-Location
                Mock -CommandName Set-Location
                Mock -CommandName Copy-WikiFolder
                Mock -CommandName New-WikiSidebar
                Mock -CommandName New-WikiFooter
                Mock -CommandName Remove-Item
                Mock -CommandName Set-WikiModuleVersion

                Mock -CommandName Invoke-Git -MockWith {
                    return 1
                }
            }

            It 'Should not throw an exception and call the expected mocks' {
                $mockPublishWikiContentParameters = @{
                    Path               = $TestDrive
                    OwnerName          = 'owner'
                    RepositoryName     = 'repo'
                    ModuleName         = 'TestModule'
                    ModuleVersion      = '1.0.0'
                    GitHubAccessToken  = 'token'
                    GitUserEmail       = 'user@host.com'
                    GitUserName        = 'User'
                    GlobalCoreAutoCrLf = 'true'
                }

                { Publish-WikiContent @mockPublishWikiContentParameters } | Should -Not -Throw

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[1] -eq 'config' -and
                    $Arguments[2] -eq '--global' -and
                    $Arguments[3] -eq 'core.autocrlf' -and
                    $Arguments[4] -eq 'true'
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[1] -eq 'clone' -and
                    $Arguments[2] -eq "https://github.com/$($mockPublishWikiContentParameters.OwnerName)/$($mockPublishWikiContentParameters.RepositoryName).wiki.git"
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Copy-WikiFolder -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName New-WikiSidebar -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName New-WikiFooter -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[1] -eq 'config' -and
                    $Arguments[2] -eq '--local' -and
                    $Arguments[3] -eq 'user.email' -and
                    $Arguments[4] -eq $mockPublishWikiContentParameters.GitUserEmail
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[1] -eq 'config' -and
                    $Arguments[2] -eq '--local' -and
                    $Arguments[3] -eq 'user.name' -and
                    $Arguments[4] -eq $mockPublishWikiContentParameters.GitUserName
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[1] -eq 'remote' -and
                    $Arguments[2] -eq 'set-url' -and
                    $Arguments[3] -eq 'origin' -and
                    $Arguments[4] -eq "https://$($mockPublishWikiContentParameters.GitUserName):$($mockPublishWikiContentParameters.GithubAccessToken)@github.com/$($mockPublishWikiContentParameters.OwnerName)/$($mockPublishWikiContentParameters.RepositoryName).wiki.git"
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[1] -eq 'add' -and
                    $Arguments[2] -eq '*'
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[1] -eq 'commit' -and
                    $Arguments[2] -eq '--message' -and
                    $Arguments[3] -eq ($localizedData.UpdateWikiCommitMessage -f $mockPublishWikiContentParameters.ModuleVersion) -and
                    $Arguments[4] -eq '--quiet'
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[1] -eq 'tag' -and
                    $Arguments[2] -eq '--annotate' -and
                    $Arguments[3] -eq $mockPublishWikiContentParameters.ModuleVersion -and
                    $Arguments[4] -eq '--message' -and
                    $Arguments[5] -eq $mockPublishWikiContentParameters.ModuleVersion
                } -Exactly -Times 0 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[1] -eq 'push' -and
                    $Arguments[2] -eq 'origin' -and
                    $Arguments[3] -eq '--quiet'
                } -Exactly -Times 0 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[1] -eq 'push' -and
                    $Arguments[2] -eq 'origin' -and
                    $Arguments[3] -eq $mockPublishWikiContentParameters.ModuleVersion -and
                    $Arguments[4] -eq '--quiet'
                } -Exactly -Times 0 -Scope It

                Assert-MockCalled -CommandName Remove-Item -Exactly -Times 1 -Scope It
            }
        }
    }
}

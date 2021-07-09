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
        Context 'When cloning Wiki content fails' {
            BeforeAll {
                Mock -CommandName Copy-WikiFolder
                Mock -CommandName New-WikiSidebar
                Mock -CommandName New-WikiFooter
                Mock -CommandName Remove-Item
                Mock -CommandName Show-InvokeGitReturn

                Mock -CommandName Invoke-Git -MockWith {
                    return @{
                        'ExitCode' = 0
                        'StandardOutput' = 'Standard Output 0'
                        'StandardError' = 'Standard Error 0'
                        'Command' = 'some command'
                        'WorkingDirectory' = 'c:\some\directory'
                    }
                }

                Mock -CommandName Invoke-Git -MockWith {
                    return @{
                        'ExitCode' = 128
                        'StandardOutput' = 'Standard Output 128'
                        'StandardError' = 'fatal: remote error: access denied or repository not exported: /335792891.wiki.git'
                        'Command' = "clone https://github.com/$($mockPublishWikiContentParameters.OwnerName)/$($mockPublishWikiContentParameters.RepositoryName).wiki.git"
                        'WorkingDirectory' = 'c:\some\directory'
                    }
                } -ParameterFilter {
                    $Arguments[0] -eq 'clone' -and
                    $Arguments[1] -eq "https://github.com/$($mockPublishWikiContentParameters.OwnerName)/$($mockPublishWikiContentParameters.RepositoryName).wiki.git"
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
                    $Arguments[0] -eq 'clone' -and
                    $Arguments[1] -eq "https://github.com/$($mockPublishWikiContentParameters.OwnerName)/$($mockPublishWikiContentParameters.RepositoryName).wiki.git"
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'config' -and
                    $Arguments[1] -eq '--global' -and
                    $Arguments[2] -eq 'core.autocrlf' -and
                    $Arguments[3] -eq 'true'
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Show-InvokeGitReturn -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Copy-WikiFolder -Exactly -Times 0 -Scope It

                Assert-MockCalled -CommandName New-WikiSidebar -Exactly -Times 0 -Scope It

                Assert-MockCalled -CommandName New-WikiFooter -Exactly -Times 0 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'config' -and
                    $Arguments[1] -eq '--local' -and
                    $Arguments[2] -eq 'user.email' -and
                    $Arguments[3] -eq $mockPublishWikiContentParameters.GitUserEmail
                } -Exactly -Times 0 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'config' -and
                    $Arguments[1] -eq '--local' -and
                    $Arguments[2] -eq 'user.name' -and
                    $Arguments[3] -eq $mockPublishWikiContentParameters.GitUserName
                } -Exactly -Times 0 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'remote' -and
                    $Arguments[1] -eq 'set-url' -and
                    $Arguments[2] -eq 'origin' -and
                    $Arguments[3] -eq "https://$($mockPublishWikiContentParameters.GitUserName):$($mockPublishWikiContentParameters.GithubAccessToken)@github.com/$($mockPublishWikiContentParameters.OwnerName)/$($mockPublishWikiContentParameters.RepositoryName).wiki.git"
                } -Exactly -Times 0 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'add' -and
                    $Arguments[1] -eq '*'
                } -Exactly -Times 0 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'commit' -and
                    $Arguments[1] -eq '--message' -and
                    $Arguments[2] -eq "`"$($localizedData.UpdateWikiCommitMessage -f $mockPublishWikiContentParameters.ModuleVersion)`""
                } -Exactly -Times 0 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'tag' -and
                    $Arguments[1] -eq '--annotate' -and
                    $Arguments[2] -eq $mockPublishWikiContentParameters.ModuleVersion -and
                    $Arguments[3] -eq '--message' -and
                    $Arguments[4] -eq $mockPublishWikiContentParameters.ModuleVersion
                } -Exactly -Times 0 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'push' -and
                    $Arguments[1] -eq 'origin'
                } -Exactly -Times 0 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'push' -and
                    $Arguments[1] -eq 'origin' -and
                    $Arguments[2] -eq $mockPublishWikiContentParameters.ModuleVersion
                } -Exactly -Times 0 -Scope It

                Assert-MockCalled -CommandName Remove-Item -Exactly -Times 1 -Scope It
            }
        }

        Context 'When publishing Wiki content' {
            BeforeAll {
                Mock -CommandName Copy-WikiFolder
                Mock -CommandName New-WikiSidebar
                Mock -CommandName New-WikiFooter
                Mock -CommandName Remove-Item
                Mock -CommandName Show-InvokeGitReturn

                Mock -CommandName Invoke-Git -MockWith {
                    return @{
                        'ExitCode' = 0
                        'StandardOutput' = 'Standard Output 0'
                        'StandardError' = 'Standard Error 0'
                        'Command' = 'some command'
                        'WorkingDirectory' = 'c:\some\directory'
                    }
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

                Assert-MockCalled -CommandName Show-InvokeGitReturn -Exactly -Times 0 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'clone' -and
                    $Arguments[1] -eq "https://github.com/$($mockPublishWikiContentParameters.OwnerName)/$($mockPublishWikiContentParameters.RepositoryName).wiki.git"
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'config' -and
                    $Arguments[1] -eq '--global' -and
                    $Arguments[2] -eq 'core.autocrlf' -and
                    $Arguments[3] -eq 'true'
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Copy-WikiFolder -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName New-WikiSidebar -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName New-WikiFooter -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'config' -and
                    $Arguments[1] -eq '--local' -and
                    $Arguments[2] -eq 'user.email' -and
                    $Arguments[3] -eq $mockPublishWikiContentParameters.GitUserEmail
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'config' -and
                    $Arguments[1] -eq '--local' -and
                    $Arguments[2] -eq 'user.name' -and
                    $Arguments[3] -eq $mockPublishWikiContentParameters.GitUserName
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'remote' -and
                    $Arguments[1] -eq 'set-url' -and
                    $Arguments[2] -eq 'origin' -and
                    $Arguments[3] -eq "https://$($mockPublishWikiContentParameters.GitUserName):$($mockPublishWikiContentParameters.GithubAccessToken)@github.com/$($mockPublishWikiContentParameters.OwnerName)/$($mockPublishWikiContentParameters.RepositoryName).wiki.git"
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'add' -and
                    $Arguments[1] -eq '*'
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'commit' -and
                    $Arguments[1] -eq '--message' -and
                    $Arguments[2] -eq "`"$($localizedData.UpdateWikiCommitMessage -f $mockPublishWikiContentParameters.ModuleVersion)`""
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'tag' -and
                    $Arguments[1] -eq '--annotate' -and
                    $Arguments[2] -eq $mockPublishWikiContentParameters.ModuleVersion -and
                    $Arguments[3] -eq '--message' -and
                    $Arguments[4] -eq $mockPublishWikiContentParameters.ModuleVersion
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'push' -and
                    $Arguments[1] -eq 'origin' -and
                    $Arguments[2] -eq $null
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'push' -and
                    $Arguments[1] -eq 'origin' -and
                    $Arguments[2] -eq $mockPublishWikiContentParameters.ModuleVersion
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Remove-Item -Exactly -Times 1 -Scope It
            }
        }

        Context 'When there is no new content to publishing to Wiki' {
            BeforeAll {
                Mock -CommandName Copy-WikiFolder
                Mock -CommandName New-WikiSidebar
                Mock -CommandName New-WikiFooter
                Mock -CommandName Remove-Item
                Mock -CommandName Set-WikiModuleVersion
                Mock -CommandName Show-InvokeGitReturn

                Mock -CommandName Invoke-Git -MockWith {
                    return @{
                        'ExitCode' = 0
                        'StandardOutput' = 'Standard Output 0'
                        'StandardError' = 'Standard Error 0'
                        'Command' = 'some command'
                        'WorkingDirectory' = 'c:\some\directory'
                    }
                }

                Mock -CommandName Invoke-Git -MockWith {
                    return @{
                        'ExitCode' = 1
                        'StandardOutput' = 'Standard Output 1'
                        'StandardError' = 'Standard Error 1'
                        'Command' = 'some command'
                        'WorkingDirectory' = 'c:\some\directory'
                    }
                } -ParameterFilter {
                        $Arguments[0] -eq 'commit' -and
                        $Arguments[1] -eq '--message' -and
                        $Arguments[2] -eq "`"$($localizedData.UpdateWikiCommitMessage -f $ModuleVersion)`""
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

                Assert-MockCalled -CommandName Show-InvokeGitReturn -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'clone' -and
                    $Arguments[1] -eq "https://github.com/$($mockPublishWikiContentParameters.OwnerName)/$($mockPublishWikiContentParameters.RepositoryName).wiki.git"
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'config' -and
                    $Arguments[1] -eq '--global' -and
                    $Arguments[2] -eq 'core.autocrlf' -and
                    $Arguments[3] -eq 'true'
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Copy-WikiFolder -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName New-WikiSidebar -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName New-WikiFooter -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'config' -and
                    $Arguments[1] -eq '--local' -and
                    $Arguments[2] -eq 'user.email' -and
                    $Arguments[3] -eq $mockPublishWikiContentParameters.GitUserEmail
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'config' -and
                    $Arguments[1] -eq '--local' -and
                    $Arguments[2] -eq 'user.name' -and
                    $Arguments[3] -eq $mockPublishWikiContentParameters.GitUserName
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'remote' -and
                    $Arguments[1] -eq 'set-url' -and
                    $Arguments[2] -eq 'origin' -and
                    $Arguments[3] -eq "https://$($mockPublishWikiContentParameters.GitUserName):$($mockPublishWikiContentParameters.GithubAccessToken)@github.com/$($mockPublishWikiContentParameters.OwnerName)/$($mockPublishWikiContentParameters.RepositoryName).wiki.git"
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'add' -and
                    $Arguments[1] -eq '*'
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'commit' -and
                    $Arguments[1] -eq '--message' -and
                    $Arguments[2] -eq "`"$($localizedData.UpdateWikiCommitMessage -f $mockPublishWikiContentParameters.ModuleVersion)`""
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'tag' -and
                    $Arguments[1] -eq '--annotate' -and
                    $Arguments[2] -eq $mockPublishWikiContentParameters.ModuleVersion -and
                    $Arguments[3] -eq '--message' -and
                    $Arguments[4] -eq $mockPublishWikiContentParameters.ModuleVersion
                } -Exactly -Times 0 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'push' -and
                    $Arguments[1] -eq 'origin'
                } -Exactly -Times 0 -Scope It

                Assert-MockCalled -CommandName Invoke-Git -ParameterFilter {
                    $Arguments[0] -eq 'push' -and
                    $Arguments[1] -eq 'origin' -and
                    $Arguments[2] -eq $mockPublishWikiContentParameters.ModuleVersion
                } -Exactly -Times 0 -Scope It

                Assert-MockCalled -CommandName Remove-Item -Exactly -Times 1 -Scope It
            }
        }
    }
}

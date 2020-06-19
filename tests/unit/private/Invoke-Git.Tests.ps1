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
    Describe 'Invoke-Git' {
        BeforeAll {
            # stub for git so we can mock it.
            function git {}
        }

        Context 'When calling Invoke-Git' {
            BeforeAll {
                Mock -CommandName 'git'
            }

            It 'Should call git without throwing' {
                { Invoke-Git -Arguments 'config', '--local', 'user.email', 'user@host.com' } | Should -Not -Throw
            }
        }

        Context 'When calling Invoke-Git with an access token' {
            BeforeAll {
                Mock -CommandName 'git'
                Mock -CommandName Write-Debug
            }

            It 'Should call git but mask access token in debug message' {
                { Invoke-Git -Arguments 'remote', 'set-url', 'origin', 'https://name:5ea239f132736de237492ff3@github.com/repository.wiki.git' -Debug } | Should -Not -Throw

                Assert-MockCalled -CommandName Write-Debug -ParameterFilter {
                    $Message -match 'https://name:RedactedToken@github.com/repository.wiki.git'
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When git exits with error code 1' {
            BeforeAll {
                Mock -CommandName 'git' -MockWith {
                    $script:LASTEXITCODE = 1
                }
            }

            AfterAll {
                $script:LASTEXITCODE = 0
            }

            It 'Should not throw an exception' {
                { Invoke-Git -Arguments 'status' } | Should -Not -Throw
            }
        }

        Context 'When git exits with an error code higher than 1' {
            BeforeAll {
                Mock -CommandName 'git' -MockWith {
                    $script:LASTEXITCODE = 2
                }
            }

            AfterAll {
                $script:LASTEXITCODE = 0
            }

            It 'Should throw an exception with the correct exit code' {
                { Invoke-Git -Arguments 'status' } | Should -Throw '2'
            }
        }
    }
}

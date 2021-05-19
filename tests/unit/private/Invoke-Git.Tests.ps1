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
            $workingDirectory = @{ [string] 'FullName' = "$TestDrive\TestWorkingDirectory" }
            $mockProcess = New-MockObject -Type System.Diagnostics.Process
            $mockProcess | Add-Member -MemberType ScriptMethod -Name 'Start' -Value { $true } -Force
            $mockProcess | Add-Member -MemberType ScriptMethod -Name 'WaitForExit' -Value { $true } -Force
            $mockProcess | Add-Member -MemberType ScriptProperty -Name ExitCode -Value { 0 } -Force
            $mockProcess | Add-Member -MemberType ScriptProperty -Name WorkingDirectory -Value { '' } -Force

            Mock -CommandName New-Object -MockWith { return $mockProcess } -ParameterFilter { $TypeName -eq 'System.Diagnostics.Process' } -Verifiable
        }

        Context 'When calling Invoke-Git' {
            It 'Should call without throwing' {
                { Invoke-Git -Arguments $workingDirectory.FullName, 'config', '--local', 'user.email', 'user@host.com' } | Should -Not -Throw

                Assert-VerifiableMock
            }
        }

        Context 'When calling Invoke-Git with an access token' {
            BeforeAll {
                Mock -CommandName Write-Debug
            }

            It 'Should call git but mask access token in debug message' {
                { Invoke-Git -Arguments $workingDirectory.FullName, 'remote', 'set-url', 'origin', 'https://name:5ea239f132736de237492ff3@github.com/repository.wiki.git' -Debug } | Should -Not -Throw

                Assert-MockCalled -CommandName Write-Debug -ParameterFilter {
                    $Message -match 'https://name:RedactedToken@github.com/repository.wiki.git'
                } -Exactly -Times 1 -Scope It

                Assert-VerifiableMock
            }
        }

        Context 'When git exits with error code 1' {
            BeforeAll {
                $mockProcess | Add-Member -MemberType ScriptProperty -Name ExitCode -Value { 1 } -Force
            }

            It 'Should not throw an exception' {
                { Invoke-Git -Arguments $workingDirectory.FullName, 'status' } | Should -Not -Throw

                Assert-VerifiableMock
            }
            It 'Should return 1' {
                $returnCode = Invoke-Git -Arguments $workingDirectory.FullName, 'status'
                $returnCode | Should -BeExactly 1

                Assert-VerifiableMock
            }
        }

        Context 'When git exits with an error code higher than 1' {
            BeforeAll {
                $mockProcess | Add-Member -MemberType ScriptProperty -Name 'ExitCode' -Value { 128 } -Force

                $mockProcess | Add-Member -MemberType ScriptProperty -Name 'StandardOutput' -Value {
                    New-Object -TypeName 'Object' | `
                        Add-Member -MemberType ScriptMethod -Name 'ReadToEnd' -Value { 'Standard Output Message' } -PassThru -Force
                } -Force

                $mockProcess | Add-Member -MemberType ScriptProperty -Name 'StandardError' -Value {
                    New-Object -TypeName 'Object' | `
                        Add-Member -MemberType ScriptMethod -Name 'ReadToEnd' -Value { 'Standard Error Message' } -PassThru -Force
                } -Force

                Mock -CommandName Write-Warning
            }

            It 'Should produce ExitCode=128 and Write-Warning' {
                $returnCode = Invoke-Git -Arguments $workingDirectory.FullName, 'status'
                $returnCode | Should -BeExactly '128'

                Assert-MockCalled -CommandName Write-Warning -ParameterFilter {
                    $Message -eq $($localizedData.UnexpectedInvokeGitReturnCode -f $mockProcess.ExitCode)
                } -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Write-Warning -ParameterFilter {
                    $Message -eq $('  PWD: {0}' -f $($workingDirectory.FullName))
                } -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Write-Warning -ParameterFilter {
                    $Message -eq '  git status'
                } -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Write-Warning -ParameterFilter {
                    $Message -eq '  OUTPUT: Standard Output Message'
                } -Exactly -Times 1 -Scope It
                Assert-MockCalled -CommandName Write-Warning -ParameterFilter {
                    $Message -eq '  ERROR: Standard Error Message'
                } -Exactly -Times 1 -Scope It

                Assert-VerifiableMock
            }
        }
    }
}

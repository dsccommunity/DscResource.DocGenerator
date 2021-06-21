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
            $mockProcess = New-MockObject -Type System.Diagnostics.Process
            $mockProcess | Add-Member -MemberType ScriptMethod -Name 'Start' -Value { $true } -Force
            $mockProcess | Add-Member -MemberType ScriptMethod -Name 'WaitForExit' -Value { $true } -Force
            $mockProcess | Add-Member -MemberType ScriptProperty -Name ExitCode -Value { 0 } -Force
            $mockProcess | Add-Member -MemberType ScriptProperty -Name WorkingDirectory -Value { '' } -Force

            Mock -CommandName New-Object -MockWith { return $mockProcess } -ParameterFilter { $TypeName -eq 'System.Diagnostics.Process' } -Verifiable
        }

        Context 'When calling Invoke-Git' {
            BeforeAll {
                $mockProcess | Add-Member -MemberType ScriptProperty -Name 'StandardOutput' -Value {
                    New-Object -TypeName 'Object' | `
                        Add-Member -MemberType ScriptMethod -Name 'ReadToEnd' -Value { 'Standard Output Message 0' } -PassThru -Force
                } -Force

                $mockProcess | Add-Member -MemberType ScriptProperty -Name 'StandardError' -Value {
                    New-Object -TypeName 'Object' | `
                        Add-Member -MemberType ScriptMethod -Name 'ReadToEnd' -Value { 'Standard Error Message 0' } -PassThru -Force
                } -Force
            }
            It 'Should complete with ExitCode=0' {

                $result = Invoke-Git -WorkingDirectory $TestDrive `
                                -Arguments @( 'config', '--local', 'user.email', 'user@host.com' )

                $result.ExitCode | Should -BeExactly 0

                $result.StandardOutput | Should -BeExactly 'Standard Output Message 0'

                $result.StandardError | Should -BeExactly 'Standard Error Message 0'

                Assert-VerifiableMock
            }
        }

        Context 'When calling Invoke-Git with an access token' {
            BeforeAll {
                $mockProcess | Add-Member -MemberType ScriptProperty -Name ExitCode -Value { 1 } -Force

                $mockProcess | Add-Member -MemberType ScriptProperty -Name 'StandardOutput' -Value {
                    New-Object -TypeName 'Object' | `
                        Add-Member -MemberType ScriptMethod -Name 'ReadToEnd' -Value { 'Standard Output Message 1' } -PassThru -Force
                } -Force

                $mockProcess | Add-Member -MemberType ScriptProperty -Name 'StandardError' -Value {
                    New-Object -TypeName 'Object' | `
                        Add-Member -MemberType ScriptMethod -Name 'ReadToEnd' -Value { 'Standard Error Message 1' } -PassThru -Force
                } -Force

                Mock -CommandName Write-Debug
            }

            It 'Should complete with ExitCode=1 and mask access token in debug message' {

                $result = Invoke-Git -WorkingDirectory $TestDrive `
                            -Arguments @( 'remote', 'set-url', 'origin', 'https://name:5ea239f132736de237492ff3@github.com/repository.wiki.git' ) `
                            -Debug

                $result.ExitCode | Should -BeExactly 1

                $result.StandardOutput | Should -BeExactly 'Standard Output Message 1'

                $result.StandardError | Should -BeExactly 'Standard Error Message 1'

                Assert-MockCalled -CommandName Write-Debug -ParameterFilter {
                    $Message -match 'https://name:RedactedToken@github.com/repository.wiki.git'
                } -Exactly -Times 1 -Scope It

                Assert-VerifiableMock
            }
        }

        Context 'When git exits with an error code higher than 1' {
            BeforeAll {
                $mockProcess | Add-Member -MemberType ScriptProperty -Name 'ExitCode' -Value { 128 } -Force

                $mockProcess | Add-Member -MemberType ScriptProperty -Name 'StandardOutput' -Value {
                    New-Object -TypeName 'Object' | `
                        Add-Member -MemberType ScriptMethod -Name 'ReadToEnd' -Value { 'Standard Output Message 128' } -PassThru -Force
                } -Force

                $mockProcess | Add-Member -MemberType ScriptProperty -Name 'StandardError' -Value {
                    New-Object -TypeName 'Object' | `
                        Add-Member -MemberType ScriptMethod -Name 'ReadToEnd' -Value { 'Standard Error Message 128' } -PassThru -Force
                } -Force
            }

            It 'Should complete with ExitCode=128' {
                $result = Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status' )

                $result.ExitCode | Should -BeExactly 128

                $result.StandardOutput | Should -BeExactly 'Standard Output Message 128'

                $result.StandardError | Should -BeExactly 'Standard Error Message 128'

                Assert-VerifiableMock
            }
        }
    }
}

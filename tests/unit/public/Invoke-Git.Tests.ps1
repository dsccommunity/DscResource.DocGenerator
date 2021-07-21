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
            $mockProcess | Add-Member -MemberType ScriptProperty -Name WorkingDirectory -Value { '' } -Force

            $mockProcess | Add-Member -MemberType ScriptProperty -Name 'StandardOutput' -Value {
                New-Object -TypeName 'Object' | `
                    Add-Member -MemberType ScriptMethod -Name 'ReadToEnd' -Value { 'Standard Output Message' } -PassThru -Force
            } -Force

            $mockProcess | Add-Member -MemberType ScriptProperty -Name 'StandardError' -Value {
                New-Object -TypeName 'Object' | `
                    Add-Member -MemberType ScriptMethod -Name 'ReadToEnd' -Value { 'Standard Error Message' } -PassThru -Force
            } -Force

            Mock -CommandName New-Object -MockWith { return $mockProcess } -ParameterFilter { $TypeName -eq 'System.Diagnostics.Process' } -Verifiable
            Mock -CommandName Out-GitResult
        }

        Context 'When git ExitCode -eq 0' {
            BeforeAll {
                $mockProcess | Add-Member -MemberType ScriptProperty -Name 'ExitCode' -Value { 0 } -Force
            }

            It 'Should not throw, return result with -PassThru' {
                $result = Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status', '--verbose' ) -PassThru

                $result.ExitCode | Should -BeExactly 0

                $result.StandardOutput | Should -BeExactly 'Standard Output Message'

                $result.StandardError | Should -BeExactly 'Standard Error Message'

                Assert-MockCalled -CommandName Out-GitResult -Exactly -Times 0 -Scope It

                Assert-VerifiableMock
            }

            It 'Should not throw, return result with -PassThru, call Out-GitResult via -Verbose' {
                $result = Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status', '--verbose' ) -PassThru -Verbose

                $result.ExitCode | Should -BeExactly 0

                $result.StandardOutput | Should -BeExactly 'Standard Output Message'

                $result.StandardError | Should -BeExactly 'Standard Error Message'

                Assert-MockCalled -CommandName Out-GitResult -Exactly -Times 1 -Scope It

                Assert-VerifiableMock
            }

            It 'Should not throw, return result with -PassThru, call Out-GitResult via -Debug' {
                $result = Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status', '--verbose' ) -PassThru -Debug

                $result.ExitCode | Should -BeExactly 0

                $result.StandardOutput | Should -BeExactly 'Standard Output Message'

                $result.StandardError | Should -BeExactly 'Standard Error Message'

                Assert-MockCalled -CommandName Out-GitResult -Exactly -Times 1 -Scope It

                Assert-VerifiableMock
            }

            It 'Should not throw without -PassThru' {
                { Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status', '--verbose' ) } | Should -Not -Throw

                Assert-MockCalled -CommandName Out-GitResult -Exactly -Times 0 -Scope It

                Assert-VerifiableMock
            }

            It 'Should not throw without -PassThru, call Out-GitResult via -Verbose' {
                { Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status', '--verbose' ) -Verbose } | Should -Not -Throw

                Assert-MockCalled -CommandName Out-GitResult -Exactly -Times 1 -Scope It

                Assert-VerifiableMock
            }

            It 'Should not throw without -PassThru, call Out-GitResult via -Debug' {
                { Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status', '--verbose' ) -Debug } | Should -Not -Throw

                Assert-MockCalled -CommandName Out-GitResult -Exactly -Times 1 -Scope It

                Assert-VerifiableMock
            }
        }

        Context 'When git ExitCode -ne 0' {
            BeforeAll {
                $mockProcess | Add-Member -MemberType ScriptProperty -Name 'ExitCode' -Value { 128 } -Force
            }

            It 'Should not throw, return result with -PassThru' {
                $result = Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status', '--verbose' ) -PassThru

                $result.ExitCode | Should -BeExactly 128

                $result.StandardOutput | Should -BeExactly 'Standard Output Message'

                $result.StandardError | Should -BeExactly 'Standard Error Message'

                Assert-MockCalled -CommandName Out-GitResult -Exactly -Times 0 -Scope It

                Assert-VerifiableMock
            }

            It 'Should not throw, return result with -PassThru, call Out-GitResult via -Verbose' {
                $result = Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status', '--verbose' ) -PassThru -Verbose

                $result.ExitCode | Should -BeExactly 128

                $result.StandardOutput | Should -BeExactly 'Standard Output Message'

                $result.StandardError | Should -BeExactly 'Standard Error Message'

                Assert-MockCalled -CommandName Out-GitResult -Exactly -Times 1 -Scope It

                Assert-VerifiableMock
            }

            It 'Should not throw, return result with -PassThru, call Out-GitResult via -Debug' {
                $result = Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status', '--verbose' ) -PassThru -Debug

                $result.ExitCode | Should -BeExactly 128

                $result.StandardOutput | Should -BeExactly 'Standard Output Message'

                $result.StandardError | Should -BeExactly 'Standard Error Message'

                Assert-MockCalled -CommandName Out-GitResult -Exactly -Times 1 -Scope It

                Assert-VerifiableMock
            }

            It 'Should throw without -PassThru' {
                { Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status', '--verbose' ) } | Should -Throw

                Assert-MockCalled -CommandName Out-GitResult -Exactly -Times 0 -Scope It

                Assert-VerifiableMock
            }

            It 'Should throw without -PassThru, call Out-GitResult via -Verbose' {
                { Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status', '--verbose' ) -Verbose } | Should -Throw

                Assert-MockCalled -CommandName Out-GitResult -Exactly -Times 1 -Scope It

                Assert-VerifiableMock
            }

            It 'Should throw without -PassThru, call Out-GitResult via -Debug' {
                { Invoke-Git -WorkingDirectory $TestDrive -Arguments @( 'status', '--verbose' ) -Debug } | Should -Throw

                Assert-MockCalled -CommandName Out-GitResult -Exactly -Times 1 -Scope It

                Assert-VerifiableMock
            }
        }

        Context 'When throwing an error' {
            BeforeAll {
                $mockProcess | Add-Member -MemberType ScriptProperty -Name 'ExitCode' -Value { 128 } -Force
            }

            $testCases = @(
                @{ 'Command' = @('status');             'ErrorMessage' = 'status';        },
                @{ 'Command' = @('status','-v');        'ErrorMessage' = 'status -v...';  },
                @{ 'Command' = @('status','--verbose'); 'ErrorMessage' = 'status --v...'; }
            )

            It "Should throw exact using <Command>" -TestCases $testCases {
                param( $Command, $ErrorMessage )

                $throwMessage = "$($script:localizedData.InvokeGitCommandDebug -f $ErrorMessage)`n" +`
                                "$($script:localizedData.InvokeGitExitCodeMessage -f 128)`n" +`
                                "$($script:localizedData.InvokeGitStandardOutputMessage -f 'Standard Output Message')`n" +`
                                "$($script:localizedData.InvokeGitStandardErrorMessage -f 'Standard Error Message')`n"

                { Invoke-Git -WorkingDirectory $TestDrive -Arguments $Command } | Should -Throw $throwMessage

                Assert-MockCalled -CommandName Out-GitResult -Exactly -Times 0 -Scope It
                Assert-VerifiableMock
            }
        }
    }
}

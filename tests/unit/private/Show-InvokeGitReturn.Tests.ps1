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
    Describe 'Show-InvokeGitReturn' {
        BeforeAll {
            Mock -CommandName Write-Verbose
            Mock -CommandName Write-Debug
        }

        Context 'Using basic command' {
            It 'Should call expected mocks' {
                $mockHashTable = @{
                    'ExitCode' = 128
                    'StandardOutput' = 'StandardOutput-128'
                    'StandardError' = 'StandardError-128'
                    'Command' = 'status'
                    'WorkingDirectory' = 'C:\some\path\'
                }

                { Show-InvokeGitReturn @mockHashTable } | Should -Not -Throw

                Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                    $Message -eq "$($script:localizedData.InvokeGitStandardOutputMessage -f $mockHashTable.StandardOutput)"
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                    $Message -eq "$($script:localizedData.InvokeGitStandardErrorMessage -f $mockHashTable.StandardError)"
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                    $Message -eq "$($script:localizedData.InvokeGitExitCodeMessage -f $mockHashTable.ExitCode)"
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Write-Debug -ParameterFilter {
                    $Message -like "$($script:localizedData.InvokeGitCommandDebug -f $mockHashTable.Command)"
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Write-Debug -ParameterFilter {
                    $Message -like "$($script:localizedData.InvokeGitWorkingDirectoryDebug -f $mockHashTable.WorkingDirectory)"
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'Using custom clone message' {
            It 'Should write clone message and call expected mocks' {

                $mockHashTable = @{
                    'ExitCode' = 128
                    'StandardOutput' = 'StandardOutput-128'
                    'StandardError' = 'StandardError-128'
                    'Command' = 'clone https://github.com/test/repo.git'
                    'WorkingDirectory' = 'C:\some\path\'
                }

                { Show-InvokeGitReturn @mockHashTable } | Should -Not -Throw

                Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                    $Message -eq $script:localizedData.WikiGitCloneFailMessage
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                    $Message -eq "$($script:localizedData.InvokeGitStandardOutputMessage -f $mockHashTable.StandardOutput)"
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                    $Message -eq "$($script:localizedData.InvokeGitStandardErrorMessage -f $mockHashTable.StandardError)"
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                    $Message -eq "$($script:localizedData.InvokeGitExitCodeMessage -f $mockHashTable.ExitCode)"
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Write-Debug -ParameterFilter {
                    $Message -like "$($script:localizedData.InvokeGitCommandDebug -f $mockHashTable.Command)"
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Write-Debug -ParameterFilter {
                    $Message -like "$($script:localizedData.InvokeGitWorkingDirectoryDebug -f $mockHashTable.WorkingDirectory)"
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'Using custom commit message' {
            It 'Should write commit message and call expected mocks' {

                $mockHashTable = @{
                    'ExitCode' = 128
                    'StandardOutput' = 'StandardOutput-128'
                    'StandardError' = 'StandardError-128'
                    'Command' = 'commit --message "some message"'
                    'WorkingDirectory' = 'C:\some\path\'
                }

                { Show-InvokeGitReturn @mockHashTable } | Should -Not -Throw

                Assert-MockCalled -CommandName Write-Verbose -ParameterFilter { #custom
                    $Message -eq $script:localizedData.NothingToCommitToWiki
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                    $Message -eq "$($script:localizedData.InvokeGitStandardOutputMessage -f $mockHashTable.StandardOutput)"
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                    $Message -eq "$($script:localizedData.InvokeGitStandardErrorMessage -f $mockHashTable.StandardError)"
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Write-Verbose -ParameterFilter {
                    $Message -eq "$($script:localizedData.InvokeGitExitCodeMessage -f $mockHashTable.ExitCode)"
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Write-Debug -ParameterFilter {
                    $Message -like "$($script:localizedData.InvokeGitCommandDebug -f $mockHashTable.Command)"
                } -Exactly -Times 1 -Scope It

                Assert-MockCalled -CommandName Write-Debug -ParameterFilter {
                    $Message -like "$($script:localizedData.InvokeGitWorkingDirectoryDebug -f $mockHashTable.WorkingDirectory)"
                } -Exactly -Times 1 -Scope It
            }
        }
    }
}

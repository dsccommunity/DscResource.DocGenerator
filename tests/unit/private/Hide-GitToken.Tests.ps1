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
    Describe 'Hide-GitToken' {
        BeforeAll {
            $returnedValue = 'remote add origin https://**REDACTED-TOKEN**@github.com/owner/repo.git'
        }
        Context 'When command contains a legacy GitHub token' {
            BeforeAll {
                $legacyToken = (1..40 | %{ ('abcdef1234567890').ToCharArray() | Get-Random }) -join ''
            }
            It "Should redact: $legacyToken" {
                $result = Hide-GitToken -Command @( 'remote', 'add', 'origin', "https://$legacyToken@github.com/owner/repo.git" )

                $result -eq $returnedValue | Should -Be $true
            }
        }
        Context 'When command contains a GitHub 5 char token' {
            $newToken = (1..1 | %{ ('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890').ToCharArray() | Get-Random }) -join ''
            $testTokens = @(
                @{ 'Token' = "ghp_$newToken" },
                @{ 'Token' = "gho_$newToken" },
                @{ 'Token' = "ghu_$newToken" },
                @{ 'Token' = "ghs_$newToken" },
                @{ 'Token' = "ghr_$newToken" }
            )

            It "Should redact: '<Token>'" -TestCases $testTokens {
                param( $Token )

                $result = Hide-GitToken -Command @( 'remote', 'add', 'origin', "https://$Token@github.com/owner/repo.git" )

                $result -eq $returnedValue | Should -Be $true
            }
        }
        Context 'When command contains a GitHub 100 char token' {
            $newToken = (1..96 | %{ ('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890').ToCharArray() | Get-Random }) -join ''
            $testTokens = @(
                @{ 'Token' = "ghp_$newToken" },
                @{ 'Token' = "gho_$newToken" },
                @{ 'Token' = "ghu_$newToken" },
                @{ 'Token' = "ghs_$newToken" },
                @{ 'Token' = "ghr_$newToken" }
            )

            It "Should redact: '<Token>'" -TestCases $testTokens {
                param( $Token )

                $result = Hide-GitToken -Command @( 'remote', 'add', 'origin', "https://$Token@github.com/owner/repo.git" )

                $result -eq $returnedValue | Should -Be $true
            }
        }
        Context 'When command contains a GitHub 200 char token' {
            $newToken = (1..196 | %{ ('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890').ToCharArray() | Get-Random }) -join ''
            $testTokens = @(
                @{ 'Token' = "ghp_$newToken" },
                @{ 'Token' = "gho_$newToken" },
                @{ 'Token' = "ghu_$newToken" },
                @{ 'Token' = "ghs_$newToken" },
                @{ 'Token' = "ghr_$newToken" }
            )

            It "Should redact: '<Token>'" -TestCases $testTokens {
                param( $Token )

                $result = Hide-GitToken -Command @( 'remote', 'add', 'origin', "https://$Token@github.com/owner/repo.git" )

                $result -eq $returnedValue | Should -Be $true
            }
        }
        Context 'When command contains a GitHub 255 char token' {
            $newToken = (1..251 | %{ ('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890').ToCharArray() | Get-Random }) -join ''
            $testTokens = @(
                @{ 'Token' = "ghp_$newToken" },
                @{ 'Token' = "gho_$newToken" },
                @{ 'Token' = "ghu_$newToken" },
                @{ 'Token' = "ghs_$newToken" },
                @{ 'Token' = "ghr_$newToken" }
            )

            It "Should redact: '<Token>'" -TestCases $testTokens {
                param( $Token )

                $result = Hide-GitToken -Command @( 'remote', 'add', 'origin', "https://$Token@github.com/owner/repo.git" )

                $result -eq $returnedValue | Should -Be $true
            }
        }
    }
}

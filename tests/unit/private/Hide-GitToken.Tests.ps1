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
        Context 'When invoked' {
            BeforeAll {
                $returnedValue = 'remote add origin https://**REDACTED-TOKEN**@github.com/owner/repo.git'
                $legacyToken = (1..40 | %{ ('abcdef1234567890').ToCharArray() | Get-Random }) -join ''
                $newTokenLength = Get-Random -Minimum 1 -Maximum 251
                $newToken = (1..$newTokenLength | %{ ('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890').ToCharArray() | Get-Random }) -join ''
            }
            # gh(p|o|u|s|r)_([A-Za-z0-9]{1,255})
            $testTokens = @(
                @{ 'Token' = "$legacyToken"  },
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

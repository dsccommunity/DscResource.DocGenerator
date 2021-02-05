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
    Describe 'Get-ResourceExampleAsMarkdown' {
        Context 'When there are no examples for a resource' {
            BeforeAll {
                Mock -CommandName Get-ChildItem
                Mock -CommandName Write-Warning
            }

            It 'Should not throw and write a warning message' {
                 { Get-ResourceExampleAsMarkdown -Path $TestDrive } | Should -Not -Throw

                 Assert-MockCalled -CommandName Write-Warning -ParameterFilter {
                    $Message -eq ($script:localizedData.NoExampleFileFoundWarning -f 'MyResource')
                 } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When there are ' {
            BeforeAll {
                $mockExamplePath = Join-Path $TestDrive -ChildPath 'Example1.ps1'

                Mock -CommandName Get-DscResourceWikiExampleContent
                Mock -CommandName Get-ChildItem -MockWith {
                    return @{
                        FullName = $mockExamplePath
                    }
                }
            }

            It 'Should not throw and call the correct mock to generate the output' {
                { Get-ResourceExampleAsMarkdown -Path $TestDrive } | Should -Not -Throw

                Assert-MockCalled -CommandName Get-DscResourceWikiExampleContent -ParameterFilter {
                   $ExamplePath -eq $mockExamplePath `
                   -and $ExampleNumber -eq 1
                } -Exactly -Times 1 -Scope It
           }
        }
    }
}

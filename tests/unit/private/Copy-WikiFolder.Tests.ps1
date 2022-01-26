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
    Describe 'Copy-WikiFolder' {
        BeforeAll {
            $mockCopyWikiFileParameters = @{
                Path            = "$TestDrive\TestModule"
                DestinationPath = $TestDrive
            }

            $mockFileInfo = @(
                @{
                    Name          = 'Home.md'
                    DirectoryName = "$($mockCopyWikiFileParameters.Path)\WikiSource"
                    FullName      = "$($mockCopyWikiFileParameters.Path)\WikiSource\Home.md"
                }
                @{
                    Name          = 'image.png'
                    DirectoryName = "$($mockCopyWikiFileParameters.Path)\WikiSource\Media"
                    FullName      = "$($mockCopyWikiFileParameters.Path)\WikiSource\Media\image.png"
                }
            )

            Mock -CommandName Copy-Item
        }

        Context 'When there are no files to copy' {
            BeforeAll {
                Mock -CommandName Get-ChildItem
            }

            It 'Should not throw an exception' {
                { Copy-WikiFolder @mockCopyWikiFileParameters } | Should -Not -Throw
            }

            It 'Should not copy any files' {
                Assert-MockCalled -CommandName Copy-Item -Exactly -Times 0 -Scope Context
            }
        }

        Context 'When there are files to copy' {
            BeforeAll {
                Mock -CommandName Get-ChildItem -MockWith {
                    return $mockfileInfo
                }
            }

            It 'Should not throw an exception' {
                { Copy-WikiFolder @mockCopyWikiFileParameters } | Should -Not -Throw
            }

            It 'Should copy the correct number of files' {
                Assert-MockCalled -CommandName Copy-Item -Exactly -Times 2 -Scope Context
            }
        }
    }
}

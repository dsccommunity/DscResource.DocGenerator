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
    Describe 'New-TempFolder' {
        BeforeAll {
            $mockPath = @{
                Name = 'l55xoanl.ojy'
            }
        }

        Context 'When a new temp folder is created' {
            BeforeAll {
                Mock -CommandName New-Item -ParameterFilter {
                    $ItemType -eq 'Directory'
                } -MockWith {
                    return $mockPath
                }
            }

            It 'Should not throw' {
                { New-TempFolder } | Should -Not -Throw
            }

            It 'Should call the expected mocks' {
                Assert-MockCalled -CommandName New-Item -ParameterFilter {
                    $ItemType -eq 'Directory'
                } -Exactly -Times 1 -Scope Context
            }
        }

        Context 'When a new temp folder cannot be created' {
            BeforeAll {
                Mock -CommandName New-Item -ParameterFilter {
                    $ItemType -eq 'Directory'
                } -MockWith {
                    return $false
                }
            }

            It 'Should throw the correct error' {
                $tempPath = [System.IO.Path]::GetTempPath()

                { New-TempFolder } | Should -Throw ($script:localizedData.NewTempFolderCreationError -f $tempPath)
            }

            It 'Should call the expected mocks' {
                Assert-MockCalled -CommandName New-Item -ParameterFilter {
                    $ItemType -eq 'Directory'
                } -Exactly -Times 10
            }
        }
    }
}

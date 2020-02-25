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
    Describe 'Get-ModuleVersion' {
        Context 'When ModuleVersion is not $null' {
            It 'Should return the correct module version' {
                Get-ModuleVersion -ModuleVersion '1.0.0-preview1' | Should -Be '1.0.0-preview1'
            }

            It 'Should return the correct module version when it contained metadata' {
                Get-ModuleVersion -ModuleVersion '1.0.0-preview1+metadata.2019-01-01' | Should -Be '1.0.0-preview1'
            }
        }

        Context 'When ModuleVersion is $null' {
            Context 'When module manifest has a prerelease string set' {
                BeforeAll {
                    Mock -CommandName Import-PowerShellDataFile -MockWith {
                        return @{
                            ModuleVersion = '2.0.0'
                            PrivateData = @{
                                PSData = @{
                                    Prerelease = 'preview2'
                                }
                            }
                        }
                    }
                }

                It 'Should return the correct module version' {
                    Get-ModuleVersion -OutputDirectory $TestDrive -ProjectName 'MyModule' | Should -Be '2.0.0-preview2'
                }
            }

            Context 'When module manifest does not have prerelease string set' {
                BeforeAll {
                    Mock -CommandName Import-PowerShellDataFile -MockWith {
                        return @{
                            ModuleVersion = '2.0.0'
                            PrivateData = @{
                                PSData = @{
                                    Prerelease = ''
                                }
                            }
                        }
                    }
                }

                It 'Should return the correct module version' {
                    Get-ModuleVersion -OutputDirectory $TestDrive -ProjectName 'MyModule' | Should -Be '2.0.0'
                }
            }
        }

    }
}

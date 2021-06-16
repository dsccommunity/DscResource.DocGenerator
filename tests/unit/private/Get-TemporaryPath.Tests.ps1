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
    Describe 'Get-TemporaryPath' {
        # Mocks
        $script:mockTempPath = 'temp path'
        $script:mockTmpDirPath = 'tmpdir path'

        $script:getItemTemp_mock = @{
            Name = 'TEMP'
            Value = $script:mockTempPath
        }

        $script:getItemTmpDir_mock = @{
            Name = 'TMPDIR'
            Value = $script:mockTmpDirPath
        }

        # Parameter filters
        $script:testPath_parameterFilter = {
            $Path -eq 'variable:IsWindows'
        }

        $script:getItemTemp_parameterFilter = {
            $Path -eq 'env:TEMP'
        }

        $script:getItemTmpDir_parameterFilter = {
            $Path -eq 'env:TMPDIR'
        }

        $script:getVariableIsWindows_parameterFilter = {
            $Name -eq 'IsWindows' -and `
            $ValueOnly -eq $true
        }

        $script:getVariableIsLinux_parameterFilter = {
            $Name -eq 'IsLinux' -and `
            $ValueOnly -eq $true
        }

        $script:getVariableIsMacOs_parameterFilter = {
            $Name -eq 'IsMacOS' -and `
            $ValueOnly -eq $true
        }

        Context 'When run on Windows PowerShell 5.1 or lower' {
            BeforeAll {
                Mock `
                    -CommandName Test-Path `
                    -MockWith { $false } `
                    -ParameterFilter $script:testPath_parameterFilter

                Mock `
                    -CommandName Get-Item `
                    -MockWith { $script:getItemTemp_mock } `
                    -ParameterFilter $script:getItemTemp_parameterFilter

                Mock `
                    -CommandName Get-Variable `
                    -ParameterFilter $script:getVariableIsWindows_parameterFilter

                Mock `
                    -CommandName Get-Variable `
                    -ParameterFilter $script:getVariableIsLinux_parameterFilter

                Mock `
                    -CommandName Get-Variable `
                    -ParameterFilter $script:getVariableIsMacOs_parameterFilter
            }

            It 'Should not throw exception' {
                {
                    $script:getTemporaryPathResult = Get-TemporaryPath
                } | Should -Not -Throw
            }

            It 'Should return the temp path' {
                $script:getTemporaryPathResult | Should -BeExactly $script:mockTempPath
            }
        }

        Context 'When run on PowerShell 6 or above on Windows' {
            BeforeAll {
                Mock `
                    -CommandName Test-Path `
                    -MockWith { $true } `
                    -ParameterFilter $script:testPath_parameterFilter

                Mock `
                    -CommandName Get-Item `
                    -MockWith { $script:getItemTemp_mock } `
                    -ParameterFilter $script:getItemTemp_parameterFilter

                Mock `
                    -CommandName Get-Variable `
                    -MockWith { $true } `
                    -ParameterFilter $script:getVariableIsWindows_parameterFilter

                Mock `
                    -CommandName Get-Variable `
                    -MockWith { $false } `
                    -ParameterFilter $script:getVariableIsLinux_parameterFilter

                Mock `
                    -CommandName Get-Variable `
                    -MockWith { $false } `
                    -ParameterFilter $script:getVariableIsMacOs_parameterFilter
            }

            It 'Should not throw exception' {
                {
                    $script:getTemporaryPathResult = Get-TemporaryPath
                } | Should -Not -Throw
            }

            It 'Should return the temp path' {
                $script:getTemporaryPathResult | Should -BeExactly $script:mockTempPath
            }
        }

        Context 'When run on PowerShell 6 or above on MacOS' {
            BeforeAll {
                Mock `
                    -CommandName Test-Path `
                    -MockWith { $true } `
                    -ParameterFilter $script:testPath_parameterFilter

                Mock `
                    -CommandName Get-Item `
                    -MockWith { $script:getItemTmpDir_mock } `
                    -ParameterFilter $script:getItemTmpDir_parameterFilter

                Mock `
                    -CommandName Get-Variable `
                    -MockWith { $false } `
                    -ParameterFilter $script:getVariableIsWindows_parameterFilter

                Mock `
                    -CommandName Get-Variable `
                    -MockWith { $false } `
                    -ParameterFilter $script:getVariableIsLinux_parameterFilter

                Mock `
                    -CommandName Get-Variable `
                    -MockWith { $true } `
                    -ParameterFilter $script:getVariableIsMacOs_parameterFilter
            }

            It 'Should not throw exception' {
                {
                    $script:getTemporaryPathResult = Get-TemporaryPath
                } | Should -Not -Throw
            }

            It 'Should return the tmpdir path' {
                $script:getTemporaryPathResult | Should -BeExactly $script:mockTmpDirPath
            }
        }

        Context 'When run on PowerShell 6 or above on Linux' {
            BeforeAll {
                Mock `
                    -CommandName Test-Path `
                    -MockWith { $true } `
                    -ParameterFilter $script:testPath_parameterFilter

                Mock `
                    -CommandName Get-Variable `
                    -MockWith { $false } `
                    -ParameterFilter $script:getVariableIsWindows_parameterFilter

                Mock `
                    -CommandName Get-Variable `
                    -MockWith { $true } `
                    -ParameterFilter $script:getVariableIsLinux_parameterFilter

                Mock `
                    -CommandName Get-Variable `
                    -MockWith { $false } `
                    -ParameterFilter $script:getVariableIsMacOs_parameterFilter
            }

            It 'Should not throw exception' {
                {
                    $script:getTemporaryPathResult = Get-TemporaryPath
                } | Should -Not -Throw
            }

            It 'Should return the /tmp path' {
                $script:getTemporaryPathResult | Should -BeExactly '/tmp'
            }
        }
    }
}

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

Describe 'Generate_Conceptual_Help' {
    BeforeAll {
        Mock -CommandName New-DscResourcePowerShellHelp

        # Stub function for the executable GitVersion.
        function gitversion
        {
            # Make sure to throw if this stub is called.
            throw 'GitVersion Mock: Not Implemented'
        }
    }

    BeforeEach {
        <#
            Make sure we didn't inherit a value for this parameter from the
            parent scope or a prior test. If this variable is set to a value
            by the build pipeline then this test would fail. This row make sure
            we always start clean.
        #>
        $ModuleVersion = $null
    }

    It 'Should run the build script alias' {
        $buildTaskName = 'Generate_Conceptual_Help'
        $buildScriptAliasName = 'Task.{0}' -f $buildTaskName

        $script:buildScript = Get-Command -Name $buildScriptAliasName -Module $script:projectName

        $script:buildScript.Name | Should -Be $buildScriptAliasName
        $script:buildScript.ReferencedCommand | Should -Be ('{0}.build.ps1' -f $buildTaskName)
    }

    It 'Should dot-source the build script without throwing' {
        { . $script:buildScript } | Should -Not -Throw
    }

    Context 'When the property ModuleVersion uses a value from the parent scope' {
        BeforeAll {
            # This mocks the alias 'property' for the parameter 'ModuleVersion'.
            Mock -Command Get-BuildProperty -MockWith {
                return '99.1.1-preview0001'
            } -ParameterFilter {
                $Name -eq 'ModuleVersion'
            }

            $mockTaskParameters = @{
                ProjectName = 'MyModule'
                SourcePath = $TestDrive
            }

            $mockExpectedDestinationModulePath = Join-Path -Path $script:projectPath -ChildPath 'output' |
                Join-Path -ChildPath $mockTaskParameters.ProjectName |
                    Join-Path -ChildPath '99.1.1'
        }

        It 'Should run the build task with the correct destination module path and without throwing' {
            {
                Invoke-Build -Task $buildTaskName -File $script:buildScript.Definition @mockTaskParameters
            } | Should -Not -Throw

            Assert-MockCalled -CommandName New-DscResourcePowerShellHelp -ParameterFilter {
                $DestinationModulePath -eq $mockExpectedDestinationModulePath
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the executable gitversion is available' {
        BeforeAll {
            # This mocks the executable gitversion.
            Mock -CommandName gitversion -MockWith {
                # Mock the JSON object that GitVersion returns.
                return '
                {
                    "NuGetVersionV2":"99.1.1-preview0001"
                }
                '
            }

            $mockTaskParameters = @{
                ProjectName = 'MyModule'
                SourcePath = $TestDrive
            }

            $mockExpectedDestinationModulePath = Join-Path -Path $script:projectPath -ChildPath 'output' |
                Join-Path -ChildPath $mockTaskParameters.ProjectName |
                    Join-Path -ChildPath '99.1.1'
        }

        It 'Should run the build task with the correct destination module path and without throwing' {
            {
                Invoke-Build -Task $buildTaskName -File $script:buildScript.Definition @mockTaskParameters
            } | Should -Not -Throw

            Assert-MockCalled -CommandName New-DscResourcePowerShellHelp -ParameterFilter {
                $DestinationModulePath -eq $mockExpectedDestinationModulePath
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the executable gitversion is not available' {
        BeforeAll {
            # This mocks the executable gitversion.
            Mock -CommandName gitversion -MockWith {
                throw
            }

            Mock -CommandName Get-ModuleVersion -MockWith {
                return '1.0.0'
            }

            $mockTaskParameters = @{
                ProjectName = 'MyModule'
                SourcePath = $TestDrive
            }

            $mockExpectedDestinationModulePath = Join-Path -Path $script:projectPath -ChildPath 'output' |
                Join-Path -ChildPath $mockTaskParameters.ProjectName |
                    Join-Path -ChildPath '1.0.0'
        }

        It 'Should run the build task with the correct destination module path and without throwing' {
            {
                Invoke-Build -Task $buildTaskName -File $script:buildScript.Definition @mockTaskParameters
            } | Should -Not -Throw

            Assert-MockCalled -CommandName New-DscResourcePowerShellHelp -ParameterFilter {
                $DestinationModulePath -eq $mockExpectedDestinationModulePath
            } -Exactly -Times 1 -Scope It
        }
    }
}

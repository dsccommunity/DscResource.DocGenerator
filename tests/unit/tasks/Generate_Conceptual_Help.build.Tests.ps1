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

    It 'Should export the build script alias' {
        $buildTaskName = 'Generate_Conceptual_Help'
        $buildScriptAliasName = 'Task.{0}' -f $buildTaskName

        $script:buildScript = Get-Command -Name $buildScriptAliasName -Module $script:projectName

        $script:buildScript.Name | Should -Be $buildScriptAliasName
        $script:buildScript.ReferencedCommand | Should -Be ('{0}.build.ps1' -f $buildTaskName)
    }

    It 'Should reference an existing build script' {
        Test-Path -Path $script:buildScript.Definition | Should -BeTrue
    }

    Context 'When the generating conceptual help for a built module' {
        BeforeAll {
            # This mocks the alias 'property' for the parameter 'ModuleVersion'.
            Mock -Command Get-BuiltModuleVersion -MockWith {
                return '99.1.1-preview0001'
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

    Context 'When the generating conceptual help and parsing markdown code for a built module' {
        BeforeAll {
            # This mocks the alias 'property' for the parameter 'ModuleVersion'.
            Mock -Command Get-BuiltModuleVersion -MockWith {
                return '99.1.1-preview0001'
            }

            $mockTaskParameters = @{
                ProjectName = 'MyModule'
                SourcePath = $TestDrive
                MarkdownCodeRegularExpression = @(
                    '\`(.+?)\`'
                )
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
}

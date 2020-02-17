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

    Context 'When the executable gitversion is available' {
        BeforeAll {
            Mock -CommandName gitversion -MockWith {
                # Mock the JSON object that GitVersion returns.
                return '
                {
                    "MajorMinorPatch":"99.1.1"
                }
                '
            }
        }

        It 'Should run the build task with the correct destination module path and without throwing' {
            $mockTaskParameters = @{
                ProjectName = 'MyModule'
                SourcePath = $TestDrive
            }

            {
                Invoke-Build -Task $buildTaskName -File $script:buildScript.Definition @mockTaskParameters
            } | Should -Not -Throw

            Assert-MockCalled -CommandName New-DscResourcePowerShellHelp -ParameterFilter {
                $DestinationModulePath -eq ('{0}\output\{1}\99.1.1' -f $script:projectPath, $mockTaskParameters.ProjectName)
            } -Exactly -Times 1 -Scope It
        }
    }

    Context 'When the executable gitversion is not available' {
        BeforeAll {
            Mock -CommandName gitversion -MockWith {
                throw
            }
        }

        It 'Should run the build task with the correct destination module path and without throwing' {
            $mockTaskParameters = @{
                ProjectName = 'MyModule'
                SourcePath = $TestDrive
            }

            {
                Invoke-Build -Task $buildTaskName -File $script:buildScript.Definition @mockTaskParameters
            } | Should -Not -Throw

            Assert-MockCalled -CommandName New-DscResourcePowerShellHelp -ParameterFilter {
                $DestinationModulePath -eq ('{0}\output\{1}\0.0.1' -f $script:projectPath, $mockTaskParameters.ProjectName)
            } -Exactly -Times 1 -Scope It
        }
    }
}

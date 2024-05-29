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

Describe 'Package_Wiki_Content' {
    BeforeAll {
        Mock -CommandName Compress-Archive
    }

    It 'Should export the build script alias' {
        $buildTaskName = 'Package_Wiki_Content'
        $buildScriptAliasName = 'Task.{0}' -f $buildTaskName

        $script:buildScript = Get-Command -Name $buildScriptAliasName -Module $script:projectName

        $script:buildScript.Name | Should -Be $buildScriptAliasName
        $script:buildScript.ReferencedCommand | Should -Be ('{0}.build.ps1' -f $buildTaskName)
    }

    It 'Should reference an existing build script' {
        Test-Path -Path $script:buildScript.Definition | Should -BeTrue
    }

    Context 'When path is valid' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $true
            }
        }

        It 'Should run the build task without throwing' {
            {
                $taskParameters = @{
                    ProjectName     = 'DscResource.DocGenerator'
                    OutputDirectory = $TestDrive.FullName
                }

                Invoke-Build -Task $buildTaskName -File $script:buildScript.Definition @taskParameters
            } | Should -Not -Throw

            Assert-MockCalled -CommandName Test-Path -Exactly -Times 2 -Scope It
            Assert-MockCalled -CommandName Compress-Archive -Exactly -Times 1 -Scope It
        }
    }

    Context 'When path is invalid' {
        BeforeAll {
            Mock -CommandName Test-Path -MockWith {
                return $false
            }
        }

        It 'Should run the build task and throw' {
            {
                $taskParameters = @{
                    ProjectName     = 'DscResource.DocGenerator'
                    OutputDirectory = $TestDrive.FullName
                }

                Invoke-Build -Task $buildTaskName -File $script:buildScript.Definition @taskParameters
            } | Should -Throw

            Assert-MockCalled -CommandName Test-Path -Exactly -Times 2 -Scope It
        }
    }
}

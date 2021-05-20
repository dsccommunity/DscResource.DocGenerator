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

Describe 'Publish_GitHub_Wiki_Content' {
    BeforeAll {
        Mock -CommandName Publish-WikiContent

        Mock -CommandName Test-Path -MockWith {
            return $true
        }

        Mock -Command Get-BuiltModuleVersion -MockWith {
            return [PSCustomObject]@{
                Version          = '1.0.0-preview1'
                PreReleaseString = 'preview1'
                ModuleVersion    = '1.0.0'
            }
        }

        Mock -CommandName Get-Item -MockWith {
            $Path =  ($Path -replace '\*','1.0.0')
            [PSCustomObject]@{
                FullName = $Path
            }
        }
    }
    Context 'When $GitHubToken is specified.' {
        BeforeAll {
            <#
                The build task only run if this is set. This sets the variable in the
                parent scope so Invoke-Build can use it. This way we don't mess with
                any real environment variables.
            #>
            $GitHubToken = 'anytoken'
        }

        AfterAll {
            Remove-Variable -Name 'GitHubToken'
        }

        It 'Should export the build script alias' {
            $buildTaskName = 'Publish_GitHub_Wiki_Content'
            $buildScriptAliasName = 'Task.{0}' -f $buildTaskName

            $script:buildScript = Get-Command -Name $buildScriptAliasName -Module $script:projectName

            $script:buildScript.Name | Should -Be $buildScriptAliasName
            $script:buildScript.ReferencedCommand | Should -Be ('{0}.build.ps1' -f $buildTaskName)
        }

        It 'Should reference an existing build script' {
            Test-Path -Path $script:buildScript.Definition | Should -BeTrue
        }

        It 'Should run the build task without throwing' {
            {
                $taskParameters = @{
                    ProjectName = 'MyModule'
                    SourcePath = $TestDrive
                }

                Invoke-Build -Task $buildTaskName -File $script:buildScript.Definition @taskParameters
            } | Should -Not -Throw

            Assert-MockCalled -CommandName Publish-WikiContent -Exactly -Times 1 -Scope It
        }
    }
    Context 'When $GitHubToken is not specified.' {
        BeforeAll {
            Mock -CommandName Write-Build
        }
        It 'Should Write-Build missing $GitHubToken & skipping task.' {

            { Invoke-Build -Task $buildTaskName -File $script:buildScript.Definition @taskParameters
            } | Should -Not -Throw

            Assert-MockCalled -CommandName Write-Build -ParameterFilter {
                $Color -eq 'Yellow' -and
                $Text -eq '$GitHubToken not set via parent scope, as an environment variable, or passed to the build task.'
            } -Exactly -Times 1 -Scope It
            Assert-MockCalled -CommandName Write-Build -ParameterFilter {
                $Color -eq 'Yellow' -and
                $Text -eq 'Skipping task: Publish_GitHub_Wiki_Content'
            } -Exactly -Times 1 -Scope It
        }
    }
}

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

Describe 'Generate_Wiki_Sidebar' {
    BeforeAll {
        Mock -Command Get-BuiltModuleVersion -MockWith {
            return [PSCustomObject]@{
                Version          = '1.0.0-preview1'
                PreReleaseString = 'preview1'
                ModuleVersion    = '1.0.0'
            }
        }

        Mock -CommandName Get-SamplerBuiltModuleManifest
        Mock -CommandName Get-SamplerBuiltModuleBase -MockWith {
            return $TestDrive.FullName
        }

        Mock -CommandName New-GitHubWikiSidebar

        New-Item -Path "$($TestDrive.FullName)/WikiContent" -ItemType 'Directory' -Force | Out-Null

        Set-Content -Path "$($TestDrive.FullName)/WikiContent/Get-Something.md" -Value 'Mock markdown file 1'

        Set-Content -Path "$($TestDrive.FullName)/WikiContent/home.md" -Value 'Mock markdown file 1'
    }

    It 'Should export the build script alias' {
        $buildTaskName = 'Generate_Wiki_Sidebar'
        $buildScriptAliasName = 'Task.{0}' -f $buildTaskName

        $script:buildScript = Get-Command -Name $buildScriptAliasName -Module $script:projectName

        $script:buildScript.Name | Should -Be $buildScriptAliasName
        $script:buildScript.ReferencedCommand | Should -Be ('{0}.build.ps1' -f $buildTaskName)
    }

    It 'Should reference an existing build script' {
        Test-Path -Path $script:buildScript.Definition | Should -BeTrue
    }
5
    It 'Should run the build task without throwing' {
        {
            $taskParameters = @{
                ProjectName = 'MockModule'
                ProjectPath = $TestDrive.FullName
                OutputDirectory = $TestDrive.FullName
                # Using the markdown created when the project was built.
                DocOutputFolder = $TestDrive.FullName | Join-Path -ChildPath 'WikiContent'
                SourcePath = "$($TestDrive.FullName)/source"
            }

            Invoke-Build -Task $buildTaskName -File $script:buildScript.Definition @taskParameters
        } | Should -Not -Throw

        Assert-MockCalled -CommandName New-GitHubWikiSidebar -Exactly -Times 1 -Scope 'It'
    }

    It 'Should run the build task in debug mode without throwing' {
        {
            $taskParameters = @{
                ProjectName = 'MockModule'
                ProjectPath = $TestDrive.FullName
                OutputDirectory = $TestDrive.FullName
                # Using the markdown created when the project was built.
                DocOutputFolder = $TestDrive.FullName | Join-Path -ChildPath 'WikiContent'
                SourcePath = "$($TestDrive.FullName)/source"
                DebugTask = $true
            }

            Invoke-Build -Task $buildTaskName -File $script:buildScript.Definition @taskParameters
        } | Should -Not -Throw

        Assert-MockCalled -CommandName New-GitHubWikiSidebar -ParameterFilter {
            $VerbosePreference -eq 'Continue' -and
            $DebugPreference -eq 'Continue'
        } -Exactly -Times 1 -Scope 'It'
    }
}

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

Describe 'Clean_WikiContent_For_GitHub_Publish' {
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

        New-Item -Path "$($TestDrive.FullName)/WikiContent" -ItemType 'Directory' -Force | Out-Null

        # Will not be modified
        Set-Content -Path "$($TestDrive.FullName)/WikiContent/Get-Something.md" -Value '# Get-Something`nMock markdown file 1'

        # Will be modified
        Set-Content -Path "$($TestDrive.FullName)/WikiContent/Credential-overview.md" -Value "# Credential overview`nMock markdown file 3"

        # Will not be modified
        Set-Content -Path "$($TestDrive.FullName)/WikiContent/Home.md" -Value "# My Module Name`nMock markdown file 4"
    }

    It 'Should export the build script alias' {
        $buildTaskName = 'Clean_WikiContent_For_GitHub_Publish'
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
    }
}

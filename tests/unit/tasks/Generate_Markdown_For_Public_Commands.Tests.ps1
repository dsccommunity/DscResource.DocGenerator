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

Describe 'Generate_Markdown_For_Public_Commands' {
    BeforeAll {
        Mock -Command Get-BuiltModuleVersion -MockWith {
            return [PSCustomObject]@{
                Version          = '1.0.0-preview1'
                PreReleaseString = 'preview1'
                ModuleVersion    = '1.0.0'
            }
        }

        Mock -CommandName Get-Item -MockWith {
            $Path =  [System.String] ($Path -replace '\*','1.0.0')

            [PSCustomObject]@{
                FullName = $Path
            }
        }

        Mock -CommandName Get-SamplerModuleRootPath -MockWith {
            # Return the path that was passed to the command.
            return $BuiltModuleManifest
        }

        Mock -CommandName Test-Path -MockWith {
            return $true
        }

        Set-Content -Path "$TestDrive/MockType.cs" -Value @"
public class BasicTest
{
    public static int Add(int a, int b)
    {
        return (a + b);
    }

    public int Multiply(int a, int b)
    {
        return (a * b);
    }
}
"@
    }

    It 'Should export the build script alias' {
        $buildTaskName = 'Generate_Markdown_For_Public_Commands'
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
                # Need and existing module, the module being tested is always available.
                ProjectName = 'DscResource.DocGenerator'
                DocOutputFolder = $TestDrive
                DependentType = "$TestDrive/MockType.cs"
                # Any module that is available. Pester is always available.
                DependentModule = 'Pester'
                SourcePath = "$TestDrive/source"
            }

            Invoke-Build -Task $buildTaskName -File $script:buildScript.Definition @taskParameters
        } | Should -Not -Throw

        Should -Exist -ActualValue (Join-Path -Path $TestDrive -ChildPath 'Edit-CommandDocumentation.md') -Because 'the task should have generated the markdown file for the command.'
    }
}

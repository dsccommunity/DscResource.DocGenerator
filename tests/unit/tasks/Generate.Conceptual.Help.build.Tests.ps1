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

Describe 'Generate.Conceptual.Help.build' {
    BeforeAll {
        Mock -CommandName New-DscResourcePowerShellHelp

        $buildScript = Get-Command -Name 'Task.Generate_Conceptual_Help' -Module $script:projectName
    }

    It 'Should dot-source the build script without throwing' {
        { . $buildScript } | Should -Not -Throw
    }

    It 'Should run the build task without throwing' {
        {
            $taskParameters = @{
                ProjectName = 'MyModule'
                SourcePath = $TestDrive
            }

            Invoke-Build -Task 'Generate_Conceptual_Help' -File $buildScript.Definition @taskParameters
        } | Should -Not -Throw

        Assert-MockCalled -CommandName New-DscResourcePowerShellHelp -Exactly -Times 1 -Scope It
    }
}
